"""Isolate production clock/GAO topology at actual pins, using synthetic probes."""
from pathlib import Path
import re,json,shutil,subprocess,xml.etree.ElementTree as ET,datetime,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022'
S=R/'audit/autonomous_timing_20261022_154006/clock_topology_p16_verified';D=A/'clock_gao_scalar_probe';D.mkdir(exist_ok=False)
shutil.copytree(S/'src',D/'src')
for n in ['probe.gprj','probe.cst']:shutil.copy2(S/n,D/n)
rao=ET.parse(R/'src/keyboard_debug.rao');capture=rao.getroot().find('./AoCore/SignalList')
widths={}
for e in capture:
    name=e.get('name') if e.tag=='Bus' else e.text
    m=re.fullmatch(r'([^\[]+)(?:\[(\d+):(\d+)\])?',name)
    assert m,name
    widths[m[1]]=max(widths.get(m[1],1),int(m[2])+1 if m[2] else 1)
s=(S/'top.v').read_text().replace('clock_topology_probe','tang_mega_138k_pro_top',1)
s=re.sub(r'\baudio\b','clk_12m288',s)
s=s.replace('reg[23:0] ac;','wire[23:0] ac;wire diagnostic_tick;')
s=re.sub(r'always @\(posedge clk_12m288 or negedge rst_n\)if\(!rst_n\)ac<=0;else ac<=ac\+1\'b1;', '',s)
extra='''
 reg[1023:0] activity;
 always @(posedge clk_12m288 or negedge rst_n)if(!rst_n)activity<=1024'd1;
 else activity<={activity[1022:0],activity[1023]^activity[1022]^activity[1000]^activity[999]};
'''
offset=0
for name,width in widths.items():
    if '/' in name:continue
    assert not re.search(r'\b'+re.escape(name)+r'\b',s),name
    shape=f'[{width-1}:0]' if width>1 else ''
    extra+=f' (* syn_keep=1,syn_preserve=1 *) reg{shape} {name};\n always @(posedge clk_12m288 or negedge rst_n)if(!rst_n){name}<=0;else {name}<=activity[{offset}+:{width}];\n';offset+=width
assert offset<1024
extra+=' probe_synth_observation u_synth_top(clk_12m288,rst_n,ac,diagnostic_tick);\n'
s=s.replace('endmodule',extra+'endmodule',1)
s+='''
module probe_synth_observation(input clk,rst_n,output reg[23:0] audio_out,output wire sample_tick);
 assign sample_tick=&audio_out[7:0];
 always @(posedge clk or negedge rst_n)if(!rst_n)audio_out<=0;else audio_out<=audio_out+1'b1;
endmodule
'''
(D/'top.v').write_text(s)
rao.write(D/'probe.rao',encoding='utf-8',xml_declaration=True)
proj=ET.parse(D/'probe.gprj');files=proj.getroot().find('FileList')
ET.SubElement(files,'File',path='probe.rao',type='file.gao',enable='1');proj.write(D/'probe.gprj',encoding='utf-8',xml_declaration=True)
sdc=(R/'src/integrated.sdc').read_text();sdc='\n'.join(l for l in sdc.splitlines() if 'pll_lock_sync_0_s0' not in l)+'\n';(D/'probe.sdc').write_text(sdc)
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
run all
exit
''')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rec=dict(status='RUNNING',started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),scope='Diagnostic only: production PLL/DCS/HDMI/JTAG/GAO configuration and pin constraints; synthetic counters replace real probe sources. Never production source, image or timing approval.',programming=False,
         inputs={p.relative_to(D).as_posix():sha(p) for p in D.rglob('*') if p.is_file()})
(D/'RESULT.json').write_text(json.dumps(rec,indent=2))
with (D/'console.log').open('w') as f:
    p=subprocess.Popen(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(D/'run.tcl')],cwd=D,stdout=f,stderr=subprocess.STDOUT)
    rec['pid']=p.pid;(D/'RESULT.json').write_text(json.dumps(rec,indent=2));code=p.wait()
log=(D/'console.log').read_text(errors='replace');errors=re.findall(r'^ERROR.*',log,re.M)
rec.update(status='COMPLETED_DIAGNOSTIC_ONLY' if code==0 and not errors else 'FAILED_DIAGNOSTIC',returncode=code,errors=errors,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
(D/'RESULT.json').write_text(json.dumps(rec,indent=2));print(json.dumps({k:rec[k] for k in ['status','returncode','errors']},indent=2),flush=True)
