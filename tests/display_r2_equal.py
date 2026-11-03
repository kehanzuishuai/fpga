from pathlib import Path
import subprocess,hashlib,json,os,re
B=Path(__file__).resolve().parents[1];C=B/'audit/timing_candidate_r2';F=B/'audit/native_runs/adsr_layout_r1';O=B/'tests/out';iv=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe');os.environ['TEMP']=str(O);os.environ['TMP']=str(O)
for stage,args in [('compile',[iv,'-g2012','-s','tb_indicator_equal','-o',O/'indicator_equal.vvp',O/'tb_indicator_equal.sv']),('run',[iv.with_name('vvp.exe'),O/'indicator_equal.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=B,capture_output=True,text=True,timeout=180);(O/f'indicator_equal_{stage}.log').write_text(p.stdout+p.stderr);print(stage,p.returncode,(p.stdout+p.stderr)[-1200:],flush=True);assert p.returncode==0
# Move all validity gating outside the popcount tree: exact for the actual
# target_valid expression (which necessarily implies keys_valid).
assert "c_target_count<=count_target_valid?count_voices(count_status[458+:32] & ~count_status[18+:32]):6'd0;" in (C/'src/display/visual_labels.sv').read_text()
assert "c_wrong_count<=count_target_valid?count_voices(count_status[18+:32] & ~count_status[458+:32]):6'd0;" in (C/'src/display/visual_labels.sv').read_text()
import random
random.seed(20261101)
for _ in range(100000):
 keys=random.getrandbits(32);targets=random.getrandbits(32)
 for kv,tv in [(0,0),(1,0),(1,1)]:
  actual=keys if kv else 0;wanted=targets if tv else 0
  before=((wanted&~actual).bit_count(),actual.bit_count(),(actual&~wanted).bit_count() if tv else 0)
  after=((targets&~keys).bit_count() if tv else 0,keys.bit_count() if kv else 0,(keys&~targets).bit_count() if tv else 0)
  assert before==after
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
proof={'status':'PASS','scope':'production-extracted glyph geometry/ROM pipeline at fixed end-to-end latency, gradient exact in visible well; 300000 valid-popcount-gating vectors','inputs':{str(p):sha(p) for p in [F/'src/display/visual_renderer.sv',C/'src/display/visual_renderer.sv',F/'src/display/visual_labels.sv',C/'src/display/visual_labels.sv',O/'tb_indicator_equal.sv']}}
(B/'audit/DISPLAY_R2_EQUIVALENCE.json').write_text(json.dumps(proof,indent=2));print('PASS glyph/gradient and count gating equivalence')
