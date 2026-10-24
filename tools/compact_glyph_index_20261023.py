from pathlib import Path
import json,hashlib,shutil
from display_glyph_index_20261023 import index_labels
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/glyph_index';r=json.loads((A/'CHANGE.json').read_text())
p=R/'src/display/visual_labels.sv';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();assert sha(p)==r['source_sha256'],'Prototype edited externally'
shutil.copy2(p,A/'visual_labels.wide_prototype.sv');shutil.copy2(R/'assets/display_glyph_index.hex',A/'glyph_index.wide_prototype.hex')
profile=dict(entries=r['entries'],masks=r['masks']);(R/'tools/display_glyph_index_profile_20261023.json').write_text(json.dumps(profile,indent=2))
s=index_labels((A/'visual_labels.before.sv').read_text(),R);p.write_text(s)
r.update(source_sha256=sha(p),asset_sha256=sha(R/'assets/display_glyph_index.hex'),descriptor_asset_sha256=sha(R/'assets/display_glyph_descriptors.hex'),
         layout='4096x8 synchronous sparse index plus256x41 combinational descriptor; full24-bit identity check, existing21-clock latency',status='APPLIED_PENDING_EQUIVALENCE_AND_SYNTHESIS')
(A/'CHANGE.json').write_text(json.dumps(r,indent=2));print(json.dumps({k:r[k] for k in ['status','layout','source_sha256']},indent=2))
