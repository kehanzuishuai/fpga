"""Integration verification entry point. Never programs hardware."""
from pathlib import Path
import subprocess,sys,re,xml.etree.ElementTree as ET,hashlib,json,time
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'tests/remote_music_20261019/out'
IVER=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
VVP=IVER.with_name('vvp.exe')
def run(name,args,timeout=1200):
 OUT.mkdir(parents=True,exist_ok=True)
 # Icarus resolves every partial output driver against an entire 12,768-bit
 # packed bus. Separate one-driver words have identical four-state connectivity
 # and avoid that simulator cost. No arithmetic, register, clock or state changes.
 bank=ROOT/'src/instruments/gongyong/yinse_aux_bank.sv'
 model=OUT/'yinse_aux_bank_netview.sv';manifest=OUT/'BANK_SIM_VIEW.json'
 replacements=[
  ('wire [VOICES*399-1:0] queries;wire [LANES*334-1:0] results;', 'wire [398:0] queries[0:VOICES-1];wire [333:0] results[0:LANES-1];'),
  ('queries[(lane*THREADS+thread)*399+:399]', 'queries[lane*THREADS+thread]'),
  ('results[lane*334+:334]', 'results[lane]'),
  ('results[(g/THREADS)*334+:334],queries[g*399+:399]', 'results[g/THREADS],queries[g]')]
 original=bank.read_text();view=original
 for old,new in replacements:
  assert view.count(old)==1,old
  view=view.replace(old,new)
 if not model.exists() or model.read_text()!=view:model.write_text(view)
 info={'scope':'Connectivity-only Icarus view: packed disjoint bus drivers become separate word nets. Arithmetic/state/clock unchanged. Production GPRJ uses original source; mapped gate comparison uses actual Gowin primitives.',
  'original':bank.relative_to(ROOT).as_posix(),'original_sha256':hashlib.sha256(bank.read_bytes()).hexdigest(),'generated':model.relative_to(ROOT).as_posix(),'generated_sha256':hashlib.sha256(model.read_bytes()).hexdigest(),'replacements':replacements}
 serialized=json.dumps(info,indent=2)
 if not manifest.exists() or manifest.read_text()!=serialized:manifest.write_text(serialized)
 args=[model if str(x).replace('\\','/').lower() in (bank.as_posix().lower(),bank.relative_to(ROOT).as_posix().lower()) else x for x in args]
 def inputs():
  files=[*sorted((ROOT/'src').rglob('*')),ROOT/'yinyue_fashengqi.gprj',ROOT/'tools/build_gowin.tcl',model,manifest,*sorted((ROOT/'firmware/remote_music/esp32/ESP32_FPGA_Music_Controller').glob('*'))]
  return {p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.is_file()}
 before=inputs();started=time.time()
 with (OUT/f'{name}.log').open('w',encoding='utf-8') as f:
  p=subprocess.run([str(x) for x in args],cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
 text=(OUT/f'{name}.log').read_text(encoding='utf-8',errors='replace')
 print(name,'exit',p.returncode,flush=True)
 useful='\n'.join(x for x in text.splitlines() if 'sorry: constant selects in always_*' not in x)
 print(useful[-5000:],flush=True)
 if p.returncode:raise SystemExit(p.returncode)
 if ('compile' in name or name=='elaborate') and re.search(r'warning: Port|implicit definition',text):
  raise RuntimeError('Port-width or implicit-net warning: '+name)
 after=inputs()
 (OUT/(name+'.json')).write_text(json.dumps({'status':'PASS' if p.returncode==0 and before==after else 'FAIL','returncode':p.returncode,'elapsed_s':time.time()-started,'input_sha256':before,'inputs_unchanged':before==after},indent=2),encoding='utf-8')
 if before!=after:raise RuntimeError('Sources changed while running '+name)
def sources():
 paths=[]
 for f in ET.parse(ROOT/'yinyue_fashengqi.gprj').findall('.//File'):
  path=f.get('path','')
  if f.get('enable')=='1' and Path(path).suffix in ('.v','.sv'):
   if path.startswith('src/gowin_pll/') or Path(path).stem in ('visual_video_clock','visual_dvi_io'):continue
   if path in ['src/piano_note_rom.v','src/piano_ratio_rom.v','src/piano_sine_rom.v','src/piano_exp_rom.v','src/piano_level_rom.v']:continue
   paths.append(path)
 return paths+['sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','tests/display_upgrade_20261018/video_boundary_stub.v']
def compile_top():
 run('elaborate',[IVER,'-g2012','-s','tang_mega_138k_pro_top','-o',OUT/'top.vvp',*sources()])
def bench(name,files):
 target=OUT/f'{name}.vvp'
 run(name+'_compile',[IVER,'-g2012','-s','tb_'+name,'-o',target,f'tests/remote_music_20261019/tb_{name}.sv',*files])
 run(name,[VVP,target],2400 if name=='aux' else 1200)
if __name__=='__main__':
 OUT.mkdir(parents=True,exist_ok=True)
 if sys.argv[1]=='elaborate':compile_top()
 elif sys.argv[1]=='wav':bench('wav',['src/remote/wav_spi_stream.sv','src/remote/wav_pcm_player.sv'])
 elif sys.argv[1]=='aux':bench('aux',list((ROOT/'src/instruments').rglob('*.sv')))
 elif sys.argv[1]=='control':bench('control',[*list((ROOT/'src/remote/uart').glob('*.sv')),'src/remote/wifi_core.sv','src/remote/control/wifi_control.sv','src/remote/control/wifi_score_player.sv','src/remote/remote_control.sv','src/ttp229_event_bridge.v'])
 else:raise SystemExit('unknown action')
