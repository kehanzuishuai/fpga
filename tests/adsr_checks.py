from pathlib import Path
import subprocess,os,json,time,hashlib
b=Path(__file__).resolve().parents[1];o=b/'tests/out';o.mkdir(exist_ok=True);os.environ['TEMP']=str(o);os.environ['TMP']=str(o)
iv=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
parts={'envelope_observer':[b/'src/display/display_status_adapter.sv',b/'src/instruments/gongyong/yinse_envelope.sv'],'adsr_plot':[b/'src/display/visual_renderer.sv']}
result={}
for name,src in parts.items():
 for stage,args in [('compile',[iv,'-g2012','-s','tb_'+name,'-o',o/(name+'.vvp'),b/'tests'/('tb_'+name+'.sv'),*src]),('run',[iv.with_name('vvp.exe'),o/(name+'.vvp')])]:
  p=subprocess.run(list(map(str,args)),cwd=b,capture_output=True,text=True,encoding='utf8',errors='replace',timeout=180);(o/f'{name}_{stage}.log').write_text(p.stdout+p.stderr,encoding='utf8');print(name,stage,p.returncode,(p.stdout+p.stderr)[-1800:],flush=True);assert p.returncode==0
 result[name]='PASS'
(b/'tests/ADSR_TESTS.json').write_text(json.dumps({'status':'PASS','tests':result,'hardware_tested':False,'inputs':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for group in parts.values() for p in group}},indent=2))
