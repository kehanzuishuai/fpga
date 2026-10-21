from pathlib import Path
import json,hashlib
from continue_audio_audit import R,A,O,run,PY
source=O/'key_pcm.csv';lines=[s for s in source.open() if s.startswith('0,')]
d=A/'capture_window_attempt1/raw0_samples.csv';d.write_text(''.join(lines))
result={'source_snapshot':str(A/'capture_window_attempt1/tb_audio_note_map.sv'),'sample_file':str(d),'sample_sha256':hashlib.sha256(d.read_bytes()).hexdigest(),'observed_samples':len(lines),'expected_samples':4096,'status':'FAIL','reason':'Observation disabled before final DAC capture; main DUT handshake/serial assertions separate'}
(A/'capture_window_attempt1/RESULT.json').write_text(json.dumps(result,indent=2),encoding='utf8')
run('capture_window_attempt1_check',[PY,'-B','-c',"from pathlib import Path; n=sum(1 for _ in Path('audit/continuation_20261017/capture_window_attempt1/raw0_samples.csv').open()); print('observed',n,'expected',4096); assert n==4096"])
