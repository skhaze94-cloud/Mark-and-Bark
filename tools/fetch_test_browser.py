#!/usr/bin/env python3
"""Fetch the pinned Chrome for Testing runtime used for the Web release checks."""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request
import zipfile

VERSION = '156.0.8078.73'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', required=True, type=Path)
    args = parser.parse_args()
    folder = args.destination.resolve()
    folder.mkdir(parents=True, exist_ok=True)
    archive = folder / 'chrome.zip'
    url = f'https://storage.googleapis.com/chrome-for-testing-public/{VERSION}/linux64/chrome-headless-shell-linux64.zip'
    if not archive.exists():
        urllib.request.urlretrieve(url, archive)
    with zipfile.ZipFile(archive) as packed:
        for name in packed.namelist():
            if not (folder / name).resolve().is_relative_to(folder):
                raise RuntimeError('Unexpected browser archive path.')
        packed.extractall(folder)
    for name in ['chrome-headless-shell', 'chrome_crashpad_handler']:
        path = folder / 'chrome-headless-shell-linux64' / name
        if path.exists():
            path.chmod(0o755)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (folder / 'browser_version.json').write_text(json.dumps({'version': VERSION, 'archive_sha256': digest}, indent=2))
    print('Installed pinned Chrome for Testing', VERSION)


if __name__ == '__main__':
    main()
