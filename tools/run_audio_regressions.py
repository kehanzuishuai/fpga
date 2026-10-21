from pathlib import Path
import subprocess,os,sys,json,concurrent.futures as cf,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];O=R/'tests/audio_diagnosis';IV=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
env=os.environ.copy();env['PATH']=str(IV.parent)+os.pathsep+env['PATH'];env['FPGA_IVERILOG']=str(IV);env['FPGA_VVP']=str(IV.with_name('vvp.exe'));env['PYTHONDONTWRITEBYTECODE']='1'
commands={
'piano_regression':[sys.executable,'-X','utf8','-B','-u','-c',"import os,runpy,sys;os.cpu_count=lambda:6;sys.argv=['sim/run_tests.py','all'];runpy.run_path('sim/run_tests.py',run_name='__main__')"],
'display_regression':[sys.executable,'-X','utf8','-B','-u','tests/display/scripts/verify_display.py'],
'keyboard_unit':[sys.executable,'-X','utf8','-B','-u','tools/run_keyboard_unit.py'],
'keyboard_status':[sys.executable,'-X','utf8','-B','-u','tools/run_keyboard_status.py']}
def run(item):
 name,args=item
 with (O/(name+'.log')).open('w',encoding='utf8') as log:p=subprocess.run(args,cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=10800)
 print(name,'PASS' if p.returncode==0 else 'FAILED',flush=True);return {'name':name,'returncode':p.returncode,'log':str(O/(name+'.log'))}
with cf.ThreadPoolExecutor(max_workers=4) as ex:results=list(ex.map(run,commands.items()))
# Elaborate the real physical top with actual ROMs and Gowin primitive declarations, no PLL runtime claim.
sources=[R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1' and e.attrib['path'].endswith(('.v','.sv'))]
results.append(run(('hardware_syntax',[str(IV),'-g2012','-tnull','-s','tb_hardware_elaboration','tests/integration/tb_hardware_elaboration.sv',*map(str,sources),r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\simlib\gw5a\prim_sim.v'])))
(O/'REGRESSION_RESULTS.json').write_text(json.dumps({'status':'PASS' if all(a['returncode']==0 for a in results) else 'FAILED','results':results},indent=2),encoding='utf8')
sys.exit(any(a['returncode']!=0 for a in results))
