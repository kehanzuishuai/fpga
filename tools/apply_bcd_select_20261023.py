from pathlib import Path
import json,hashlib,shutil
from display_bcd_select_20261023 import select_bcd
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/bcd_select';A.mkdir(exist_ok=True)
p=R/'src/display/visual_labels.sv';b=A/'before_visual_labels.sv';assert not b.exists();shutil.copy2(p,b)
s=p.read_text();new=select_bcd(s);assert s!=new;p.write_text(new)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
(A/'CHANGE.json').write_text(json.dumps(dict(status='APPLIED_PENDING_EQUIVALENCE',before_sha256=sha(b),source_sha256=sha(p),
 scope='Decimal place always0..4; use3-bit place and explicit5-way nibble/leading-zero selects instead of32-bit variable shift arithmetic. Same ASCII for all20-bit BCD patterns, same21-cycle labels.',
 critical_path='V3 synthesis attr_char.pos[0] -> labels.ch[0],15logic levels14.138ns',programming=False),indent=2))
print('Applied exact bounded BCD digit selection; algebra and pixel checks required.')
