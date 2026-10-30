#!/usr/bin/env python3
"""Run all source-project checks from a fresh copy with isolated player saves."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import uuid

from qa_common import copy_project, isolated_environment, run_checked


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=shutil.which('godot4') or shutil.which('godot'))
    args = parser.parse_args()
    if not args.godot:
        parser.error('Provide --godot /path/to/Godot or put godot4/godot on PATH.')
    engine = str(Path(args.godot).resolve())
    source = Path(__file__).resolve().parents[1]
    output = source / 'test_output'
    output.mkdir(exist_ok=True)
    suites = ['playthrough', 'jump_review', 'polish_review', 'variety_review',
              'mega_playthrough', 'animation_review', 'restoration_review', 'finishing_review',
              'library_review', 'graphics_review', 'whimsy_review', 'hud_review']
    summary = {'engine': subprocess.check_output([engine, '--version'], text=True).strip(),
               'clean_project_copy': True, 'isolated_save_data': True, 'suites': {}}
    qa_name = 'MarkBarkQA_' + uuid.uuid4().hex
    user_data = None
    with tempfile.TemporaryDirectory(prefix='mark-bark-qa-') as temporary:
        folder = Path(temporary)
        project = folder / 'project'
        copy_project(source, project, qa_name=qa_name)
        env = isolated_environment(folder)
        try:
            summary['suites']['import'] = run_checked(
                [engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                 '--editor', '--import', '--quit'], output / 'qa_import.log', env)
            print('import: PASS', flush=True)
            probe = folder / 'user_dir.gd'
            probe.write_text('extends SceneTree\nfunc _initialize():\n'
                             ' print("QA_USER_DIR="+JSON.stringify(OS.get_user_data_dir()))\n quit()\n')
            run_checked([engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                         '--script', probe], output / 'qa_user_dir.log', env)
            match = re.search(r'QA_USER_DIR=(.+)', (output / 'qa_user_dir.log').read_text())
            if not match:
                raise RuntimeError('Could not verify isolation of the QA save folder.')
            user_data = Path(json.loads(match[1])).resolve()
            if user_data.name != qa_name:
                raise RuntimeError('Refusing to test against a non-isolated player save folder.')
            for scene in suites:
                summary['suites'][scene] = run_checked(
                    [engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                     '--fixed-fps', '60', f'res://tests/{scene}.tscn'],
                    output / f'qa_{scene}.log', env, require_result=True)
                print(f'{scene}: PASS', flush=True)
            generated = project / 'test_output'
            if generated.exists():
                shutil.copytree(generated, output, dirs_exist_ok=True)
        finally:
            # The generated name is unique and verified by the engine itself.
            if user_data and user_data.name == qa_name and user_data.is_dir():
                shutil.rmtree(user_data)
    summary['total_passed'] = sum(row['passed'] for row in summary['suites'].values())
    (output / 'qa_summary.json').write_text(json.dumps(summary, indent=2))
    print(f'Complete: {summary["total_passed"]} checks passed. Logs: {output}')


if __name__ == '__main__':
    main()
