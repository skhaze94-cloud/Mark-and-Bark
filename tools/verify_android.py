#!/usr/bin/env python3
"""Check the signed APK and exercise its exact exported resources on desktop.

This is package/content verification, not an Android device or emulator test.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import zipfile

from qa_common import isolated_environment
from verify_exports import verify_pack


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', required=True, type=Path)
    parser.add_argument('--build-tools', required=True, type=Path)
    parser.add_argument('--godot', required=True, type=Path)
    args = parser.parse_args()
    apk = args.apk.resolve()
    source = Path(__file__).resolve().parents[1]
    output = source / 'test_output' / 'android'
    output.mkdir(parents=True, exist_ok=True)
    report = {'physical_device_tested': False, 'emulator_tested': False,
              'sha256': hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest(),
              'bytes': apk.stat().st_size}
    for label, command in [
        ('signature', ['apksigner', 'verify', '--verbose', '--print-certs', apk]),
        ('alignment', ['zipalign', '-c', '-P', '16', '4', apk]),
        ('badging', ['aapt', 'dump', 'badging', apk]),
        ('manifest', ['aapt', 'dump', 'xmltree', apk, 'AndroidManifest.xml'])]:
        result = subprocess.run([args.build_tools.resolve() / command[0], *command[1:]],
                                check=True, capture_output=True, text=True)
        report[label] = result.stdout
    assert "name='com.samkhaze.markandbark'" in report['badging']
    assert "versionCode='410' versionName='4.1.0'" in report['badging']
    assert "native-code: 'arm64-v8a'" in report['badging']
    assert "targetSdkVersion:'35'" in report['badging']
    assert 'uses-permission:' not in report['badging']
    assert 'android:screenOrientation(0x0101001e)=(type 0x10)0x0' in report['manifest']
    assert 'android:debuggable' not in report['manifest'] or 'android:debuggable(0x0101000f)=(type 0x12)0x0' in report['manifest']
    assert 'Verified using v2 scheme (APK Signature Scheme v2): true' in report['signature']
    assert 'Verified using v3 scheme (APK Signature Scheme v3): true' in report['signature']
    with tempfile.TemporaryDirectory(prefix='mark-bark-apk-check-') as temporary:
        folder = Path(temporary)
        pack = folder / 'apk-resources.zip'
        with zipfile.ZipFile(apk) as archive, zipfile.ZipFile(pack, 'w') as resources:
            assert archive.testzip() is None
            names = archive.namelist()
            assert not any(n.startswith(('assets/tests/', 'assets/tools/', 'assets/docs/', 'assets/test_output/')) for n in names)
            assert not any(n.endswith(('.keystore', '.jks', 'credentials.json')) for n in names)
            for name in names:
                if name.startswith('assets/') and not name.startswith('assets/dexopt/') and not name.endswith('/'):
                    resources.writestr(name.removeprefix('assets/'), archive.read(name))
                if name.endswith('.so'):
                    data = archive.read(name)
                    assert data[:5] == b'\x7fELF\x02'
                    offset = struct.unpack_from('<Q', data, 32)[0]
                    size, count = struct.unpack_from('<HH', data, 54)
                    aligns = [struct.unpack_from('<Q', data, offset + i * size + 48)[0]
                              for i in range(count) if struct.unpack_from('<I', data, offset + i * size)[0] == 1]
                    assert aligns and min(aligns) >= 16384
                    report.setdefault('elf_load_alignments', {})[name] = aligns
        report['packed_content_smoke'] = verify_pack(args.godot.resolve(), pack, output / 'packed',
            isolated_environment(folder), source / 'tools' / 'export_smoke.gd')
    (output / 'verification.json').write_text(json.dumps(report, indent=2))
    print('APK signature, 16 KiB alignment, landscape, ARM64, offline permissions and exact packed content: PASS')
    print('Physical Android device/emulator test: not performed')


if __name__ == '__main__':
    main()
