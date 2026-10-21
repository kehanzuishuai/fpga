from pathlib import Path
import subprocess,json,hashlib,xml.etree.ElementTree as ET,time,sys
from datetime import datetime,timezone,timedelta
R=Path(__file__).resolve().parents[1];assert R==Path(r'D:\gaoyun\piano_v2_integrated')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
files=[R/'yinyue_fashengqi.gprj',R/'src/piano_fx.v']
files += [R/e.attrib['path'] for e in ET.parse(files[0]).findall('./FileList/File') if e.attrib.get('enable')=='1']
files=list(dict.fromkeys(files))
before={str(p.relative_to(R)):sha(p) for p in files}
start=time.time()
stamp=datetime.now(timezone(timedelta(hours=8))).isoformat()
out=R/'tests/results/gowin_final.log'
with open(out,'w',encoding='utf-8') as log:
 p=subprocess.run([r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe',str(R/'tools/build_gowin.tcl')],cwd=R,stdout=log,stderr=subprocess.STDOUT)
after={str(p.relative_to(R)):sha(p) for p in files}
fs=R/'impl/pnr/ao_0.fs';tr=R/'impl/pnr/yinyue_fashengqi.tr'
timing=tr.read_text(encoding='utf-8',errors='replace') if tr.exists() else ''
ok=p.returncode==0 and before==after and fs.is_file() and fs.stat().st_mtime>=start-2
ok=ok and '<Numbers of Setup Violated Endpoints>:0' in timing and '<Numbers of Hold Violated Endpoints>:0' in timing
data={'status':'PASS' if ok else 'FAILED','started_at_Asia_Shanghai':stamp,'command_returncode':p.returncode,'inputs_unchanged_during_build':before==after,'input_sha256':after,
'bitstream':str(fs),'bitstream_sha256':sha(fs) if fs.exists() else None,'fresh_bitstream':fs.exists() and fs.stat().st_mtime>=start-2,'log':str(out)}
(R/'audit/BUILD_INPUT_HASHES.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
outputs=[fs,tr,R/'impl/pnr/yinyue_fashengqi.rpt.txt',R/'impl/pnr/yinyue_fashengqi.pin.html',R/'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']
(R/'audit/BUILD_OUTPUT_HASHES.json').write_text(json.dumps({str(x.relative_to(R)):sha(x) for x in outputs if x.is_file()},indent=2),encoding='utf-8')
print(json.dumps(data,indent=2),flush=True)
sys.exit(0 if ok else 1)

