"""Fast display-only synthesis to find74.25MHz paths before full P&R."""
from pathlib import Path
import sys,subprocess,re,html,json
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'synth_probes'/sys.argv[1]
O.mkdir(parents=True,exist_ok=True)
(O/'probe.sv').write_text('''module display_synthesis_probe(
input wire audio_clk,pixel_clk,audio_rst_n,pixel_rst_n,pcm_valid,
input wire signed[23:0]pcm,input wire[57:0]status_audio,
output wire[9:0]b,g,r,output wire[31:0]fd,wd,sd);
audio_visualizer #(.STATUS_ENABLE(1),.MAPPING_CONFIRMED(0)) u(
.audio_clk(audio_clk),.audio_rst_n(audio_rst_n),.pcm_valid(pcm_valid),.pcm(pcm),
.xy_enable(1'b0),.xy_x(24'sd0),.xy_y(24'sd0),.pixel_clk(pixel_clk),.pixel_rst_n(pixel_rst_n),
.tmds_blue(b),.tmds_green(g),.tmds_red(r),.fft_dropped(fd),.wave_dropped(wd),.spectrum_dropped(sd),.status_audio(status_audio));
endmodule''')
(O/'probe.sdc').write_text('create_clock -name audio_clk -period81.379 [get_ports {audio_clk}]\ncreate_clock -name pixel_clk -period13.468 [get_ports {pixel_clk}]\nset_clock_groups -asynchronous -group [get_clocks {audio_clk}] -group [get_clocks {pixel_clk}]\n'.replace('-period81','-period 81').replace('-period13','-period 13'))
files=[p for p in (R/'src/display').glob('*') if p.suffix in ['.v','.sv'] and p.name not in ['visual_video_clock.v','visual_dvi_io.v']]+[O/'probe.sv']
(O/'probe.gprj').write_text('<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE gowin-fpga-project><Project><Template>FPGA</Template><Version>5</Version><Device name="GW5AST-138C" pn="GW5AST-LV138FPG676AC1/I0">gw5ast138c-003</Device><FileList>'+''.join(f'<File path="{p.as_posix()}" type="file.verilog" enable="1"/>' for p in files)+f'<File path="{(O/"probe.sdc").as_posix()}" type="file.sdc" enable="1"/></FileList></Project>')
(O/'synth.tcl').write_text('cd {'+O.as_posix()+'}\nopen_project {'+(O/'probe.gprj').as_posix()+'}\nset_option -verilog_std sysv2017\nset_option -top_module display_synthesis_probe\nrun syn\n')
with (O/'synthesis.log').open('w') as f:p=subprocess.run([r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'synth.tcl')],cwd=R,stdout=f,stderr=subprocess.STDOUT)
assert p.returncode==0,(O/'synthesis.log').read_text(errors='replace')[-2000:]
s=(O/'impl/gwsynthesis/probe_syn.rpt.html').read_text();z=html.unescape(re.sub('<[^>]+>',' ',s))
a=z.index('Max Frequency Summary:',z.index('Max Frequency Summary')+1);b=z.index('Detail Timing Paths Information',a)
paths=re.findall(r'From\s+([^\r\n]+).*?To\s+([^\r\n]+)',z[b:],re.S)
result={'frequency_report':z[a:b],'critical_paths':paths,'scope':'Display-only synthesis estimate, not final integrated P&R/STA'}
(O/'RESULT.json').write_text(json.dumps(result,indent=2));print(result['frequency_report']);print(paths)
