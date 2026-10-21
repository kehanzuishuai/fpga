"""Small physical-clock probe; production sources are read-only."""
from pathlib import Path
import sys,re,subprocess,json
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'clock_probes'/sys.argv[1];O.mkdir(parents=True,exist_ok=True)
mode=sys.argv[1]
s=(R/'src/display/visual_dvi_io.v').read_text()
if mode.startswith('six'):s=s.replace('reg [3:0] reset_release','reg [4:0] reset_release').replace('reset_release[2:0]','reset_release[3:0]').replace('local_rst_n<=reset_release[3]','local_rst_n<=reset_release[4]')
if mode in ['six_n','six_nloc']:s=s.replace('always @(posedge serial_global','always @(negedge serial_global')
if mode.startswith('half'):
 s=s.replace('output wire ck_p,ck_n);','output wire ck_p,ck_n,input wire reset_clk);')
 s=s.replace(' wire [2:0] serial_data;', ''' wire reset_global;
 DCS reset_buffer(.CLKIN0(reset_clk),.CLKIN1(1'b0),.CLKIN2(1'b0),.CLKIN3(1'b0),.CLKSEL(4'b0001),.SELFORCE(1'b1),.CLKOUT(reset_global));
 defparam reset_buffer.DCS_MODE="CLK0";
 wire [2:0] serial_data;''')
 s=s.replace('negedge serial_global','posedge reset_global')
 vc=(R/'src/display/visual_video_clock.v').read_text().replace('serial_clk,locked);','serial_clk,locked,serial_reset_clk);').replace('.clkout0(serial_clk),.clkout1(pixel_clk)', '.clkout0(serial_clk),.clkout1(pixel_clk),.clkout2(serial_reset_clk)')
 (O/'visual_video_clock.v').write_text(vc)
 pll=(R/'src/display/gowin_pll/visual_pll_mod.v').read_text().replace('lpfres, lpfcap);','lpfres, lpfcap, clkout2);').replace('wire clkout2;','output clkout2;').replace('PLL_inst.ODIV2_SEL = 8','PLL_inst.ODIV2_SEL = 4').replace('PLL_inst.CLKOUT2_EN = "FALSE"','PLL_inst.CLKOUT2_EN = "TRUE"').replace('PLL_inst.CLKOUT2_PE_COARSE = 0','PLL_inst.CLKOUT2_PE_COARSE = 1')
 if mode in ['half_trim','half_fine_trim']:
  pll=pll.replace("PLL_inst.CLKOUT2_DT_DIR = 1'b1","PLL_inst.CLKOUT2_DT_DIR = 1'b0").replace('PLL_inst.CLKOUT2_DT_STEP = 0','PLL_inst.CLKOUT2_DT_STEP = '+('4' if mode=='half_trim' else '1'))
  if mode=='half_fine_trim':pll=pll.replace('PLL_inst.CLKOUT2_PE_FINE = 0','PLL_inst.CLKOUT2_PE_FINE = 1')
 (O/'visual_pll_mod.v').write_text(pll)
if mode.startswith('dcs'):
 s=s.replace(' wire [2:0] serial_data;', ''' wire serial_global;
 DCS serial_buffer(.CLKIN0(serial_clk),.CLKIN1(1'b0),.CLKIN2(1'b0),.CLKIN3(1'b0),.CLKSEL(4'b0001),.SELFORCE(1'b1),.CLKOUT(serial_global));
 defparam serial_buffer.DCS_MODE="CLK0";
 wire [2:0] serial_data;''').replace('.FCLK(serial_clk)','.FCLK(serial_global)')
if mode.startswith('dcs_serial'):
 s=s.replace(' genvar i;', ''' (* async_reg="true",syn_preserve=1,syn_keep=1 *) reg [3:0] reset_release;
 always @(posedge serial_global or negedge rst_n)
 if(!rst_n)reset_release<=0;else reset_release<={reset_release[2:0],1'b1};
 genvar i;''')
 s=s.replace('always @(posedge pixel_clk or negedge rst_n)','always @(posedge serial_global or negedge rst_n)').replace("else local_rst_n<=1'b1;","else local_rst_n<=reset_release[3];")
 if mode.endswith('falling'):s=s.replace('always @(posedge serial_global or negedge rst_n)\n     if','always @(negedge serial_global or negedge rst_n)\n     if')
(O/'probe_dvi.v').write_text(s)
(O/'probe.v').write_text('''module clock_probe(input wire clk_50m,rst_n,output wire [2:0] video_d_p,video_d_n,output wire video_ck_p,video_ck_n);
wire pixel_clk,serial_clk,video_locked;
visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked);
reg meta,reset_n;always@(posedge pixel_clk or negedge video_locked)if(!video_locked)begin meta<=0;reset_n<=0;end else begin meta<=1;reset_n<=meta;end
reg[9:0]word_data;always@(posedge pixel_clk)word_data<=word_data+1'b1;
visual_dvi_io u_video_io(pixel_clk,serial_clk,reset_n,word_data,word_data^10'h155,word_data^10'h2aa,video_d_p,video_d_n,video_ck_p,video_ck_n);
endmodule''')
if mode.startswith('half'):
 p=O/'probe.v';q=p.read_text().replace('wire pixel_clk,serial_clk,video_locked;','wire pixel_clk,serial_clk,video_locked,serial_reset_clk;').replace('pixel_clk,serial_clk,video_locked);','pixel_clk,serial_clk,video_locked,serial_reset_clk);').replace('video_d_n,video_ck_p,video_ck_n);','video_d_n,video_ck_p,video_ck_n,serial_reset_clk);');p.write_text(q)
