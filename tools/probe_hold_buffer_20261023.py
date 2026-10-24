"""Check whether explicit identity LUTs survive the actual vendor mapper."""
from pathlib import Path
import hashlib,json,re,subprocess,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1];O=R/'audit/routing_followup_20261022/hold_buffer_probe';O.mkdir(exist_ok=True)
s='''module probe(input clk,input d,output reg q);
 (* syn_preserve=1 *) reg launch;
 (* syn_keep=1 *) wire pad0,pad1;
 (* syn_keep=1 *) LUT1 #(.INIT(2'b10)) buffer0(.I0(launch),.F(pad0));
 (* syn_keep=1 *) LUT1 #(.INIT(2'b10)) buffer1(.I0(pad0),.F(pad1));
 always @(posedge clk)begin launch<=d;q<=pad1;end
endmodule
''';(O/'probe.v').write_text(s)
p=E.Element('Project');E.SubElement(p,'Template').text='FPGA';E.SubElement(p,'Version').text='5';E.SubElement(p,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
E.SubElement(E.SubElement(p,'FileList'),'File',path='probe.v',type='file.verilog',enable='1');(O/'probe.gprj').write_bytes(E.tostring(p,encoding='utf-8',xml_declaration=True));(O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -top_module probe\nrun syn\nexit\n')
with (O/'console.log').open('w') as f:p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=120)
log=(O/'console.log').read_text(errors='replace');assert p.returncode==0 and 'GowinSynthesis finish' in log and not re.search('^ERROR',log,re.M),log[-1500:]
vg=O/'impl/gwsynthesis/probe.vg';text=vg.read_text();cells=re.findall(r'^\s*LUT1\s+(\S+)\s+\(',text,re.M)
r=dict(status='IDENTITY_PADDING_RETAINED' if len(cells)==2 else 'IDENTITY_PADDING_NOT_RETAINED_DO_NOT_USE',lut1_cells=cells,resources=E.parse(O/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib,netlist_sha256=hashlib.sha256(vg.read_bytes()).hexdigest(),scope='Isolated mapper capability only, no source edit or actual routed hold improvement claim.',programming=False)
(O/'RESULT.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
