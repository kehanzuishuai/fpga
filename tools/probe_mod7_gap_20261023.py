"""Exhaustive12-bit equivalence and small registered-path mapping comparison."""
from pathlib import Path
import hashlib,html,json,re,subprocess,xml.etree.ElementTree as E
from display_mod7_gap_20261023 import gap_module,shorten_mod7
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/mod7_gap';A.mkdir(exist_ok=True)
source=R/'src/display/visual_renderer.sv';before=source.read_text();(A/'candidate_visual_renderer.sv').write_text(shorten_mod7(before));(A/'helper.sv').write_text(gap_module())
(A/'tb.sv').write_text('''module tb;reg[11:0] value=0;wire gap;integer i;
visual_mod7_gap dut(value,gap);initial begin for(i=0;i<4096;i=i+1)begin value=12'(i);#1;
if(gap!==(value%12'd7==12'd6))$fatal(1,"mod7 mismatch %0d",i);end
$display("PASS all4096 12bit modulo7 separator values");$finish;end endmodule
''')
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('compile',[iv,'-g2012','-s','tb','-o',A/'test.vvp',A/'helper.sv',A/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),A/'test.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=120);(A/(name+'.log')).write_text(p.stdout+p.stderr)
 assert p.returncode==0,(p.stdout+p.stderr)[-2000:]
 print(p.stdout[-800:],flush=True)
results={}
for tag in ['original','candidate']:
 O=A/tag;O.mkdir(exist_ok=True)
 logic="assign next_gap=q%12'd7==12'd6;" if tag=='original' else 'visual_mod7_gap test(q,next_gap);'
 s='''module probe(input clk,input[11:0]x,output reg gap);
 (* syn_preserve=1 *) reg[11:0] q;wire next_gap;
'''+logic+'\nalways @(posedge clk)begin q<=x;gap<=next_gap;end\nendmodule\n'+gap_module()
 (O/'probe.sv').write_text(s);project=E.Element('Project');E.SubElement(project,'Template').text='FPGA';E.SubElement(project,'Version').text='5'
 E.SubElement(project,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
 E.SubElement(E.SubElement(project,'FileList'),'File',path='probe.sv',type='file.verilog',enable='1');(O/'probe.gprj').write_bytes(E.tostring(project,encoding='utf-8',xml_declaration=True))
 (O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module probe\nrun syn\nexit\n')
 with (O/'console.log').open('w') as f:p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=120)
 log=(O/'console.log').read_text(errors='replace');assert p.returncode==0 and 'GowinSynthesis finish' in log and not re.search('^ERROR',log,re.M),log[-1500:]
 t=html.unescape(re.sub('<[^>]+>',' ',(O/'impl/gwsynthesis/probe_syn.rpt.html').read_text()));t=re.sub(r'\s+',' ',t);a=t.index('Max Frequency Summary:');b=t.index('Detail Timing Paths Information',a);first=t.index('Path Summary:')
 results[tag]=dict(frequency_summary=t[a:b],first_path=t[first:first+800],resources=E.parse(O/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib)
assert source.read_text()==before
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=dict(status='PASS_EXACT_OPERATOR_ISOLATED_NOT_APPLIED',cases=4096,results=results,before_sha256=sha(source),candidate_sha256=sha(A/'candidate_visual_renderer.sv'),scope='Only modulo7 predicate replaced by exact combinational four-digit sum. Original register/always structure unchanged; no whole-design STA claim.',programming=False)
(A/'RESULT.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
