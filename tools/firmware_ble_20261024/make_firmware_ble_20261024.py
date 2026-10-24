"""ESP32-S3 firmware with the BLE bridge and without WAV (user decisions 2026-10-24).

Source: firmware/remote_music (left unchanged). Target: firmware/remote_music_ble.
- WAV removed: WavLink.h/WavService.h/wav.js not copied, the WAV section and
  script tag removed from index.html, WAV_JS no longer embedded, WavService not
  set up. The FPGA no longer contains the WAV decoder (branch v12 onwards).
- BLE bridge added (BleBridge.h, C:/fpga/piano_app/BLE_PROTOCOL.md v1); the FPGA
  worker task serves BLE requests whenever it has no HTTP job.
- ControlLink.h: recEnable()/recRead() for the new FPGA commands 0x17/0x07.
- Partition scheme huge_app (3 MB app, no OTA): the BLE stack does not fit the
  default 1.25 MB app partition.
Then regenerates web_page.h and compiles (compile only, no upload).
"""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys
R = Path(r'D:\gaoyun\piano_v2_audio_fix')
SRC = R / 'firmware/remote_music'
DST = R / 'firmware/remote_music_ble'
HERE = Path(__file__).resolve().parent
SK = 'esp32/ESP32_FPGA_Music_Controller'


def patch(path, pairs):
    s = path.read_text(encoding='utf-8')
    for old, new in pairs:
        assert s.count(old) == 1, (path.name, old[:70])
        s = s.replace(old, new)
    path.write_text(s, encoding='utf-8')


if not DST.exists():
    (DST / SK).mkdir(parents=True)
    shutil.copytree(SRC / 'shouji', DST / 'shouji', ignore=shutil.ignore_patterns('wav.js'))
    for f in ('build_web.py', 'README.md'):
        shutil.copy2(SRC / 'esp32' / f, DST / 'esp32' / f)
    for f in ('ControlLink.h', 'ESP32_FPGA_Music_Controller.ino', 'sketch.yaml'):
        shutil.copy2(SRC / SK / f, DST / SK / f)
    shutil.copy2(HERE / 'BleBridge.h', DST / SK / 'BleBridge.h')
    html = DST / 'shouji/index.html'
    s = html.read_text(encoding='utf-8')
    a = s.index('<section><div class="section-head"><h2>WAV音乐播放</h2>')
    b = s.index('</section>', a) + len('</section>')
    s = s[:a] + s[b:]
    assert s.count('<script src="wav.js"></script>') == 1
    html.write_text(s.replace('<script src="wav.js"></script>', ''), encoding='utf-8')
    patch(DST / 'esp32/build_web.py', [("[('WAV_JS','wav.js'),('PAGE','index.html')", "[('PAGE','index.html')")])
    patch(DST / SK / 'ControlLink.h', [('  bool play(bool on){', '''  // Physical-key recording (FPGA v13 commands 0x17/0x07, BLE_PROTOCOL.md).
  bool recEnable(bool on){
    uint8_t v=on?1:0,r[4];
    if(!handshake()||!request(0x17,&v,1,r))return false;
    if(r[0]!=v){error=Error::NotApplied;return false;}return true;
  }
  bool recRead(uint32_t &word){
    uint8_t r[4];if(!request(0x07,nullptr,0,r))return false;
    word=uint32_t(r[0])|uint32_t(r[1])<<8|uint32_t(r[2])<<16|uint32_t(r[3])<<24;return true;
  }
  bool play(bool on){''')])
    patch(DST / SK / 'ESP32_FPGA_Music_Controller.ino', [
        ('#include "web_page.h"\n', '#include "web_page.h"\n#include "BleBridge.h"\n'),
        ('  if(xQueueReceive(deviceQueue,&job,portMAX_DELAY)!=pdTRUE)continue;\n',
         '  // No HTTP job within 5 ms: serve the phone app over BLE (same task owns the FPGA link).\n'
         '  if(xQueueReceive(deviceQueue,&job,pdMS_TO_TICKS(5))!=pdTRUE){Ble::service(*fpgaLink);continue;}\n'),
        ('#include "WavService.h"\n', ''),
        ('  if(deviceQueue&&jobMutex)workerReady=xTaskCreate(deviceWorker,"fpga_uart",8192,nullptr,1,nullptr)==pdPASS;\n',
         '  Ble::setup();\n  if(deviceQueue&&jobMutex)workerReady=xTaskCreate(deviceWorker,"fpga_uart",8192,nullptr,1,nullptr)==pdPASS;\n'),
        ('  WavService::setup();\n  server.on("/wav.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",WAV_JS);});\n', ''),
    ])
    patch(DST / SK / 'sketch.yaml', [('default_fqbn: esp32:esp32:esp32s3', 'default_fqbn: esp32:esp32:esp32s3:PartitionScheme=huge_app')])
p = subprocess.run([sys.executable, str(DST / 'esp32/build_web.py')], capture_output=True, text=True)
assert p.returncode == 0, p.stderr
out = R / 'tests/remote_music_ble_20261024/esp32'
out.mkdir(parents=True, exist_ok=True)
cli = R / 'tools/toolchains/arduino/arduino-cli.exe'
fqbn = 'esp32:esp32:esp32s3:PartitionScheme=huge_app'
args = [str(cli), '--config-file', str(cli.with_name('arduino-cli.yaml')), 'compile', '--fqbn', fqbn, '--jobs', '2',
        '--build-path', str(out / 'esp32_build'), str(DST / SK)]
p = subprocess.run(args, cwd=DST, capture_output=True, text=True, errors='replace', timeout=1800)
(out / 'esp32_compile.log').write_text(p.stdout + p.stderr, encoding='utf-8')
srcs = {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in (DST / SK).iterdir() if f.is_file()}
bins = {f.name: {'bytes': f.stat().st_size, 'sha256': hashlib.sha256(f.read_bytes()).hexdigest()}
        for f in sorted((out / 'esp32_build').glob('*.bin'))} if p.returncode == 0 else {}
(out / 'esp32_compile.json').write_text(json.dumps({'status': 'PASS' if p.returncode == 0 else 'FAIL', 'fqbn': fqbn,
    'scope': 'Compile only, no upload. Generic ESP32-S3, 4 MB flash, huge_app partitions.', 'sources': srcs, 'binaries': bins,
    'no_auto_programming': True}, indent=2), encoding='utf-8')
print('PASS' if p.returncode == 0 else 'FAIL', (p.stdout + p.stderr)[-2500:])
