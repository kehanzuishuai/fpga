from pathlib import Path
import re,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
s=(R/'impl/gwsynthesis/yinyue_fashengqi.vg').read_text()
actual=re.search(r'^module visual_xy_source\s*\([\s\S]*?^endmodule[^\n]*',s,re.M)[0].replace('module visual_xy_source','module post_xy_source')
tested=(O/'post_xy_source.v').read_text();assert len(re.findall(r'^module ',tested,re.M))==1
assert actual==tested,'The tested gate component changed; repeat simulation'
print('PASS exact full gate FIR text identical after physical clock rebuild:',hashlib.sha256(actual.encode()).hexdigest())
