from pathlib import Path
import os,subprocess,json,sys
R=Path(__file__).resolve().parents[1];OUT=R/'tests/results/keyboard'
IV=Path(os.environ.get('FPGA_IVERILOG',r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe'));VV=IV.with_name('vvp.exe')
results=[]
def run(name,files):
 for suffix,args in [('compile',[IV,'-g2012','-s','tb_'+name,'-o',OUT/(name+'.vvp'),*files]),('run',[VV,OUT/(name+'.vvp')])]:
  p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=240)
  (OUT/(name+'_'+suffix+'.log')).write_text(p.stdout+p.stderr,encoding='utf-8')
  if p.returncode:raise RuntimeError(name+' '+suffix+' '+(p.stdout+p.stderr)[-2000:])
  if suffix=='run':
   assert 'PASS' in p.stdout,p.stdout
   results.append(p.stdout.strip());print(p.stdout,flush=True)
try:
 run('keyboard_events',['tests/keyboard/tb_keyboard_events.sv','src/keyboard/keyboard_state_mapper.sv','src/ttp229_event_bridge.v','src/note_event_fifo.v'])
 run('keyboard_serial',['tests/keyboard/tb_keyboard_serial.sv','src/ttp229_reader.v','sim/models/ttp229_bfm.v'])
 (OUT/'keyboard_unit_results.json').write_text(json.dumps({'status':'PASS','scope':'Protocol-independent events plus assumed TTP229-BSF serial BFM, not BIT-TREE hardware evidence','results':results},indent=2),encoding='utf-8')
except Exception as e:
 (OUT/'keyboard_unit_results.json').write_text(json.dumps({'status':'FAILED','error':str(e),'results':results},indent=2),encoding='utf-8')
 print('FAIL',e);sys.exit(1)
