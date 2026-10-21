from pathlib import Path
import subprocess,sys,re,json,os,hashlib,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];os.chdir(R)
OUT=R/'tests/results/integration';OUT.mkdir(parents=True,exist_ok=True)
IV=Path(os.environ.get('FPGA_IVERILOG',r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe'))
VVP=IV.with_name('vvp.exe');results=[]
def run(name,args,timeout=1800):
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=timeout)
 (OUT/(name+'.log')).write_text(p.stdout+p.stderr,encoding='utf-8')
 if p.returncode:raise RuntimeError(name+': '+(p.stdout+p.stderr)[-2500:])
 return p.stdout+p.stderr
try:
 tree=ET.parse(R/'yinyue_fashengqi.gprj')
 entries=tree.findall('./FileList/File')
 paths=[R/e.attrib['path'] for e in entries if e.attrib.get('enable')=='1']
 assert all(p.is_file() for p in paths),'missing project dependency'
 assert len(paths)==len(set(paths)),'duplicate file reference'
 sources=[p for p in paths if p.suffix in ('.v','.sv')]
 modules={}
 for p in sources:
  data=p.read_text(encoding='utf-8-sig')
  data=re.sub(r'/\*.*?\*/|//[^\n]*','',data,flags=re.S)
  for n in re.findall(r'\bmodule\s+(\w+)',data):
   assert n not in modules,'duplicate module '+n
   modules[n]=str(p)
 protected=['synth_core.v','voice_bank.v','voice_allocator.v','piano_note_loader.v','piano_partial_voice.v','piano_fx.v','pcm5102_i2s_tx.v','ttp229_reader.v','ttp229_event_bridge.v']
 for n in protected:assert (R/'src'/n).read_bytes()==(Path(r'D:\gaoyun\piano_v2')/'src'/n).read_bytes()
 results.append('project dependency paths, unique enabled modules, protected original core hashes PASS')
 # Compile actual board RTL against vendor primitives, without running physical PLL models.
 run('hardware_syntax',[IV,'-g2012','-s','tb_hardware_elaboration','-tnull',R/'tests/integration/tb_hardware_elaboration.sv',*sources,
 Path(r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\simlib\gw5a\prim_sim.v')])
 results.append('actual board RTL + Gowin GW5A primitive declarations elaboration PASS')
 original=Path(r'D:\gaoyun\piano_v2')
 for n,new in [('i2s_tx.v','baseline_i2s'),('synth_top.v','baseline_synth'),('tang_mega_138k_pro_top.v.v','baseline_board')]:
  text=(original/'src'/n).read_text(encoding='utf-8')
  if n=='i2s_tx.v':text=re.sub(r'\bi2s_tx\b','baseline_i2s',text)
  if n=='synth_top.v':
   text=re.sub(r'\bsynth_top\b','baseline_synth',text);text=re.sub(r'\bi2s_tx\b','baseline_i2s',text)
  if n=='tang_mega_138k_pro_top.v.v':
   text=re.sub(r'\btang_mega_138k_pro_top\b','baseline_board',text);text=re.sub(r'\bsynth_top\b','baseline_synth',text)
  (OUT/(new+'.v')).write_text(text,encoding='utf-8')
 exclude={'audio_pll.v','audio_pll_mod.v','visual_video_clock.v','visual_dvi_io.v','visual_pll_mod.v','pll_init.v','piano_level_rom.v','piano_ratio_rom.v','piano_note_rom.v','piano_sine_rom.v','piano_exp_rom.v'}
 functional=[p for p in sources if p.name not in exclude]
 extra=[R/'sim/models/piano_roms_fast.v',R/'sim/models/ttp229_bfm.v',R/'sim/models/gowin_pll_stub.v',R/'tests/integration/video_boundary_stub.v',
 R/'tests/display/sim/tmds_stream_checker.sv',R/'tests/integration/tb_integrated_system.sv',
 *[OUT/(n+'.v') for n in ['baseline_i2s','baseline_synth','baseline_board']]]
 run('integrated_compile',[IV,'-g2012','-s','tb_integrated_system','-o',OUT/'integrated.vvp',*functional,*extra])
 output=run('integrated_system',[VVP,OUT/'integrated.vvp'],3600)
 assert 'PASS integrated system:' in output and 'FATAL' not in output
 print(output,flush=True);results.append(output.strip())
 (OUT/'results.json').write_text(json.dumps({'status':'PASS','scope':'Functional simulation: nominal PLL/serializer substitutes and exhaustive-address-equivalent array piano ROMs. Actual hardware ROMs separately elaborated against GW5A primitives and implemented by Gowin.','results':results},indent=2),encoding='utf-8')
except Exception as e:
 (OUT/'results.json').write_text(json.dumps({'status':'FAILED','error':str(e),'results':results},indent=2),encoding='utf-8')
 print('FAIL',e,flush=True);sys.exit(1)



