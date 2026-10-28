#!/usr/bin/env python3
"""Run the complete game checks with isolated saves; requires Godot 4.4.1."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default=shutil.which('godot4') or shutil.which('godot'))
args = parser.parse_args()
if not args.godot:
    parser.error('Provide --godot /path/to/Godot or put godot4/godot on PATH.')
engine = str(Path(args.godot).resolve())
root = Path(__file__).resolve().parents[1]
output = root / 'test_output'
output.mkdir(exist_ok=True)
scenes = ['playthrough', 'jump_review', 'polish_review', 'variety_review', 'mega_playthrough']
summary = {'engine': subprocess.check_output([engine, '--version'], text=True).strip(), 'suites': {}}
with tempfile.TemporaryDirectory(prefix='qa-', dir=output) as state:
    env = dict(os.environ)
    for key, folder in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        target = Path(state) / folder
        target.mkdir()
        env[key] = str(target)
    jobs = [('import', ['--editor', '--import', '--quit'])] + [(scene, ['--fixed-fps', '60', f'res://tests/{scene}.tscn']) for scene in scenes]
    for name, flags in jobs:
        result = subprocess.run([engine, '--headless', '--path', str(root), *flags], env=env, capture_output=True, text=True, timeout=240)
        log = result.stdout + result.stderr
        (output / f'qa_{name}.log').write_text(log)
        failed = result.returncode != 0 or 'SCRIPT ERROR:' in log or '\nERROR:' in log
        match = re.search(r'RESULT:\s*(\d+) passed;\s*(\d+) failed', log)
        if name != 'import' and (not match or int(match[2])):
            failed = True
        summary['suites'][name] = {'passed': int(match[1]) if match else 0, 'failed': int(match[2]) if match else int(failed), 'exit_code': result.returncode}
        print(f'{name}: {"FAIL" if failed else "PASS"}', flush=True)
        if failed:
            print(log[-6000:])
            raise SystemExit(1)
summary['total_passed'] = sum(s['passed'] for s in summary['suites'].values())
(output / 'qa_summary.json').write_text(json.dumps(summary, indent=2))
print(f'Complete: {summary["total_passed"]} checks passed. Logs: {output}')
