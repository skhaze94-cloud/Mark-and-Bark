#!/usr/bin/env python3
"""Build a signed, offline ARM64 APK using Godot 4.5.1 and Android build tools.

Passwords are read from an environment variable, never written into the project.
The Android runtime uses 16 KiB ELF pages; desktop releases stay on Godot 4.4.1.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from qa_common import copy_project, isolated_environment, run_checked


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True, type=Path)
    parser.add_argument('--template', required=True, type=Path)
    parser.add_argument('--sdk', required=True, type=Path)
    parser.add_argument('--build-tools', default='35.0.0')
    parser.add_argument('--java', required=True, type=Path)
    parser.add_argument('--keystore', required=True, type=Path)
    parser.add_argument('--key-alias', required=True)
    parser.add_argument('--password-env', default='MARK_BARK_KEY_PASSWORD')
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    if not os.environ.get(args.password_env):
        parser.error('The password environment variable must be set.')
    engine = args.godot.resolve()
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    if not version.startswith('4.5.1.stable.'):
        parser.error('The Android release is pinned to Godot 4.5.1 stable.')
    source = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    logs = source / 'test_output' / 'android'
    logs.mkdir(parents=True, exist_ok=True)
    build_tools = args.sdk.resolve() / 'build-tools' / args.build_tools
    with tempfile.TemporaryDirectory(prefix='mark-bark-android-') as temporary:
        folder = Path(temporary)
        project = folder / 'project'
        copy_project(source, project)
        env = isolated_environment(folder)
        env['JAVA_HOME'] = str(args.java.resolve())
        templates = folder / 'data' / 'godot' / 'export_templates' / '4.5.1.stable'
        templates.mkdir(parents=True, exist_ok=True)
        # The editor validates both official APK templates even for a release.
        for name in ['android_debug.apk', 'android_release.apk']:
            (templates / name).symlink_to(args.template.resolve().parent / name)
        config = folder / 'config' / 'godot'
        config.mkdir(parents=True, exist_ok=True)
        (config / 'editor_settings-4.5.tres').write_text(
            '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
            'export/android/java_sdk_path = ' + json.dumps(str(args.java.resolve())) + '\n'
            'export/android/android_sdk_path = ' + json.dumps(str(args.sdk.resolve())) + '\n')
        presets = project / 'export_presets.cfg'
        text = presets.read_text()
        start = text.index('[preset.2.options]')
        text = text[:start] + text[start:].replace('custom_template/release=""',
            'custom_template/release=' + json.dumps(str(args.template.resolve())), 1).replace(
                'package/signed=true', 'package/signed=false', 1)
        presets.write_text(text)
        run_checked([engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                     '--editor', '--import', '--quit'], logs / 'import.log', env)
        unsigned = folder / 'unsigned.apk'
        run_checked([engine, '--headless', '--audio-driver', 'Dummy', '--path', project,
                     '--export-release', 'Android', unsigned], logs / 'export.log', env)
        if not unsigned.is_file():
            raise RuntimeError('The Android exporter did not produce a complete APK.')
        aligned = folder / 'aligned.apk'
        subprocess.run([build_tools / 'zipalign', '-f', '-P', '16', '4', unsigned, aligned], check=True)
        subprocess.run([build_tools / 'apksigner', 'sign', '--ks', args.keystore.resolve(),
                        '--ks-key-alias', args.key_alias, '--ks-pass', 'env:' + args.password_env,
                        '--key-pass', 'env:' + args.password_env, '--out', output, aligned],
                       check=True, env=env, capture_output=True)
    digest = hashlib.file_digest(output.open('rb'), 'sha256').hexdigest()
    (logs / 'build.json').write_text(json.dumps({'engine': version, 'file': output.name,
        'bytes': output.stat().st_size, 'sha256': digest,
        'template_sha256': hashlib.file_digest(args.template.open('rb'), 'sha256').hexdigest()}, indent=2))
    print(f'Signed APK: {output} ({output.stat().st_size:,} bytes)\nSHA256: {digest}')


if __name__ == '__main__':
    main()
