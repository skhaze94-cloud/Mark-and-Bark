"""Small standard-library helpers shared by source and export verification."""
import os
from pathlib import Path
import re
import shutil
import subprocess


def copy_project(source, destination, qa_name=None):
    shutil.copytree(source, destination, ignore=shutil.ignore_patterns(
        '.git', '.godot', 'test_output', 'exports', 'dist', 'node_modules', '__pycache__'))
    if qa_name:
        project = destination / 'project.godot'
        text, count = re.subn(r'^config/name=.*$', f'config/name="{qa_name}"',
                              project.read_text(), count=1, flags=re.MULTILINE)
        if count != 1:
            raise RuntimeError('Could not isolate the QA application name.')
        project.write_text(text)


def isolated_environment(folder):
    env = dict(os.environ)
    for key, leaf in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'),
                      ('XDG_CACHE_HOME', 'cache')]:
        path = folder / leaf
        path.mkdir(parents=True, exist_ok=True)
        env[key] = str(path)
    return env


def run_checked(command, log_path, env=None, timeout=240, require_result=False, extra_log=None):
    try:
        result = subprocess.run([str(x) for x in command], capture_output=True,
                                text=True, env=env, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or b'') + (exc.stderr or b'')
        log_path.write_text(output.decode(errors='replace') if isinstance(output, bytes) else output)
        raise RuntimeError(f'Timed out. See {log_path}') from exc
    log = result.stdout + result.stderr
    if extra_log and Path(extra_log).exists():
        log += '\n[Engine log]\n' + Path(extra_log).read_text(errors='replace')
    log_path.write_text(log)
    match = re.search(r'RESULT:\s*(\d+) passed;\s*(\d+) failed', log)
    failed = (result.returncode != 0 or 'SCRIPT ERROR:' in log or '\nERROR:' in log
              or 'fatal library error' in log.lower() or 'Parse Error:' in log)
    if require_result and (not match or int(match[2])):
        failed = True
    if failed:
        raise RuntimeError(f'Command failed. See {log_path}\n{log[-6000:]}')
    return {'passed': int(match[1]) if match else 0,
            'failed': int(match[2]) if match else 0, 'exit_code': result.returncode}
