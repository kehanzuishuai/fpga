"""PnR-only regional-reset placement repair, guarded by actual failed report."""
from pathlib import Path
import json,hashlib,shutil,re
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022';S=R/'audit/autonomous_timing_20261022_154006/runs/followup_packed_ks_key_lip_p3_r0';D=A/'reset_region';D.mkdir(exist_ok=True)
r=json.loads((S/'RESULT.json').read_text());assert r['status']=='IMPLEMENTATION_FAILED' and any('PR0004' in x for x in r['errors'])
report=(S/'impl/pnr/yinyue_fashengqi.rpt.txt').read_text(errors='replace');m=re.search(r'^\s*u_video_io/reset_regional\s*\|[^|]+\|([^\n]+)',report,re.M);assert m and 'PTR1' in m[1] and 'PTR3' in m[1]
probe=A/'clock_gao_reset_cluster_probe';assert json.loads((probe/'RESULT.json').read_text())['returncode']==0
slacks=json.loads((probe/'STA_SCOPE.json').read_text())['worst_slack_ns'];assert len(slacks)==5 and all(x is not None and x>=0 for x in slacks.values())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(R/'src/display/visual_dvi_io.v')==sha(S/'src/display/visual_dvi_io.v')
cst=R/'src/integrated.cst';before=cst.read_text();assert sha(cst)==r['inputs']['src/integrated.cst']
shutil.copy2(cst,D/'integrated.before.cst')
addition='''
// Keep the first two reset release stages in the same PTR3 region as the
// three serializer reset registers above; no new timing exceptions.
INS_LOC "u_video_io/reset_release_0_s1" R34C181[0][B];
INS_LOC "u_video_io/reset_release_1_s1" R36C181[0][B];
'''
assert all(line in (probe/'probe.cst').read_text() for line in addition.splitlines() if line.startswith('INS_LOC'))
cst.write_text(before+addition)
rec=dict(status='APPLIED_PNR_ONLY_NOT_YET_MAIN_VERIFIED',before_sha256=r['inputs']['src/integrated.cst'],after_sha256=sha(cst),failed_main_errors=r['errors'],failed_main_reset_regions=m[1].strip(),diagnostic_worst_slack_ns=slacks,
    scope='Only two INS_LOC FF positions added; no HDL, clock frequency/phase, IO pin, SDC or feature changed. Hypothesis remains to be checked in full design.',programming=False)
(D/'CHANGE.json').write_text(json.dumps(rec,indent=2));print(json.dumps(rec,indent=2))
