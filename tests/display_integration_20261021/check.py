"""Focused boundary checks; does not rerun unrelated audio or full video regression."""
from pathlib import Path
import subprocess,os,json,hashlib,re,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out';O.mkdir(exist_ok=True)
IV=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VVP=IV.with_name('vvp.exe')
def run(name,args):
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,encoding='utf-8',errors='replace')
 (O/(name+'.log')).write_text(p.stdout+p.stderr,encoding='utf-8')
 if p.returncode:raise RuntimeError(name+': '+(p.stdout+p.stderr)[-3000:])
 return p.stdout+p.stderr
paths=[R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1']
assert len(paths)==len(set(paths)) and all(p.is_file() for p in paths)
sources=[p for p in paths if p.suffix in ['.sv','.v']]
run('board_elaboration',[IV,'-g2012','-s','tb_hardware_elaboration','-tnull',R/'tests/integration/tb_hardware_elaboration.sv',*sources,
 'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v'])
for name,src in [('status_adapter',[R/'src/display/display_status_adapter.sv']),
                 ('status_cdc',[R/'src/display/visual_status_cdc.sv'])]:
 tb=Path(__file__).resolve().parent/('tb_'+name+'.sv')
 run(name+'_compile',[IV,'-g2012','-s','tb_'+name,'-o',O/(name+'.vvp'),*src,tb])
 result=run(name,[VVP,O/(name+'.vvp')]);assert 'PASS' in result and 'FATAL' not in result
 print(result.strip(),flush=True)
before=json.loads((R/'audit/display_integration_20261021/BEFORE.json').read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
old_web=R/'audit/display_integration_20261021/optimization/web_page.before_guidance_activation.h'
new_web=R/'firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/web_page.h'
assert sha(old_web)==before['phone_unchanged']['firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/web_page.h']
payloads=lambda p:dict(re.findall(r'const char (\w+)\[\] PROGMEM=R"MUSICWEB\((.*?)\)MUSICWEB";',p.read_text(encoding='utf-8'),re.S))
old_payloads,new_payloads=payloads(old_web),payloads(new_web)
assert old_payloads.keys()==new_payloads.keys() and len(old_payloads)==10
for name in old_payloads:
 if name!='APP_JS':assert old_payloads[name]==new_payloads[name],name
assert new_payloads['APP_JS']==(R/'firmware/remote_music/shouji/app.js').read_text(encoding='utf-8')
for p in ['src/integrated.cst','src/integrated.sdc','src/display/visual_video_clock.v','src/display/visual_dvi_io.v',
          'src/piano_partial_voice.v','src/piano_note_loader.v','src/piano_fx.v','src/i2s_tx.v','src/pcm5102_i2s_tx.v']:
 if p in ['src/integrated.cst','src/integrated.sdc'] and sha(R/p)!=before['files'][p]:
  clock_check=json.loads((R/'audit/clock_constraints_20261022/RESULT.json').read_text())
  assert clock_check['status']=='PASS_STATIC_AND_TCL_ONLY_IMPLEMENTATION_PENDING'
  assert sha(R/p)==clock_check['constraints'][p]['after_sha256'],p
  original=R/'audit/clock_constraints_20261022/before'/p
  assert sha(original)==before['files'][p] and (R/p).read_text().startswith(original.read_text().rstrip()),p
 else:assert sha(R/p)==before['files'][p],p
record={'status':'PASS','enabled_inputs':len(paths),'board_elaboration':True,'phone_style_and_html_unchanged':True,
 'phone_change':'Only APP_JS: activate approved existing practice container with existing segments CSS and actual FPGA capability/readback',
 'scope':'512-bit real telemetry mapping, peak meter endpoints, ready/backpressure, atomic frame CDC, real board+vendor primitives elaboration; no full-frame rerun',
 'source_sha256':{p.relative_to(R).as_posix():sha(p) for p in paths},
 'asset_sha256':{p.relative_to(R).as_posix():sha(p) for p in (R/'assets').glob('*.hex')}}
(O/'CHECKS.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print('PASS project closure; audio/DAC/pins and phone HTML/CSS unchanged; only verified GAO/primary-clock constraints appended; approved practice activation in APP_JS only',flush=True)
