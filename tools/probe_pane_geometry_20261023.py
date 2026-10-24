"""Verify pane algebra and measure common-center preparation, without root edits."""
from pathlib import Path
import hashlib,html,json,re,subprocess,xml.etree.ElementTree as E
from display_pane_geometry_20261023 import prepared_function
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/pane_geometry'
source=R/'src/display/visual_scene.sv';s=source.read_text();a=s.index(' function automatic [12:0] round_geometry(');b=s.index('endfunction',a)+len('endfunction');functions=s[a:b]+'\n'+prepared_function()
st=s[s.index('begin:STAGE_0'):s.index('begin:STAGE_1')]
actual=sorted(set(int(v) for v in re.findall(r'd\.p[wh]=([^;]+)',st)))
dimensions=sorted(set(actual+[1,2,27,28,29,30,35,2047,4095]));cases=''.join(f'{i}:width={v};' for i,v in enumerate(dimensions))
tb='''module tb;
__FUNCTIONS__
integer cfg,j,i,width,offset,radius,count=0;reg signed[12:0] coordinate,rs,rl,bs,bl;reg[12:0] original,prepared;
initial begin
for(cfg=0;cfg<5;cfg=cfg+1)begin
case(cfg)0:offset=0;1:offset=-7;2:offset=-4;3:offset=-2;4:offset=1;endcase
radius=28-offset;
for(j=0;j<__N__;j=j+1)begin case(j)__CASES__ endcase
for(i=0;i<8192;i=i+1)begin
coordinate=13'(i);rs=13'(width)-13'sd28;rl=13'(width)-13'sd29;bs=13'd512-13'd28;bl=13'd512-13'd29;
original=round_geometry(coordinate,13'sd26,13'(offset),13'(offset),13'(width-2*offset),13'(512-2*offset),13'(radius));
prepared=round_pane_prepared(coordinate,13'sd26,13'(offset),13'(offset),13'(width-2*offset),13'(512-2*offset),rs,rl,bs,bl);
if(original!==prepared)$fatal(1,"paneX cfg%0d width%0d coord%0d %h %h",cfg,width,coordinate,original,prepared);
original=round_geometry(13'sd26,coordinate,13'(offset),13'(offset),13'(512-2*offset),13'(width-2*offset),13'(radius));
prepared=round_pane_prepared(13'sd26,coordinate,13'(offset),13'(offset),13'(512-2*offset),13'(width-2*offset),bs,bl,rs,rl);
if(original!==prepared)$fatal(1,"paneY cfg%0d width%0d coord%0d",cfg,width,coordinate);
count=count+2;
end end end
$display("PASS %0d exact pane axis geometries, all8192 signed coordinates, five borders, actualdimensions+boundarywidths",count);$finish;
end endmodule
'''.replace('__FUNCTIONS__',functions).replace('__N__',str(len(dimensions))).replace('__CASES__',cases)
(A/'algebra.sv').write_text(tb);iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('algebra_compile',[iv,'-g2012','-s','tb','-o',A/'algebra.vvp',A/'algebra.sv']),('algebra',[iv.with_name('vvp.exe'),A/'algebra.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=120);(A/(name+'.log')).write_text(p.stdout+p.stderr)
 assert p.returncode==0,(p.stdout+p.stderr)[-2000:]
 print(p.stdout[-900:],flush=True)
results={}
for tag in ['original','candidate']:
 O=A/('synthesis_'+tag);O.mkdir(exist_ok=True)
 declarations='reg signed[12:0] rs1,rl1,bs1,bl1;' if tag=='candidate' else ''
 captures="rs1<=$signed({1'b0,w0})-13'sd28;rl1<=$signed({1'b0,w0})-13'sd29;bs1<=13'sd484;bl1<=13'sd483;" if tag=='candidate' else ''
 expr="round_pane_prepared(x1,13'sd26,13'sd1,13'sd1,w1-2,13'sd510,rs1,rl1,bs1,bl1)" if tag=='candidate' else "round_geometry(x1,13'sd26,13'sd1,13'sd1,w1-2,13'sd510,13'sd27)"
 text='''module probe(input clk,input[11:0]width,input signed[12:0]x,output reg[12:0]geometry);
(* syn_preserve=1 *) reg[11:0]w0;reg[11:0]w1;
(* syn_preserve=1 *) reg signed[12:0]x0;reg signed[12:0]x1;
'''+declarations+'\n'+functions+'\nalways @(posedge clk)begin w0<=width;x0<=x;w1<=w0;x1<=x0;'+captures+'geometry<='+expr+';end\nendmodule\n'
 (O/'probe.sv').write_text(text);project=E.Element('Project');E.SubElement(project,'Template').text='FPGA';E.SubElement(project,'Version').text='5';E.SubElement(project,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003';E.SubElement(E.SubElement(project,'FileList'),'File',path='probe.sv',type='file.verilog',enable='1');(O/'probe.gprj').write_bytes(E.tostring(project,encoding='utf-8',xml_declaration=True));(O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module probe\nrun syn\nexit\n')
 with (O/'console.log').open('w') as f:p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=120)
 log=(O/'console.log').read_text(errors='replace');assert p.returncode==0 and 'GowinSynthesis finish' in log and not re.search('^ERROR',log,re.M),log[-1500:]
 t=html.unescape(re.sub('<[^>]+>',' ',(O/'impl/gwsynthesis/probe_syn.rpt.html').read_text()));t=re.sub(r'\s+',' ',t);a=t.index('Max Frequency Summary:');b=t.index('Detail Timing Paths Information',a);first=t.index('Path Summary:');results[tag]=dict(frequency_summary=t[a:b],first_path=t[first:first+850],resources=E.parse(O/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib)
assert source.read_text()==s
r=dict(status='PASS_ISOLATED_PANE_ALGEBRA_MAPPING_NOT_APPLIED',axis_cases=len(dimensions)*8192*5*2,actual_dimensions=actual,tested_dimensions=dimensions,results=results,before_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),scope='Actual pane shapes and all13bit signed coordinates; same3registered edges in both small probes. No whole-design STA claim.',programming=False)
(A/'ALGEBRA_MAPPING.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
