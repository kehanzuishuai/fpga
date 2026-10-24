from pathlib import Path
import hashlib,json,shutil
from display_texture_address_20261023 import retime_texture_address
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/texture_address';A.mkdir(exist_ok=True)
p=R/'src/display/visual_background.sv';b=A/'before_visual_background.sv';assert not b.exists();shutil.copy2(p,b)
s=p.read_text();new=retime_texture_address(s);assert new!=s;p.write_text(new)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
(A/'CHANGE.json').write_text(json.dumps(dict(status='APPLIED_PENDING_EQUIVALENCE',before_sha256=sha(b),source_sha256=sha(p),
 scope='Exact quotient/remainder decomposition of row*BW+column in existing address clocks0/1. Native pixel data and6-clock background latency unchanged. REGISTER_ADDR modes0/1 public behavior retained; internal mode2 receives encoded word/remainder.',
 critical_path='Actual V3 routed raster.y -> sharp texture address multiplier AREG: setup-2.752ns,15.504ns data delay',programming=False),indent=2))
print('Applied exact background row/column address split; native-ROM/pixel checks required.')
