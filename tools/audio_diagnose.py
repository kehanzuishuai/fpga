from pathlib import Path
import sys,os,re,json,subprocess,concurrent.futures as cf,wave,hashlib,csv,time
import numpy as np
R=Path(__file__).resolve().parents[1];O=R/'tests/audio_diagnosis';os.chdir(R)
sys.path.insert(0,str(R/'tools'))
import piano_tables as pt,fpga_piano_model as fm,fx_model
IV=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe');VV=IV.with_name('vvp.exe')
T=pt.build();FS=48000;N=144000;OFF=96000
NOTES=list(range(60,76))+[24,36,48,84,104]
def run(args,log,timeout=7200):
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,encoding='utf8',errors='replace',timeout=timeout)
 log.parent.mkdir(parents=True,exist_ok=True);log.write_text(p.stdout+p.stderr,encoding='utf8')
 if p.returncode:raise RuntimeError(str(args)+' '+(p.stdout+p.stderr)[-1500:])
 return p.stdout+p.stderr
def wav(path,y):
 y=np.asarray(y,dtype=np.int64);v=y.astype(np.int32).astype(np.uint32);b=np.column_stack([v&255,(v>>8)&255,(v>>16)&255]).astype(np.uint8)
 with wave.open(str(path),'wb') as f:f.setparams((1,3,FS,len(y),'NONE','not compressed'));f.writeframes(b.tobytes())
def voice(note):
 d=O/'baseline'/f'midi_{note:03d}';d.mkdir(parents=True,exist_ok=True)
 text=run([VV,O/'voice.vvp',f'+note={note}','+vel=100','+on=4',f'+off={OFF}',f'+ticks={N}',f'+log={d / "rtl_voice.txt"}'],d/'sim.log')
 assert 'SIM DONE' in text and 'FAIL' not in text
 text=run([sys.executable,'-X','utf8','-B','tools/compare_pcm.py',d/'rtl_voice.txt','--hammer','1'],d/'equivalence.log')
 assert 'PASS: RTL and model are bit-exact' in text,text
 y=np.zeros(N,dtype=np.int64)
 for line in (d/'rtl_voice.txt').read_text().splitlines():
  a=line.split()
  if a and a[0]=='S' and int(a[1])<N:y[int(a[1])]=int(a[2])
 gain=(y*32767)>>15
 np.save(d/'voice.npy',y);np.save(d/'gain.npy',gain)
 name=['C','Cs','D','Ds','E','F','Fs','G','Gs','A','As','B'][note%12]+str(note//12-1)
 wav(d/f'midi_{note:03d}_{name}_fx_off.wav',gain)
 np.savetxt(d/'fx_input.txt',gain,fmt='%d')
 # The reference model is accepted only after full-duration voice RTL equivalence.
 fx=fx_model.Fx();post=fx.process(gain)
 np.save(d/'fx.npy',post);wav(d/f'midi_{note:03d}_{name}_fx_on.wav',post)
 text=run([VV,O/'fx.vvp',f'+input={d/"fx_input.txt"}',f'+output={d/"rtl_fx.txt"}',f'+samples={N}'],d/'fx_sim.log')
 assert 'PASS FX stream' in text,text
 actual=np.loadtxt(d/'rtl_fx.txt',dtype=np.int64)
 assert np.array_equal(actual,post),f'FX mismatch note {note}: '+str(np.flatnonzero(actual!=post)[:10])
 result={'note':note,'velocity':100,'samples':N,'note_off_tick':OFF,'voice_equivalence':'all computed samples including release; original loader timing','fx_equivalence':'all 144000 samples, 32-clock valid spacing after reset RAM clear','status':'PASS','voice_log':str(d/'equivalence.log')}
 (d/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8')
 print('PASS baseline',note,'voice and FX full-duration bit-exact',flush=True);return result
if __name__=='__main__':
 start=time.time();O.mkdir(parents=True,exist_ok=True)
 run([IV,'-g2012','-s','tb_piano_voice','-o',O/'voice.vvp','sim/tb/tb_piano_voice.v','src/piano_partial_voice.v','src/piano_note_loader.v','src/note_freq_table.v','sim/models/piano_roms_fast.v'],O/'voice_compile.log')
 run([IV,'-g2005','-s','tb_audio_fx','-o',O/'fx.vvp',O/'tb_audio_fx.v','src/piano_fx.v'],O/'fx_compile.log')
 results=[];failed=[]
 with cf.ThreadPoolExecutor(max_workers=4) as ex:
  tasks={ex.submit(voice,n):n for n in NOTES}
  for t in cf.as_completed(tasks):
   try:results.append(t.result())
   except Exception as e:failed.append({'note':tasks[t],'error':str(e)});print('FAIL',tasks[t],e,flush=True)
 (O/'BASELINE_RUN.json').write_text(json.dumps({'status':'PASS' if not failed else 'FAILED','results':results,'failures':failed,'elapsed_seconds':time.time()-start},indent=2),encoding='utf8')
 sys.exit(bool(failed))
