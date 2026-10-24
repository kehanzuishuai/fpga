"""Isolated synthesis for measured, appearance-preserving display optimization."""
from pathlib import Path
import subprocess, sys, xml.etree.ElementTree as ET,shutil,re
R=Path(__file__).resolve().parents[2]
top=sys.argv[1]; tag=sys.argv[2];synthesis_top=top
O=R/'tests/display_integration_20261021/resource'/tag
O.mkdir(parents=True,exist_ok=True)
source=O/(top+'.sv')
source.write_bytes((R/'src/display'/(top+'.sv')).read_bytes())
if top=='visual_background' and 'address_pipeline' in sys.argv[3:]:
 sys.path.insert(0,str(R/'tools'))
 from pipeline_display_background_address_20261021 import pipeline_background_address
 source.write_text(pipeline_background_address(source.read_text()))
shutil.copytree(R/'assets',O/'assets',dirs_exist_ok=True)
project=ET.Element('Project');ET.SubElement(project,'Template').text='FPGA'
ET.SubElement(project,'Version').text='5'
ET.SubElement(project,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
files=ET.SubElement(project,'FileList')
ET.SubElement(files,'File',path=source.as_posix(),type='file.verilog',enable='1')
if top in ['visual_audio_core','visual_renderer']:
 for dep in (R/'src/display').iterdir():
  if dep.suffix in ['.sv','.v'] and dep.name!=source.name:
   copy=O/dep.name;copy.write_bytes(dep.read_bytes())
   ET.SubElement(files,'File',path=copy.as_posix(),type='file.verilog',enable='1')
if top=='visual_renderer':
 synthesis_top='visual_renderer_probe'
 # Match the production adapter: no single-ADSR telemetry exists in the piano.
 # Keeping bit5 dynamic would measure a deliberately invalid observation path.
 s=source.read_text();header=s[:s.index(');')+2]
 header=header.replace('visual_renderer #','visual_renderer_probe #').replace('output reg','output wire')
 ports='clk rst_n x y de hs vs blank_start wave_pending spec_pending wave_data spec_data wave_addr spec_addr wave_release spec_release red green blue out_de out_hs out_vs status_live'.split()
 wrapper=header+''' wire [511:0] actual_status={status_data[511:6],1'b0,status_data[4:0]};
 visual_renderer #(.LOGN(LOGN),.SAMPLE_RATE(SAMPLE_RATE)) render(
 '''+','.join(f'.{p}({p})' for p in ports)+',.status_data(actual_status));\nendmodule\n'
 w=O/'probe_top.sv';w.write_text(wrapper)
 ET.SubElement(files,'File',path=w.as_posix(),type='file.verilog',enable='1')
if top=='visual_audio_core':
 synthesis_top='visual_audio_core_probe'
 s=source.read_text();header=s[:s.index(' // Mailbox')]
 header=header.replace('module visual_audio_core #','module visual_audio_core_probe #')
 ports='audio_clk audio_rst_n pcm_valid pcm xy_enable xy_x xy_y pixel_clk pixel_rst_n tmds_blue tmds_green tmds_red fft_dropped wave_dropped spectrum_dropped status_update status_ready'.split()
 physical='physical_video' in sys.argv[3:]
 physical_body=''
 if physical:
  header=header.replace('input wire audio_clk', 'input wire clk_50m,audio_clk')
  end=header.rfind(');');header=header[:end]+',output wire [2:0] physical_d_p,physical_d_n,output wire physical_ck_p,physical_ck_n\n);\n'
  physical_body=''' wire physical_pixel,physical_serial,physical_locked,physical_reset_clock;
 visual_video_clock clocks(clk_50m,pixel_rst_n,physical_pixel,physical_serial,physical_locked,physical_reset_clock);
 visual_dvi_io io(physical_pixel,physical_serial,pixel_rst_n,tmds_blue,tmds_green,tmds_red,physical_d_p,physical_d_n,physical_ck_p,physical_ck_n,physical_reset_clock);
'''
  dep=R/'src/pll_init.v'
  ET.SubElement(files,'File',path=dep.as_posix(),type='file.verilog',enable='1')
  for pll_name in ['visual_ref_pll_mod.v','visual_pll_mod.v']:
   dep=R/'src/display/gowin_pll'/pll_name
   ET.SubElement(files,'File',path=dep.as_posix(),type='file.verilog',enable='1')
 if 'actual_audio_pll' in sys.argv[3:]:
  assert physical
  physical_body+=''' wire physical_audio,physical_audio_locked;
 audio_PLL audio_clock(.clkin(clk_50m),.init_clk(clk_50m),.reset(~audio_rst_n),.clkout0(physical_audio),.lock(physical_audio_locked));
'''
  for pll_name in ['audio_pll.v','audio_pll_mod.v']:
   dep=R/'src/gowin_pll'/pll_name
   ET.SubElement(files,'File',path=dep.as_posix(),type='file.verilog',enable='1')
 wrapper=header+physical_body+''' wire [511:0] actual_status={status_data[511:6],1'b0,status_data[4:0]};
 visual_audio_core #(.LOGN(LOGN),.SAMPLE_RATE(SAMPLE_RATE)) core(
 '''+','.join(f'.{p}({"physical_pixel" if physical and p=="pixel_clk" else "physical_audio" if "actual_audio_pll" in sys.argv[3:] and p=="audio_clk" else p})' for p in ports)+',.status_data(actual_status));\nendmodule\n'
 w=O/'probe_top.sv';w.write_text(wrapper)
 ET.SubElement(files,'File',path=w.as_posix(),type='file.verilog',enable='1')
if top=='visual_background' and len(sys.argv)>3 and sys.argv[3]=='registered_input':
 synthesis_top='visual_background_probe'
 w=O/'probe_top.sv'
 w.write_text('''module visual_background_probe(input clk,input [11:0] x,y,output [23:0] sharp_rgb,frost_rgb);
 reg [11:0] xq,yq;always @(posedge clk)begin xq<=x;yq<=y;end
 visual_background bg(clk,xq,yq,sharp_rgb,frost_rgb);endmodule
''')
 ET.SubElement(files,'File',path=w.as_posix(),type='file.verilog',enable='1')
if 'distributed_shift_candidate' in sys.argv[3:]:
 for candidate in O.glob('*.sv'):
  original=candidate.read_text()
  modified=re.sub(r'syn_srlstyle\s*=\s*"registers"', 'syn_srlstyle="distributed_ram"', original)
  if modified!=original:candidate.write_text(modified)
(O/'probe.gprj').write_bytes(ET.tostring(project,encoding='utf-8',xml_declaration=True))
if 'actual_audio_clock' in sys.argv[3:]:
 sdc=O/'probe.sdc';sdc.write_text('create_clock -name audio_clk -period 81.380208333333 [get_ports {audio_clk}]\n')
 ET.SubElement(files,'File',path=sdc.as_posix(),type='file.sdc',enable='1')
 (O/'probe.gprj').write_bytes(ET.tostring(project,encoding='utf-8',xml_declaration=True))
(O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module {synthesis_top}\nrun syn\nexit\n')
with (O/'probe.log').open('w') as f:
 p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT)
print((O/'probe.log').read_text(errors='replace')[-2500:],flush=True)
sys.exit(p.returncode)
