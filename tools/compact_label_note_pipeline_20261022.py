"""Retain only the selected key note through the long text metadata pipeline."""
from pathlib import Path
import hashlib,json,sys

R=Path(__file__).resolve().parents[1]
p=R/'src/display/visual_labels.sv'
A=R/'audit/autonomous_timing_20261022_154006/changes/label_note_pipeline'
A.mkdir(parents=True,exist_ok=True)
if not (A/'before_visual_labels.sv').exists():
    (A/'before_visual_labels.sv').write_bytes(p.read_bytes())
s=p.read_text()
if 'key_note_pipe[0]<=pick_key_note(status_pipe[1],attr_pipe[0][32:28]);' in s:
    print('Selected-note pipeline already compacted; no source rewrite')
    sys.exit(0)
assert s.count('char_key_note<=pick_key_note(status_pipe[15],attr_pipe[14][32:28]);')==1
s=s.replace(' reg [6:0] char_key_note;', ''' // Select after the first registered region/attribute stages, then carry7 bits.
 // Pixel t0: status_pipe[1] and attr_pipe[0] align at t2; pipe[13] at t15;
 // char_key_note captures it at t16, exactly the original lookup cycle.
 reg [6:0] char_key_note,key_note_pipe[0:13];integer note_stage;
 always @(posedge clk)begin
  key_note_pipe[0]<=pick_key_note(status_pipe[1],attr_pipe[0][32:28]);
  for(note_stage=1;note_stage<14;note_stage=note_stage+1)
   key_note_pipe[note_stage]<=key_note_pipe[note_stage-1];
 end''')
s=s.replace('status_pipe[meta_i]<=status_pipe[meta_i-1];control_pipe[meta_i]<=control_pipe[meta_i-1];',
'''if(meta_i<2)status_pipe[meta_i]<=status_pipe[meta_i-1];
   else status_pipe[meta_i]<={status_pipe[meta_i-1][511:306],224'b0,status_pipe[meta_i-1][81:0]};
   control_pipe[meta_i]<=control_pipe[meta_i-1];''')
s=s.replace('char_key_note<=pick_key_note(status_pipe[15],attr_pipe[14][32:28]);','char_key_note<=key_note_pipe[13];')
p.write_text(s)
h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
(A/'CHANGE.json').write_text(json.dumps(dict(scope='Exact cycle retiming of key-note selection only. Original21-cycle text latency and all geometry/color/glyph logic retained. Mapping bits82..305 discarded only after their sole lookup consumer.',
 before=h(A/'before_visual_labels.sv'),after=h(p),mapping_bit_cycles_removed=3038,programming=False),indent=2))
print('Prepared selected-note pipeline; requires labels equivalence and new synthesis/PnR')
