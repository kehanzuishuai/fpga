"""Record final source/output identity; no synthesis, simulation or programming."""
from pathlib import Path
import hashlib,json,re,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1]
A=R/'audit/autonomous_timing_20261022_154006'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
f=json.loads((A/'FINAL.json').read_text())
D=A/'runs'/f['selected']
enabled=[e.get('path') for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
assert len(enabled)==96
assert all(sha(R/n)==f['source_sha256'][n]==sha(D/n) for n in enabled)
assert sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')==f['netlist_sha256']
assert all(sha(R/'impl/pnr'/n)==h for n,h in f['pnr_sha256'].items())
assert not (R/'impl/pnr/ao_0.fs').exists()
assert not (R/'impl/pnr/yinyue_fashengqi.tr').exists()
assert sha(R/'release/latest/ao_0.fs')==f['old_release_unchanged_sha256']
ui=R/'firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/web_page.h'
assert sha(ui)=='3969c34b4d279eae7e16e1066441730b026b021e04ecf8e4ed52bece4bc719c1'
initial=json.loads((A/'runs/clock_first_p3_r2/RESULT.json').read_text())
changed=[n for n in enabled if n in initial['inputs'] and sha(R/n)!=initial['inputs'][n]]
assert set(changed)=={'src/tang_mega_138k_pro_top.v.v','src/gowin_pll/audio_pll.v','src/gowin_pll/audio_pll_mod.v','src/integrated.cst','src/integrated.sdc'}
probe=A/'clock_topology_probe'
t=(probe/'impl/pnr/probe.tr').read_text(errors='replace')
slacks={}
sections=['3.1.1 Setup Paths Table','3.1.2 Hold Paths Table','3.1.3 Recovery Paths Table','3.1.4 Removal Paths Table','3.2 Minimum Pulse Width Table']
for name in sections:
    start=t.index('\n'+name)
    m=re.search(r'^\s*1\s+(-?[\d.]+)\s',t[start:],re.M)
    slacks[name]=float(m[1]) if m else None
endpoints={k:int(re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',t)[1]) for k in ['Setup','Hold']}
result=dict(status='PASS_FINAL_SOURCE_OUTPUT_IDENTITY_ONLY',engineering_status=f['status'],enabled_input_count=len(enabled),changed_inputs_from_start=changed,
    selected=f['selected'],ui_sha256=sha(ui),programming=False,root_has_new_fs=False,root_has_complete_sta=False,
    diagnostic_only=dict(scope='Small clock/HDMI topology; not main FPGA project',report_sha256=sha(probe/'impl/pnr/probe.tr'),worst_slack_ns=slacks,violated_endpoints=endpoints))
(A/'FINAL_VERIFICATION.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
