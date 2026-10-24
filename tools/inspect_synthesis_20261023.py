"""Inspect completed vendor synthesis without claiming routed timing closure."""
from pathlib import Path
import argparse,hashlib,html,json,re,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('tag');o=p.parse_args();assert re.fullmatch('[a-z0-9_]+',o.tag)
D=R/'audit/autonomous_timing_20261022_154006/runs'/o.tag
record=json.loads((D/'RESULT.json').read_text());log=(D/'console.log').read_text(errors='replace')
assert 'GowinSynthesis finish' in log
assert not re.findall(r'^ERROR.*',log.split('GowinSynthesis finish',1)[0],re.M)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for n,h in record['inputs'].items():
 if n.startswith(('src/','assets/')) or n=='yinyue_fashengqi.gprj':assert sha(D/n)==h,n
report=D/'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html'
t=html.unescape(re.sub('<[^>]+>',' ',report.read_text()))
t=re.sub(r'\s+',' ',t)
def section(start,end):
 a=t.index(start);return t[a:t.index(end,a)]
summary=section('Max Frequency Summary:','Detail Timing Paths Information')
first=re.search(r'Path Summary:.*?Launch Clk.*?Latch Clk.*?(?=Path Details|Data Arrival|Launch Clock Path|Data Path|Path Detail)',t)
first_text=first[0][:1000] if first else t[t.index('Path Summary:'):t.index('Path Summary:')+800]
out=dict(status='SYNTHESIS_PASSED_ROUTED_TIMING_UNCONFIRMED',resources=ET.parse(D/'impl/gwsynthesis/yinyue_fashengqi_syn_rsc.xml').getroot().attrib,
 frequency_summary=summary,first_path=first_text,netlist_sha256=sha(D/'impl/gwsynthesis/yinyue_fashengqi.vg'),report_sha256=sha(report),programming=False)
(D/'SYNTHESIS_CHECK.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
