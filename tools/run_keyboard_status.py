from pathlib import Path
import subprocess,os,json,sys
R=Path(__file__).resolve().parents[1];O=R/'tests/results/keyboard'
IV=Path(os.environ.get('FPGA_IVERILOG',r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe'));VV=IV.with_name('vvp.exe')
results=[]
try:
 for top,tb in [('tb_keyboard_hud','tests/keyboard/tb_keyboard_hud.sv'),('tb_status_interfaces','tests/integration/tb_status_interfaces.sv')]:
  files=[tb,'src/display/piano_status_overlay.sv','src/display/piano_status_cdc.v','src/display/yinse_display_info.sv']
  for suffix,args in [('compile',[IV,'-g2012','-s',top,'-o',O/(top+'.vvp'),*files]),('run',[VV,O/(top+'.vvp')])]:
   p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True)
   (O/(top+'_'+suffix+'.log')).write_text(p.stdout+p.stderr,encoding='utf-8')
   if p.returncode:raise RuntimeError(top+' '+(p.stdout+p.stderr)[-1200:])
   if suffix=='run':assert 'PASS' in p.stdout;results.append(p.stdout.strip());print(p.stdout,flush=True)
 (O/'keyboard_status_results.json').write_text(json.dumps({'status':'PASS','results':results},indent=2),encoding='utf-8')
except Exception as e:
 print('FAIL',e);sys.exit(1)
