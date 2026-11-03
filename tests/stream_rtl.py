from pathlib import Path
import subprocess,os,json
b=Path(__file__).resolve().parents[1];o=b/'tests/out';o.mkdir(exist_ok=True)
os.environ['TEMP']=str(o);os.environ['TMP']=str(o)
iv=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
for name,args in [('stream_compile',[iv,'-g2012','-s','tb_stream','-o',o/'stream.vvp',b/'tests/tb_stream.sv',b/'src/remote/control/wifi_control.sv']),('stream',[iv.with_name('vvp.exe'),o/'stream.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=b,capture_output=True,text=True,timeout=180);(o/(name+'.log')).write_text(p.stdout+p.stderr);print(name,p.returncode,p.stdout,p.stderr,flush=True);assert p.returncode==0
