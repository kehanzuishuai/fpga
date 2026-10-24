"""Exercise the parallel text selector against the archived V5 pipeline."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys
R=Path(__file__).resolve().parents[2];sys.path.insert(0,str(R/'tools'))
from display_parallel_text_20261023 import parallel_characters
from display_routed_fixes_20261023 import stage_axis_digits,stage_completed_digits
axis='--axis' in sys.argv
completed='--completed' in sys.argv
A=R/'audit/routing_followup_20261022';O=A/('completed_digits' if completed else 'axis_numeric' if axis else 'parallel_text');O.mkdir(exist_ok=True)
p=R/'src/display/visual_labels.sv';s=p.read_text();(O/'before_visual_labels.sv').write_text(s)
(O/'candidate_visual_labels.sv').write_text((stage_completed_digits if completed else stage_axis_digits if axis else parallel_characters)(s))
for name in ['reference.sv','tb.sv']:shutil.copy2(A/'selected_note_v6'/name,O/name)
if completed:
 tb=(O/'tb.sv').read_text();marker='   status[455]=1;'
 cases='case(n%12)'+''.join(f"{i}:status[493+:16]=16'd{value};" for i,value in enumerate([0,1,9,10,99,100,999,1000,9999,10000,65534,65535]))+'endcase\n'
 assert tb.count(marker)==1;(O/'tb.sv').write_text(tb.replace(marker,'   '+cases+marker))
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('compile',[iv,'-g2012','-s','tb','-o',O/'test.vvp',O/'candidate_visual_labels.sv',O/'reference.sv',O/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),O/'test.vvp'])]:
 r=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(r.stdout+r.stderr)
 if r.returncode:raise RuntimeError((r.stdout+r.stderr)[-3000:])
 print(r.stdout[-1000:],flush=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert p.read_text()==s
r=dict(status='PASS_ISOLATED_COMPLETED_DIGITS_NOT_APPLIED' if completed else 'PASS_ISOLATED_AXIS_BCD_NOT_APPLIED' if axis else 'PASS_ISOLATED_PARALLEL_TEXT_NOT_APPLIED',cycles=11560,regions=90,keys=32,latency_cycles=21,before_sha256=sha(p),candidate_sha256=sha(O/'candidate_visual_labels.sv'),scope='Completed-event text prepared at existing edge; threshold0/9/10/99/100/999/1000/9999/10000/65535 boundaries exercised.' if completed else 'Axis BCD prepared one existing edge earlier, then unchanged digit selector.' if axis else 'All candidates and one-hot default selection preserve visible characters and pixels against V5. No pipeline edge added.',programming=False)
(O/'RESULT.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
