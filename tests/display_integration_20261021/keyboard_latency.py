"""Only production keyboard -> real32 piano/FX/master -> decoded dual DAC latency."""
from pathlib import Path
import sys,subprocess,json,hashlib,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
sys.path.insert(0,str(R/'tools'))
from continue_audio_audit import sources,IV,VV
files=[*sources(),R/'tests/display_integration_20261021/tb_keyboard_latency.sv',
 R/'sim/models/piano_roms_fast.v',R/'sim/models/gowin_pll_stub.v',R/'sim/models/ttp229_bfm.v',R/'sim/models/i2s_rx_model.v',R/'tests/display_upgrade_20261018/video_boundary_stub.v']
vendor_primitives=Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before={p.relative_to(R).as_posix():sha(p) for p in files}
for name,args in [('keyboard_latency_compile',[IV,'-g2012','-s','tb_keyboard_latency','-o',O/'keyboard_latency.vvp',*files,vendor_primitives]),
                  ('keyboard_latency',[VV,O/'keyboard_latency.vvp'])]:
 with (O/(name+'.log')).open('w') as log:p=subprocess.run(list(map(str,args)),cwd=R,stdout=log,stderr=subprocess.STDOUT)
 text=(O/(name+'.log')).read_text(errors='replace')
 if p.returncode:raise RuntimeError(text[-3500:])
 print(text[-3000:] if name=='keyboard_latency' else name+' PASS',flush=True)
assert before=={p.relative_to(R).as_posix():sha(p) for p in files},'Inputs changed'
assert 'PASS focused' in text
fields='case mask phase accepted_keys_ns first_event_ns first_pcm_ns first_pt8211_word_ns first_pcm5102_frame_ns last_individual_voice_ns'.split()
rows=[dict(zip(fields,[int(x,16) if i==1 else int(x) for i,x in enumerate(m.split(','))])) for m in re.findall(r'^RESULT,(.*)$',text,re.M)]
record={'status':'PASS','scope':'Digital signal ready at TTP model -> real board DISPLAY_ENABLE=0, production clock frequency, readers/remote arbitration/FIFO/32piano/FX/master/both pin decoders. PLL behavioral, original ROM contents. No TTP internal sensing, DAC analog, speaker or display latency claim.',
 'single_key_digital_limit_ns':5000000,'rows':rows,'source_sha256':before}
(O/'KEYBOARD_LATENCY.json').write_text(json.dumps(record,indent=2))
