"""Check explicit placement of all five HDMI reset flops in the DCS region."""
from pathlib import Path
import json,shutil,subprocess,hashlib,xml.etree.ElementTree as ET,re
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022';S=A/'clock_gao_scalar_probe';D=A/'clock_gao_reset_cluster_probe';D.mkdir(exist_ok=False)
assert json.loads((S/'RESULT.json').read_text())['returncode']==0
for n in ['src','impl/gwsynthesis']:shutil.copytree(S/n,D/n)
for n in ['top.v','probe.gprj','probe.cst','probe.sdc','probe.rao']:shutil.copy2(S/n,D/n)
t=ET.parse(S/'probe.gprj.user')
for e in t.findall('./FlowState/Process'):
    if e.get('ID')=='Pnr':e.set('State','0')
t.write(D/'probe.gprj.user',encoding='utf-8',xml_declaration=True)
cst=(D/'probe.cst').read_text()+'''\n// Keep all five regional-clock reset flops near the serializer IOs.
INS_LOC "u_video_io/reset_release_0_s1" R34C181[0][B];
INS_LOC "u_video_io/reset_release_1_s1" R36C181[0][B];
''';(D/'probe.cst').write_text(cst)
(D/'run.tcl').write_text(f'''cd {{{D.as_posix()}}}
open_project probe.gprj
set_option -verilog_std sysv2017
set_option -top_module tang_mega_138k_pro_top
set_option -convert_sdp32_36_to_sdp16_18 0
set_option -timing_driven 1
set_option -correct_hold_violation 1
set_option -place_option 3
set_option -route_option 0
set_option -cst_warn_to_error 1
set_option -gen_text_timing_rpt 1
run pnr
exit
''')
with (D/'console.log').open('w') as f:p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(D/'run.tcl')],cwd=D,stdout=f,stderr=subprocess.STDOUT)
log=(D/'console.log').read_text(errors='replace');errors=re.findall(r'^ERROR.*',log,re.M)
rec=dict(status='COMPLETED_DIAGNOSTIC_ONLY' if p.returncode==0 and not errors else 'FAILED_DIAGNOSTIC',returncode=p.returncode,errors=errors,programming=False,
    scope='Legality/timing of two additional reset FF placement constraints at real IO locations, synthetic clock+GAO data only; not a main implementation result.',cst_sha256=hashlib.sha256((D/'probe.cst').read_bytes()).hexdigest())
(D/'RESULT.json').write_text(json.dumps(rec,indent=2));print(json.dumps(rec,indent=2))
