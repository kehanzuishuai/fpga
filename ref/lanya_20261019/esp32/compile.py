from pathlib import Path
import subprocess,sys,os,json,hashlib
r=Path(__file__).resolve().parents[1];out=r/'sim/out';out.mkdir(exist_ok=True)
cli=Path(r'D:/ArduinoIDE/resources/app/lib/backend/resources/arduino-cli.exe')
args=[str(cli),'compile','--fqbn','esp32:esp32:esp32s3','--build-path',str(out/'esp32_build'),'--build-cache-path',str(out/'esp32_cache'),str(r/'esp32/ESP32_FPGA_Music_Controller')]
source_dir=r/'esp32/ESP32_FPGA_Music_Controller'
before={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in source_dir.iterdir() if f.is_file()}
p=subprocess.run(args,cwd=r,capture_output=True,text=True,errors='replace',timeout=900)
(out/'esp32_compile.log').write_text(p.stdout+p.stderr,encoding='utf-8')
after={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in source_dir.iterdir() if f.is_file()}
if before!=after:raise RuntimeError('Firmware changed during compilation; rerun compile.py')
(out/'esp32_compile.json').write_text(json.dumps({'status':'PASS' if p.returncode==0 else 'FAIL','fqbn':'esp32:esp32:esp32s3','scope':'Compile only. Generic S3 configuration; match flash/PSRAM options to the physical board before upload.','sources':before},indent=2),encoding='utf-8')
print(p.stdout+p.stderr);sys.exit(p.returncode)
