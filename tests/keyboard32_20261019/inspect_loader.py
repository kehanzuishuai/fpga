from pathlib import Path
import re,difflib
R=Path(__file__).resolve().parents[2]
paths=[R/'impl/gwsynthesis/yinyue_fashengqi.vg',R/'audit/keyboard32_20261019/backup/impl/gwsynthesis/yinyue_fashengqi.vg']
bodies=[]
for p in paths:
 s=p.read_text(errors='replace')
 b=re.search(r'^module piano_note_loader\s*\([\s\S]*?^endmodule',s,re.M).group()
 bodies.append(b)
 print(p,'bytes',len(b))
 print('\n'.join(b.splitlines()[:75]))
print('EXACT_MODULE_EQUAL',bodies[0]==bodies[1])
if bodies[0]!=bodies[1]:
 print(''.join(list(difflib.unified_diff(bodies[1].splitlines(True),bodies[0].splitlines(True)))[:150]))
