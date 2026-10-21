from pathlib import Path
import os,subprocess,json,sys,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];OUT=R/'tests/results/keyboard'
IV=Path(os.environ.get('FPGA_IVERILOG',r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe'));VV=IV.with_name('vvp.exe')
excluded={'audio_pll.v','audio_pll_mod.v','visual_video_clock.v','visual_dvi_io.v','visual_pll_mod.v','pll_init.v','piano_level_rom.v','piano_ratio_rom.v','piano_note_rom.v','piano_sine_rom.v','piano_exp_rom.v'}
sources=[R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1']
sources=[p for p in sources if p.suffix in ['.v','.sv'] and p.name not in excluded]
extra=['tests/keyboard/tb_keyboard_system.sv','sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/integration/video_boundary_stub.v','tests/display/sim/tmds_stream_checker.sv']
try:
 for stage,args in [('compile',[IV,'-g2012','-s','tb_keyboard_system','-o',OUT/'keyboard_system.vvp',*sources,*extra]),('run',[VV,OUT/'keyboard_system.vvp'])]:
  p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=3600)
  text=p.stdout+p.stderr;(OUT/('keyboard_system_'+stage+'.log')).write_text(text,encoding='utf-8')
  if p.returncode:raise RuntimeError(stage+' '+text[-2500:])
  if stage=='run':assert 'PASS keyboard system' in text;print(text,flush=True)
 (OUT/'keyboard_system_results.json').write_text(json.dumps({'status':'PASS','scope':'Unconfirmed TTP16 profile, real 32Voice/FX/FFT/TMDS logic; equivalent array ROM and nominal PLL/serializer boundary models','result':text},indent=2),encoding='utf-8')
except Exception as e:
 (OUT/'keyboard_system_results.json').write_text(json.dumps({'status':'FAILED','error':str(e)},indent=2),encoding='utf-8')
 print('FAIL',e);sys.exit(1)
