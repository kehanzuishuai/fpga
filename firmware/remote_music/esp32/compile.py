from pathlib import Path
import subprocess,sys,os,json,hashlib
r=Path(__file__).resolve().parents[1];out=r.parents[1]/'tests/remote_music_20261019/esp32';out.mkdir(parents=True,exist_ok=True)
cli=r.parents[1]/'tools/toolchains/arduino/arduino-cli.exe'
config=cli.with_name('arduino-cli.yaml')
args=[str(cli),'--config-file',str(config),'compile','--fqbn','esp32:esp32:esp32s3','--jobs','2','--build-path',str(out/'esp32_build'),str(r/'esp32/ESP32_FPGA_Music_Controller')]
source_dir=r/'esp32/ESP32_FPGA_Music_Controller'
before={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in source_dir.iterdir() if f.is_file()}
p=subprocess.run(args,cwd=r,capture_output=True,text=True,errors='replace',timeout=900)
(out/'esp32_compile.log').write_text(p.stdout+p.stderr,encoding='utf-8')
after={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in source_dir.iterdir() if f.is_file()}
if before!=after:raise RuntimeError('Firmware changed during compilation; rerun compile.py')
toolchain=json.loads((cli.parent/'TOOLCHAIN.json').read_text())
bins={f.name:{'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in sorted((out/'esp32_build').glob('*.bin'))} if p.returncode==0 else {}
(out/'esp32_compile.json').write_text(json.dumps({'status':'PASS' if p.returncode==0 else 'FAIL','fqbn':'esp32:esp32:esp32s3','scope':'Compile only. Generic S3 configuration; match flash/PSRAM options to the physical board before upload.','sources':before,'toolchain':toolchain,'binaries':bins,'no_auto_programming':True},indent=2),encoding='utf-8')
print(p.stdout+p.stderr);sys.exit(p.returncode)
