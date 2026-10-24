"""Apply one recorded exact retiming of the newest synthesis critical path."""
from pathlib import Path
import hashlib,json,shutil
from display_well_geometry_20261023 import retime_wells
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/well_geometry';A.mkdir(exist_ok=True)
p=R/'src/display/visual_scene.sv';before=A/'before_visual_scene.sv';assert not before.exists()
shutil.copy2(p,before);s=p.read_text();changed=retime_wells(s);assert changed!=s;p.write_text(changed)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
(A/'CHANGE.json').write_text(json.dumps(dict(status='APPLIED_PENDING_EQUIVALENCE',source_before_sha256=sha(before),source_sha256=sha(p),
 scope='Original rounded function split into existing round_geometry and round_finish at stages13 and14 for7 fixed wells and5 sound bars. Same40-cycle scene latency, pixels, style and function; no clock/IO/audio changes.',
 critical_path='V3 synthesis info_pipe[13].x -> scene/STAGE_14.q.well_hits[5],16levels,15.084ns',programming=False),indent=2))
print('Applied stage13/14 exact fixed-mask retiming; focused checks required.')
