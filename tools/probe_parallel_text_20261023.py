"""Measure original/candidate whole labels; does not edit production source."""
from pathlib import Path
import html,json,re,shutil,subprocess,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/parallel_text';results={}
for tag,filename in [('original','before_visual_labels.sv'),('candidate','candidate_visual_labels.sv')]:
 O=A/('synthesis_'+tag);O.mkdir(exist_ok=True);s=(A/filename).read_text();(O/'labels.sv').write_text(s)
 for n in re.findall(r'\$readmemh\("([^"]+)"',s):
  out=O/n;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/n,out)
 project=E.Element('Project');E.SubElement(project,'Template').text='FPGA';E.SubElement(project,'Version').text='5'
 E.SubElement(project,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
 E.SubElement(E.SubElement(project,'FileList'),'File',path='labels.sv',type='file.verilog',enable='1')
 (O/'probe.gprj').write_bytes(E.tostring(project,encoding='utf-8',xml_declaration=True))
 (O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module visual_labels\nrun syn\nexit\n')
 with (O/'console.log').open('w') as f:
  p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=180)
 log=(O/'console.log').read_text(errors='replace');assert p.returncode==0 and 'GowinSynthesis finish' in log and not re.search('^ERROR',log,re.M),log[-1500:]
 t=html.unescape(re.sub('<[^>]+>',' ',(O/'impl/gwsynthesis/probe_syn.rpt.html').read_text()));t=re.sub(r'\s+',' ',t)
 a=t.index('Max Frequency Summary:');b=t.index('Detail Timing Paths Information',a);first=t.index('Path Summary:')
 results[tag]=dict(frequency_summary=t[a:b],first_path=t[first:first+700],resources=E.parse(O/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib)
r=dict(status='MEASURED_ISOLATED_LABELS_ONLY_NOT_APPLIED',results=results,scope='Same font assets, registers,ports and21cycles; no whole-design STA claim.',programming=False)
(A/'SYNTHESIS.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
