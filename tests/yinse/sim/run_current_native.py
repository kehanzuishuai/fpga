"""Native execution of original src, preserves lint diagnostics in build log.
This is a two-state simulator. It complements, not replaces, four-state tests.
"""
from pathlib import Path
import os,subprocess,xml.etree.ElementTree as ET,json
BASE=Path(__file__).resolve().parents[2];OUT=BASE/'yinse/sim/audit'
VERILATOR=Path(os.environ['APPDATA'])/'Python/Python313/Scripts/verilator-cli.exe'
VCVARS=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat')
env=dict(os.environ,LANG='C',LC_ALL='C')
env['PATH']='C:/Strawberry/perl/bin;'+env['PATH']
obj=OUT/'obj_native';obj.mkdir(exist_ok=True)
files=[BASE/f.attrib['path'] for f in ET.parse(BASE/'yinyue_fashengqi.gprj').findall('.//File') if f.attrib.get('enable')=='1' and f.attrib.get('type')=='file.verilog' and 'gowin_pll' not in f.attrib['path'] and 'tang_mega' not in f.attrib['path']]
cmd=[VERILATOR,'--cc','--exe','--no-timing','--Wall','-Wno-fatal','+1364-2005ext+v',
     '--top-module','current_piano_native_top','--Mdir',obj,*files,BASE/'yinse/sim/current_piano_native_top.v',BASE/'yinse/sim/current_piano_native.cpp']
with (OUT/'current_native_build.log').open('w') as log:
 p=subprocess.run(list(map(str,cmd)),cwd=BASE,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=900)
if p.returncode:raise SystemExit('Native build failed; see current_native_build.log')
include=VERILATOR.parent.parent/'site-packages/verilator/include'
exe=obj/'Vcurrent_piano_native_top.exe'
classes=[];reading=False
for line in (obj/'Vcurrent_piano_native_top_classes.mk').read_text().splitlines():
 if line.startswith(('VM_CLASSES_FAST +=','VM_CLASSES_SLOW +=','VM_SUPPORT_FAST +=','VM_SUPPORT_SLOW +=')):
  reading=True;continue
 if not line.strip() or line.startswith('#'):reading=False;continue
 if reading:
  name=line.strip().rstrip('\\').strip()
  if name:classes.append(obj/(name+'.cpp'))
args=['/nologo','/std:c++20','/O2','/EHsc','/MD','/DVL_TIME_CONTEXT','/DVM_TIMING=0','/DVM_TRACE=0','/DVM_COVERAGE=0',
      '/I'+str(include),'/I'+str(include/'vltstd'),'/I'+str(obj),'/Fe:'+str(exe),'/Fo:'+obj.as_posix()+'/',
      str(BASE/'yinse/sim/current_piano_native.cpp'),str(include/'verilated.cpp'),str(include/'verilated_threads.cpp'),
      *map(str,classes),'/link','ws2_32.lib']
rsp=OUT/'native_cl.rsp'
# MSVC response files accept one quoted argument per line; filenames are fixed
# local paths, not shell expressions. All object/executable outputs stay in obj.
rsp.write_text('\n'.join('"'+a+'"' for a in args),encoding='utf-8')
batch=OUT/'native_build.cmd'
batch.write_text('@echo off\ncall "'+str(VCVARS)+'" >nul\ncl @"'+str(rsp)+'"\nexit /b %errorlevel%\n',encoding='utf-8')
with (OUT/'current_native_compiler.log').open('w') as log:
 p=subprocess.run(['cmd.exe','/c',str(batch)],cwd=obj,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=900)
if p.returncode:raise SystemExit('MSVC build failed; see current_native_compiler.log')
with (OUT/'current_native.log').open('w') as log:
 p=subprocess.run([str(exe)],cwd=BASE,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=300)
(OUT/'current_native_result.json').write_text(json.dumps({'status':'PASS' if p.returncode==0 else 'FAIL','two_state':True,'strict_lint_pass':False,'exit_code':p.returncode},indent=2))
print((OUT/'current_native.log').read_text());raise SystemExit(p.returncode)
