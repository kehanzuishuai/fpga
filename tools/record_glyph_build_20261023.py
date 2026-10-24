"""Freeze focused evidence and current-source manifest for the glyph revision."""
from pathlib import Path
import datetime,hashlib,json,re,shutil,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
old=A/'PACKED_READY.json';backup=A/'PACKED_READY_balanced_arithmetic_v2.json'
assert not backup.exists();shutil.copy2(old,backup)
d=json.loads(old.read_text())
proofdir=A/'glyph_index';shutil.copy2(R/'tests/display_integration_20261021/out/LABELS_EQUIVALENCE.json',proofdir/'LABELS_EQUIVALENCE.json')
resource=R/'tests/display_integration_20261021/resource/glyph_index_20261023'
assert 'GowinSynthesis finish' in (resource/'probe.log').read_text()
assert sha(resource/'visual_labels.sv')==sha(R/'src/display/visual_labels.sv')
resources=ET.parse(resource/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib
assert resources['T_Bsram']=='16(14)'
html=(resource/'impl/gwsynthesis/probe_syn.rpt.html').read_text()
assert '105.848(MHz)' in html
receipt=dict(status='PASS_SYNTHESIS_ONLY',resources=resources,estimated_fmax_mhz=105.848,
 source_sha256=sha(R/'src/display/visual_labels.sv'),report_sha256=sha(resource/'impl/gwsynthesis/probe_syn.rpt.html'),
 scope='Isolated label module synthesis; not full-design timing closure.',programming=False)
(proofdir/'SYNTHESIS.json').write_text(json.dumps(receipt,indent=2))
for n in ['glyph_index/verification/RESULT.json','glyph_index/LABELS_EQUIVALENCE.json']:
 assert json.loads((A/n).read_text())['status']=='PASS'
for n in ['glyph_index/verification/RESULT.json','glyph_index/LABELS_EQUIVALENCE.json','glyph_index/SYNTHESIS.json','reset_region/CHANGE.json']:
 d['proof_sha256'][n]=sha(A/n)
d.update(recorded_utc=now(),candidate='audit/autonomous_timing_20261022_154006/runs/followup_glyph_cluster_p3_r0',
 status='FOCUSED_EQUIVALENCE_PASS_FULL_BUILD_RUNNING')
d['current_enabled_sha256']={n:sha(R/n) for n in d['current_enabled_sha256']}
d['changed_enabled_inputs']+=['src/display/visual_labels.sv','src/integrated.cst']
d['current_asset_sha256']={str(p.relative_to(R)).replace('\\','/'):sha(p) for p in (R/'assets').glob('*') if p.is_file()}
d['scope']+=' Glyph lookup uses collision-checked sparse index and dense descriptor, same21 clocks, original font pixels; two reset FF locations constrained with same logical behavior.'
old.write_text(json.dumps(d,indent=2))
runroot=R/'audit/autonomous_timing_20261022_154006/runs'
stopped=runroot/'followup_packed_balanced_p3_r0/RESULT.json'
s=json.loads(stopped.read_text());assert s['returncode']!=0 and not s['errors']
s.update(status='STOPPED_AFTER_SYNTHESIS_FOR_GLYPH_AND_CST_REVISION',stop_reason='Synthesis completed; first reported critical path became glyph CAM. Stopped early PnR to validate and build exact glyph-index replacement. Not a completed tool failure.')
stopped.write_text(json.dumps(s,indent=2))
live=dict(updated_utc=now(),goal='Resolve whole design routing and STA; preserve all features/UI; no programming',
 runs=[dict(tag='followup_glyph_cluster_p3_r0',session=8442,status='RUNNING',root_source_matches=True),
       dict(tag='followup_packed_reset_cluster_inc',status='IMPLEMENTATION_FAILED',unrouted_nets=420,regional_reset='PTR3',scope='Prior V1 netlist CST-only control'),
       dict(tag='followup_packed_ks_key_lip_p3_r0',status='IMPLEMENTATION_FAILED',unrouted_nets=357),
       dict(tag='followup_packed_balanced_p3_r0',status=s['status'],pixel_synthesis_fmax_mhz=64.190)],
 awake=dict(session=38113,pid=36792,expires_local='2026-10-23 10:01'),
 current_root='V3 source and two new glyph assets; root impl still pre-followup failed PLL version. Do not claim current implementation until coherent promotion.',
 proof_receipt='audit/routing_followup_20261022/PACKED_READY.json',programming=False,no_subagents=True)
(A/'LIVE.json').write_text(json.dumps(live,indent=2))
readme=R/'README.md';t=readme.read_text(encoding='utf-8')
t=re.sub(r'^> 后续修复进行中.*$', '> 后续修复进行中（2026-10-23）：当前源码已加入显示长路径等价改写、字形索引及吉他延迟线24位无损存储重排，必要等价检查通过，正在整机综合与布局布线。字形模块单独综合预估105.848MHz不代表整机通过。首个315块BSRAM版本仍有357条未布通；复位位置对照420条，未解决。`impl/`仍为上轮PLL候选，不是当前源码的通过证据。详见`audit/routing_followup_20261022/`，不烧录。',t,flags=re.M)
readme.write_text(t,encoding='utf-8')
with (A/'PROGRESS.md').open('a',encoding='utf-8') as f:
 f.write('\n\n## 2026-10-23 09:30 glyph revision\n\nV1 failed with357 unrouted nets; CST-only incremental reset control failed with420 despite reset regional clock now PTR3 only. Reset location was not a sufficient fix. V2 SYN completed64.190MHz pixel estimate; stopped early PnR after glyph CAM became critical. V3 glyph helper passed655360 key cases and labels2912 pixels/90regions with unchanged21-cycle latency. Focused label synthesis105.848MHz,16BSRAM total (2extra),3943LUT total. Full V3 new synthesis and fresh placement running as followup_glyph_cluster_p3_r0; root impl remains old failed version until promotion. No programming/UI or piano path changes.\n')
print(json.dumps(dict(status=d['status'],changed=d['changed_enabled_inputs'],glyph_module=receipt),indent=2))
