#!/usr/bin/env python3
"""Download and verify the exact Godot 4.4.1 release templates used by CI."""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request
import zipfile

VERSION = '4.4.1-stable'
ARCHIVE = f'Godot_v{VERSION}_export_templates.tpz'
BASE = f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}'
NEEDED = ['web_nothreads_release.zip', 'windows_release_x86_64.exe', 'linux_release.x86_64']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', required=True, type=Path)
    args = parser.parse_args()
    folder = args.destination.resolve()
    folder.mkdir(parents=True, exist_ok=True)
    sums = urllib.request.urlopen(f'{BASE}/SHA512-SUMS.txt', timeout=60).read().decode()
    expected = next(row.split()[0] for row in sums.splitlines()
                    if row.split()[-1].lstrip('*') == ARCHIVE)
    archive = folder / ARCHIVE
    if not archive.exists():
        print(f'Downloading official {VERSION} export templates...', flush=True)
        urllib.request.urlretrieve(f'{BASE}/{ARCHIVE}', archive)
    digest = hashlib.sha512()
    with archive.open('rb') as stream:
        for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b''):
            digest.update(chunk)
    if digest.hexdigest() != expected:
        raise RuntimeError('Export template archive failed the official SHA-512 check.')
    installed = {}
    with zipfile.ZipFile(archive) as packed:
        for name in NEEDED:
            member = next(entry for entry in packed.namelist() if entry.endswith('/' + name))
            path = folder / name
            path.write_bytes(packed.read(member))
            if name.startswith('linux_'):
                path.chmod(0o755)
            installed[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    (folder / 'verified_templates.json').write_text(json.dumps({
        'version': VERSION, 'archive_sha512': expected, 'files_sha256': installed}, indent=2))
    print('Verified and installed Web, Windows and native release templates.')


if __name__ == '__main__':
    main()
