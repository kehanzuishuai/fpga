from pathlib import Path
import sys,subprocess,hashlib,json,time,os
sys.path.insert(0,str(Path(__file__).resolve().parent))
from run_checks import full_sources
B=Path(__file__).resolve().parents[1];O=B/'tests/out';A=B.parent/'v19_polyphonic_stream_20261031'
IV=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe');os.environ['TEMP']=str(O);os.environ['TMP']=str(O)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
results={}
for label,base in [('before',A),('after',B)]:
 files=[base/p.relative_to(B) if p.is_relative_to(B) else p for p in full_sources()]
 files=[B/'tests/tb_audio_readonly.sv',*files,B.parents[1]/'sim/models/i2s_rx_model.v']
 target=O/f'audio_{label}.vvp';pcm=O/f'audio_{label}.hex';started=time.time();inputs={str(p):sha(p) for p in files}
 for step,args in [('compile',[IV,'-g2012','-s','tb_audio_readonly','-o',target,*files]),('run',[IV.with_name('vvp.exe'),target,'+PCM='+str(pcm)])]:
  with (O/f'audio_{label}_{step}.log').open('w') as log:p=subprocess.run(list(map(str,args)),cwd=B,stdout=log,stderr=subprocess.STDOUT,timeout=3600)
  text=(O/f'audio_{label}_{step}.log').read_text(errors='replace');print(label,step,p.returncode,text[-500:],flush=True);assert p.returncode==0
 assert inputs=={str(p):sha(p) for p in files}, 'source changed during audio test'
 results[label]={'pcm_sha256':sha(pcm),'frames':len(pcm.read_text().splitlines()),'elapsed_seconds':time.time()-started,'inputs':inputs}
assert results['before']['pcm_sha256']==results['after']['pcm_sha256'], 'PCM changed'
(B/'tests/AUDIO_READONLY.json').write_text(json.dumps({'status':'PASS','results':results,'scope':'five timbres, three-note stream chord and independent releases, actual32 synth/FX/master and both DAC paths, ROM/PLL models, display disabled; bit-exact PCM comparison','hardware_tested':False},indent=2))
print('PASS five-timbre before/after PCM byte-identical',results['after']['frames'],flush=True)
