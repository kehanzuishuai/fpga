from pathlib import Path
import shutil,subprocess,json,os
b=Path(__file__).resolve().parents[1];shutil.copy2(b.parent/'v18_octave_ui_fix_20261031/tests/keymap_regression.js',b/'tests/keymap_regression.js')
p=r'C:\Users\Yan Guyao\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe';node=r'C:\Users\Yan Guyao\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe';os.environ['TEMP']=str(b/'tests');os.environ['TMP']=str(b/'tests')
steps=[('live_control',[p,'-X','utf8','-B','-u',str(b/'tests/run_checks.py'),'control']),('modes',[p,'-X','utf8','-B','-u',str(b/'tests/run_checks.py'),'compat']),('stream_control',[p,'-X','utf8','-B','-u',str(b/'tests/run_checks.py'),'stream']),('stream_unit',[p,'-X','utf8','-B','-u',str(b/'tests/stream_rtl.py')]),('octave',[node,str(b/'tests/keymap_regression.js')])]
res={}
for name,args in steps:
 t=subprocess.run(args,capture_output=True,text=True,encoding='utf8',errors='replace',timeout=180);(b/'tests'/f'{name}_final.log').write_text(t.stdout+t.stderr,encoding='utf8');res[name]=t.returncode;print(name,t.returncode,(t.stdout+t.stderr)[-1800:],flush=True)
(b/'tests/RTL_COMPATIBILITY.json').write_text(json.dumps(res,indent=2));assert all(v==0 for v in res.values())
