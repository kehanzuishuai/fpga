from pathlib import Path
import json,csv
from continue_audio_audit import R,O,A,sha,now
build=json.loads((A/'BUILD.json').read_text());assert build['status']=='PASS','final implementation must pass'
assert sha(Path(build['fs']))==build['sha256']
outputs=[R/p for p in ['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html','impl/gwsynthesis/RTL_GAO/gw_gao_top.v']]
outputs += [p for p in O.rglob('*') if p.is_file() and p.suffix in ['.wav','.npy','.csv','.png','.svg']]
outputs += [p for p in (R/'docs').glob('*') if p.is_file()]
records=[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size} for p in outputs]
(A/'OUTPUT_HASHES.json').write_text(json.dumps({'time':now(),'files':records},indent=2),encoding='utf8')
print('Indexed',len(records),'deliverable/report/data outputs')