cst=(R/'src/integrated.cst').read_text();(O/'probe.cst').write_text('\n'.join(l for l in cst.splitlines() if any('"'+p+'"' in l for p in ['clk_50m','rst_n','video_d_p[0]','video_d_p[1]','video_d_p[2]','video_ck_p'])))
if mode in ['six_b','six_1a','six_1b','six_nloc','half_loc','half_trim','half_fine_trim']:
 slot,side={'six_b':(0,'B'),'six_1a':(1,'A'),'six_1b':(1,'B'),'six_nloc':(0,'B'),'half_loc':(0,'B'),'half_trim':(0,'B'),'half_fine_trim':(0,'B')}[mode]
 with (O/'probe.cst').open('a') as f:
  for ch,row in enumerate([35,47,33]):f.write(f'\nINS_LOC "u_video_io/channels[{ch}].local_rst_n_s1" R{row}C181[{slot}][{side}];\n')
sdc=(R/'src/integrated.sdc').read_text();sdc='\n'.join(l for l in sdc.splitlines() if (l.startswith('create') and 'audio_clk' not in l) or (l.startswith('set_false_path') and 'u_video_' in l))
if mode.startswith('dcs_serial'):
 sdc+='\ncreate_generated_clock -name video_serial_global -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT0}] -divide_by 1 [get_pins {u_video_io/serial_buffer/CLKOUT}]\n'
 sdc+='set_false_path -to [get_pins {u_video_io/reset_release_*/CLEAR u_video_io/channels*.local_rst_n_*/CLEAR u_video_io/reset_release_*/PRESET u_video_io/channels*.local_rst_n_*/PRESET}]\n'
if mode.startswith('half'):
 sdc+='\ncreate_generated_clock -name video_serial_reset -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT0}] -edges {2 4 6} [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT2}]\n'
 if mode in ['half_trim','half_fine_trim']:
  shift='{0.200 0.000 0.200}' if mode=='half_trim' else '{0.218350168 0.168350168 0.218350168}'
  sdc=sdc.replace('-edges {2 4 6} [get_pins','-edges {2 4 6} -edge_shift '+shift+' [get_pins')
 sdc+='create_generated_clock -name video_serial_reset_global -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT2}] -divide_by 1 [get_pins {u_video_io/reset_buffer/CLKOUT}]\n'
(O/'probe.sdc').write_text(sdc)
files=[R/'src/display/visual_video_clock.v',R/'src/pll_init.v',*list((R/'src/display/gowin_pll').glob('*.v')),O/'probe_dvi.v',O/'probe.v']
files=[p for p in files if p.name in ['visual_video_clock.v','pll_init.v','visual_pll_mod.v','visual_ref_pll_mod.v','probe_dvi.v','probe.v']]
if mode.startswith('half'):files=[O/p.name if p.name in ['visual_video_clock.v','visual_pll_mod.v'] else p for p in files]
(O/'probe.gprj').write_text('<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE gowin-fpga-project><Project><Template>FPGA</Template><Version>5</Version><Device name="GW5AST-138C" pn="GW5AST-LV138FPG676AC1/I0">gw5ast138c-003</Device><FileList>'+''.join(f'<File path="{p.as_posix()}" type="file.verilog" enable="1"/>' for p in files)+''.join(f'<File path="{(O/("probe."+s)).as_posix()}" type="file.{s}" enable="1"/>' for s in ['sdc','cst'])+'</FileList></Project>')
(O/'build.tcl').write_text('cd {'+O.as_posix()+'}\nopen_project {'+(O/'probe.gprj').as_posix()+'}\nset_option -verilog_std sysv2017\nset_option -top_module clock_probe\nset_option -gen_text_timing_rpt 1\nrun all\n')
with (O/'build.log').open('w') as f:p=subprocess.run([r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'build.tcl')],cwd=R,stdout=f,stderr=subprocess.STDOUT)
assert p.returncode==0,(O/'build.log').read_text(errors='replace')[-1500:]
tr=(O/'impl/pnr/probe.tr').read_text();start=tr.index('3.1.3 Recovery Paths Table',tr.index('3.1.3 Recovery Paths Table')+1);end=tr.index('3.1.4 Removal Paths Table',start)
print(tr[start:end],flush=True)
names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
slacks={k:float(m[1]) if (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',tr,re.M|re.S)) else None for k,v in names.items()}
ends={k:int(re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',tr)[1]) for k in ['Setup','Hold']}
result={'status':'PASS' if all(v is not None and v>=0 for v in slacks.values()) and ends=={'Setup':0,'Hold':0} else 'FAIL','slacks_ns':slacks,'violated_endpoints':ends,'scope':'Small physical-clock probe; full main implementation still required'}
(O/'RESULT.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True)
