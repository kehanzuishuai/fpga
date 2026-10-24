"""Labels per-line region engine: full-frame raster equivalence against the previous labels."""
from pathlib import Path
import subprocess,hashlib,json,re,time
A=Path(__file__).resolve().parents[1];R=A.parents[1];O=A/'verification'
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
s=(A/'before/visual_labels.sv').read_text()
for n in re.findall(r'^\s*module\s+(\w+)',s,re.M):s=re.sub(r'\b'+n+r'\b','pre_'+n,s)
(O/'pre_visual_labels.sv').write_text(s)
files=[O/'tb_labels_line_engine.sv',O/'pre_visual_labels.sv',A/'after/src/display/visual_labels.sv']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();t=time.time()
with (O/'compile.log').open('w') as f:p=subprocess.run([str(iv),'-g2012','-s','tb_labels_line_engine','-o',str(O/'labels.vvp'),*map(str,files)],cwd=R,stdout=f,stderr=subprocess.STDOUT)
assert p.returncode==0,(O/'compile.log').read_text()[-2000:]
with (O/'simulation.log').open('w') as f:subprocess.run([str(iv.with_name('vvp.exe')),str(O/'labels.vvp')],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=7200)
out=(O/'simulation.log').read_text(errors='replace');print(out[-600:])
ok='PASS labels line_engine' in out and 'MISMATCH' not in out
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS' if ok else 'FAIL',seconds=round(time.time()-t,1),inputs={str(f):sha(f) for f in files},programming=False),indent=2))
print('RESULT',ok)
