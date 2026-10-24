"""Measure only the fallback path identified by the completed V6 synthesis."""
from pathlib import Path
import html,json,re,subprocess,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/key_fallback'
def function(s,name):
 a=s.index(' function automatic [15:0] '+name+'(');b=s.index('endfunction',a)+len('endfunction');return s[a:b]
results={}
for tag,filename in [('original','before_visual_labels.sv'),('candidate','candidate_visual_labels.sv')]:
 s=(A/filename).read_text();O=A/('synthesis_'+tag);O.mkdir(exist_ok=True)
 source='''module probe(input clk,input [4:0] key,input [5:0] pos,output reg [15:0] character);
 (* syn_preserve=1 *) reg [4:0] key_q;
 (* syn_preserve=1 *) reg [5:0] pos_q;
 wire c_mapping_valid=1'b0;wire [6:0] char_key_note=7'd0;
'''+''.join(function(s,n)+'\n' for n in ['decimal','note_char','key_char'])+'''
 always @(posedge clk)begin key_q<=key;pos_q<=pos;character<=key_char(key_q,pos_q);end
endmodule
'''
 (O/'probe.sv').write_text(source)
 p=E.Element('Project');E.SubElement(p,'Template').text='FPGA';E.SubElement(p,'Version').text='5'
 E.SubElement(p,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
 E.SubElement(E.SubElement(p,'FileList'),'File',path='probe.sv',type='file.verilog',enable='1')
 (O/'probe.gprj').write_bytes(E.tostring(p,encoding='utf-8',xml_declaration=True))
 (O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module probe\nrun syn\nexit\n')
 with (O/'console.log').open('w') as f:
  result=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=120)
 log=(O/'console.log').read_text(errors='replace');assert result.returncode==0 and 'GowinSynthesis finish' in log and not re.search('^ERROR',log,re.M),log[-1500:]
 t=html.unescape(re.sub('<[^>]+>',' ',(O/'impl/gwsynthesis/probe_syn.rpt.html').read_text()));t=re.sub(r'\s+',' ',t)
 a=t.index('Max Frequency Summary:');b=t.index('Detail Timing Paths Information',a)
 first=t.index('Path Summary:')
 results[tag]=dict(frequency_summary=t[a:b],first_path=t[first:first+700],resources=E.parse(O/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib)
out=dict(status='MEASURED_ISOLATED_PATH_ONLY_NOT_APPLIED',results=results,scope='Registered key/position to fallback character only, no mapped MIDI branch or whole-design timing claim.',programming=False)
(A/'SYNTHESIS.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
