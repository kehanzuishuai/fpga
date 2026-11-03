"""Check the published source/firmware pair using only the Python standard library."""
from pathlib import Path
import hashlib
import json
import re
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
RELEASE = ROOT / 'release/v21_20261103'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    source = json.loads((RELEASE / 'SOURCE_MANIFEST.json').read_text(encoding='utf-8'))
    for relative, expected in source['files'].items():
        path = ROOT / relative
        assert path.is_file() and sha(path) == expected, f'Source mismatch: {relative}'
    outputs = 0
    for line in (RELEASE / 'SHA256SUMS.txt').read_text(encoding='utf-8').splitlines():
        expected, relative = line.split('  ', 1)
        path = RELEASE / relative
        assert path.resolve().is_relative_to(RELEASE.resolve()), relative
        assert path.is_file() and sha(path) == expected, f'Release mismatch: {relative}'
        outputs += 1
    fpga = json.loads((RELEASE / 'FPGA_BUILD.json').read_text(encoding='utf-8'))
    with zipfile.ZipFile(RELEASE / fpga['fpga_archive']) as archive:
        assert archive.testzip() is None, 'FPGA archive CRC mismatch'
        assert hashlib.sha256(archive.read(fpga['fpga_file'])).hexdigest() == fpga['fs_sha256'], 'Unpacked FPGA differs from the timing-validated file'
    active = [item.get('path') for item in ET.parse(ROOT / 'yinyue_fashengqi.gprj').findall('.//File') if item.get('enable') == '1']
    assert all((ROOT / name).is_file() for name in active), 'Missing enabled project file'
    roms = set()
    for path in (ROOT / 'src').rglob('*'):
        if path.suffix in ('.v', '.sv'):
            roms.update(re.findall(r'\$readmem[hb]\s*\(\s*"([^"]+)"', path.read_text(encoding='utf-8')))
    assert all((ROOT / name).is_file() for name in roms), 'Missing ROM initialization file'
    phone = ROOT / 'firmware/remote_music_ble/shouji'
    sketch = ROOT / 'firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller'
    embedded = dict(re.findall(r'const char (\w+)\[\] PROGMEM=R"MUSICWEB\((.*?)\)MUSICWEB";', (sketch / 'web_page.h').read_text(encoding='utf-8'), re.S))
    assets = {'PAGE':'index.html', 'APP_JS':'app.js', 'SCORE_JS':'score.js', 'KEYMAP_PAGE':'keymap.html', 'KEYMAP_JS':'keymap.js', 'UI_CSS':'ui.css', 'UI_TEXT_JS':'ui-text.js', 'NAV_JS':'navigation.js', 'DEVICE_API_JS':'device-api.js'}
    for symbol, filename in assets.items():
        assert embedded.get(symbol) == (phone / filename).read_text(encoding='utf-8'), f'Embedded web mismatch: {filename}'
    esp = json.loads((RELEASE / 'ESP32_BUILD.json').read_text(encoding='utf-8'))
    for relative, expected in esp['source_sha256'].items():
        assert sha(ROOT / relative.replace('\\', '/')) == expected, relative
    current_docs = ['README.md', 'README_HANDOFF.md', 'release/latest/README.md', 'release/v21_20261103/README.md',
                    'docs/BUILD_AND_PROGRAM.md', 'docs/CURRENT_INTERFACES.md', 'firmware/theremin/README.md',
                    'firmware/theremin/SOURCES.md', 'firmware/remote_music_ble/README_BLE.md',
                    'firmware/remote_music_ble/esp32/README.md', 'firmware/remote_music_ble/shouji/README.md']
    link_count = 0
    for name in current_docs:
        document = ROOT / name
        for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', document.read_text(encoding='utf-8')):
            if target.startswith(('http:', 'https:', '#')):
                continue
            relative = target.split('#', 1)[0]
            assert (document.parent / relative).exists(), f'Broken current link: {name} -> {target}'
            link_count += 1
    print(f'PASS current release: {len(source["files"])} source files; {outputs} release files; {len(active)} enabled project entries; {len(roms)} ROM assets; 9 embedded web assets; {link_count} current documentation links')


if __name__ == '__main__':
    main()
