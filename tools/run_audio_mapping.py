from pathlib import Path
import os,subprocess,xml.etree.ElementTree as ET,sys,json
R=Path(__file__).resolve().parents[1];O=R/'tests/audio_diagnosis';IV=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
excluded={'audio_pll.v','audio_pll_mod.v','visual_video_clock.v','visual_dvi_io.v','visual_pll_mod.v','pll_init.v','piano_level_rom.v','piano_ratio_rom.v','piano_note_rom.v','piano_sine_rom.v','piano_exp_rom.v'}
sources=[R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1'];sources=[p for p in sources if p.suffix in ['.v','.sv'] and p.name not in excluded]
extra=['tests/audio_diagnosis/tb_audio_note_map.sv','sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/integration/video_boundary_stub.v']
tag=sys.argv[1] if len(sys.argv)>1 else 'after'
for name,args in [('compile',[IV,'-g2012','-s','tb_audio_note_map','-o',O/'mapping.vvp',*sources,*extra]),('run',[IV.with_name('vvp.exe'),O/'mapping.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=7200)
 (O/f'mapping_{tag}_{name}.log').write_text(p.stdout+p.stderr,encoding='utf8');print(p.stdout+p.stderr,flush=True)
 if p.returncode:sys.exit(p.returncode)
assert 'PASS default map/chain' in p.stdout
