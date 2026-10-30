#!/usr/bin/env python3
"""Build production packs and exercise them in isolated, fresh game processes."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

from qa_common import copy_project, isolated_environment, run_checked


def verify_pack(runtime, pack, output, environment, controller):
    output.mkdir(parents=True, exist_ok=True)
    results = {}
    with tempfile.TemporaryDirectory(prefix='mark-bark-pack-') as temporary:
        folder = Path(temporary)
        empty = folder / 'empty'
        state = folder / 'state'
        empty.mkdir(); state.mkdir()
        for phase in ['seed', 'resume', 'recover']:
            if phase == 'recover':
                for name in ['story.json', 'climbs.json']:
                    primary = state / name
                    if not Path(str(primary) + '.bak').exists():
                        raise RuntimeError(f'Export did not retain a backup for {name}.')
                    primary.write_text('{interrupted')
            report = output / f'{phase}.json'
            engine_log = output / f'{phase}_engine.log'
            command = [runtime, '--headless', '--audio-driver', 'Dummy', '--path', empty,
                       '--main-pack', pack, '--log-file', engine_log,
                       '--script', controller, '--fixed-fps', '60', '--',
                       f'--state-dir={state.as_posix()}', f'--report={report.as_posix()}', f'--phase={phase}']
            run_checked(command, output / f'{phase}.log', environment, timeout=90,
                        require_result=True, extra_log=engine_log)
            result = json.loads(report.read_text())
            if result['failed'] or not result['exit_retry_requested']:
                raise RuntimeError(f'Exported {phase} scenario did not complete.')
            # This check runs after the real production close handler exits.
            story = json.loads((state / 'story.json').read_text())
            climbs = json.loads((state / 'climbs.json').read_text())
            if (story['data']['stage'] != 4 or not story['tutorial_done']
                    or abs(story['settings']['volume'] - .35) > .0001
                    or story['settings']['music'] or not story['settings']['touch']
                    or climbs['runs'][0]['checkpoint'] != 3 or not climbs['prefs']['calm']):
                raise RuntimeError('Exported close did not commit the expected progress and preferences.')
            results[phase] = result
            print(f'exported {phase}: PASS ({result["passed"]} checks)', flush=True)
    return results


def override_templates(project, templates):
    presets = project / 'export_presets.cfg'
    text = presets.read_text()
    for name in ['web_nothreads_release.zip', 'windows_release_x86_64.exe']:
        path = templates / name
        if not path.is_file():
            raise RuntimeError(f'Missing official export template: {path}')
        text = text.replace('custom_template/release=""',
                            'custom_template/release=' + json.dumps(path.as_posix()), 1)
    presets.write_text(text)


def archive(folder, target):
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as packed:
        for path in sorted(folder.rglob('*')):
            if path.is_file():
                packed.write(path, path.relative_to(folder))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path)
    parser.add_argument('--templates', type=Path)
    parser.add_argument('--runtime', type=Path)
    parser.add_argument('--pack', type=Path, help='Verify an already exported pack, including on Windows.')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    output = (args.output or source / 'test_output' / 'exports').resolve()
    output.mkdir(parents=True, exist_ok=True)
    controller = source / 'tools' / 'export_smoke.gd'
    summary = {'targets': {}, 'packed_checks': {}}
    with tempfile.TemporaryDirectory(prefix='mark-bark-export-') as temporary:
        folder = Path(temporary)
        env = isolated_environment(folder)
        if args.pack:
            if not args.runtime:
                parser.error('--pack requires --runtime.')
            summary['packed_checks'] = verify_pack(args.runtime.resolve(), args.pack.resolve(),
                                                     output / 'runtime', env, controller)
            summary['targets']['existing_pack'] = str(args.pack.resolve())
        else:
            if not args.godot:
                parser.error('Provide --godot /path/to/Godot, or --pack and --runtime.')
            engine = args.godot.resolve()
            project = folder / 'project'
            copy_project(source, project)
            if args.templates:
                override_templates(project, args.templates.resolve())
            run_checked([engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                         '--editor', '--import', '--quit'], output / 'import.log', env)
            pack = output / 'Mark-and-Bark.pck'
            run_checked([engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                         '--export-pack', 'Web', pack], output / 'pack.log', env)
            runtime = args.runtime.resolve() if args.runtime else engine
            if args.templates and os.name != 'nt' and not args.runtime:
                candidate = args.templates.resolve() / 'linux_release.x86_64'
                if candidate.exists():
                    runtime = candidate
            summary['packed_checks'] = verify_pack(runtime, pack, output / 'runtime', env, controller)
            summary['targets']['resource_pack'] = {'bytes': pack.stat().st_size,
                                                    'runtime': runtime.name}
            if args.templates:
                for preset, name, filename in [('Web', 'web', 'index.html'),
                                               ('Windows Desktop', 'windows', 'Mark-and-Bark.exe')]:
                    destination = output / name
                    destination.mkdir(exist_ok=True)
                    run_checked([engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                                 '--export-release', preset, destination / filename],
                                output / f'{name}_build.log', env, timeout=300)
                    required = ['index.html', 'index.js', 'index.wasm', 'index.pck'] if name == 'web' else ['Mark-and-Bark.exe', 'Mark-and-Bark.pck']
                    if any(not (destination / item).is_file() for item in required):
                        raise RuntimeError(f'{name} export is missing a required runtime file.')
                    archive(destination, output / f'Mark-and-Bark-3.7.0-{name}.zip')
                    summary['targets'][name] = {'files': required,
                                               'bytes': sum(p.stat().st_size for p in destination.rglob('*') if p.is_file())}
                    print(f'{name} release build: PASS', flush=True)
    summary['total_packed_checks'] = sum(row['passed'] for row in summary['packed_checks'].values())
    (output / 'export_summary.json').write_text(json.dumps(summary, indent=2))
    print(f'Export verification complete: {summary["total_packed_checks"]} packed-runtime checks.')


if __name__ == '__main__':
    main()
