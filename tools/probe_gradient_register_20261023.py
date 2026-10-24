"""Check preservation of the gradient position FF, without editing production RTL."""
from pathlib import Path
import hashlib,html,json,re,subprocess,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/gradient_register'
A.mkdir(exist_ok=True)
s=(R/'src/display/visual_renderer.sv').read_text()
position=s[s.index('  if(draw_x<666)'):s.index('  gradient_region2<=gradient_region1;')]
products=s[s.index('  case(gradient_region1)'):s.index('  grid2<=')]
results={}
for preserve in (False,True):
 O=A/('preserved' if preserve else 'original');O.mkdir(exist_ok=True)
 attribute='(* syn_preserve=1,syn_keep=1 *) ' if preserve else ''
 source='''module probe(input clk,input [11:0] x,
 output reg [16:0] r,g,b);
 (* syn_preserve=1 *) reg [11:0] draw_x;
 ATTRIBUTEreg [9:0] gradient_pos1;
 reg [1:0] gradient_region1;
 reg [16:0] gradient_r2,gradient_g2,gradient_b2;
 always @(posedge clk)begin
  draw_x<=x;
 POSITION
 PRODUCTS
  r<=gradient_r2;g<=gradient_g2;b<=gradient_b2;
 end
endmodule
'''.replace('ATTRIBUTE',attribute).replace('POSITION',position).replace('PRODUCTS',products)
 (O/'probe.sv').write_text(source)
 project=ET.Element('Project');ET.SubElement(project,'Template').text='FPGA';ET.SubElement(project,'Version').text='5'
 ET.SubElement(project,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
 files=ET.SubElement(project,'FileList');ET.SubElement(files,'File',path='probe.sv',type='file.verilog',enable='1')
 ET.SubElement(files,'File',path='probe.sdc',type='file.sdc',enable='1')
 (O/'probe.gprj').write_bytes(ET.tostring(project,encoding='utf-8',xml_declaration=True))
 (O/'probe.sdc').write_text('create_clock -name pixel -period 13.468013468 [get_ports {clk}]\n')
 (O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module probe\nrun syn\nexit\n')
 with (O/'console.log').open('w') as f:
  p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=120)
 log=(O/'console.log').read_text(errors='replace');assert p.returncode==0 and 'GowinSynthesis finish' in log and not re.search(r'^ERROR',log,re.M),log[-1500:]
 report=O/'impl/gwsynthesis/probe_syn.rpt.html';t=html.unescape(re.sub('<[^>]+>',' ',report.read_text()));t=re.sub(r'\s+',' ',t)
 vg=(O/'impl/gwsynthesis/probe.vg').read_text()
 names=re.findall(r'^\s*DFF\w*\s+([^\n]*gradient_pos1[^\n]*)',vg,re.M)
 f=t[t.index('Max Frequency Summary:'):t.index('Detail Timing Paths Information')]
 first=t[t.index('Path Summary:'):t.index('Path Summary:')+1100]
 results[O.name]=dict(frequency_summary=f,first_path=first,position_ff_names=names,resources=ET.parse(O/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib,
 source_sha256=hashlib.sha256((O/'probe.sv').read_bytes()).hexdigest())
assert len(results['preserved']['position_ff_names'])==10,results['preserved']
result=dict(status='PASS_ISOLATED_MAPPING_PROBE_NOT_APPLIED',results=results,scope='Attributes only; exact production gradient expressions extracted. This isolated synthesis does not prove whole-design STA.',programming=False)
(A/'RESULT.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
