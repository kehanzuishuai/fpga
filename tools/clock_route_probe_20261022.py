"""Small physical P16 clock-ingress probes; no programming."""
from pathlib import Path
import sys, subprocess, shutil, json
R=Path(__file__).resolve().parents[1]
kind=sys.argv[1];assert kind in ['direct','dcs_pg','pll_bypass']
D=R/'audit/autonomous_timing_20261022_154006/clock_probes'/(sys.argv[2] if len(sys.argv)>2 else kind)
D.mkdir(parents=True,exist_ok=False)
body='wire clock_logic;'
if kind=='direct':body+='assign clock_logic=clk_50m;'
elif kind=='dcs_pg':body+='''
 DCS clock_buffer(.CLKIN0(clk_50m),.CLKIN1(1'b0),.CLKIN2(1'b0),.CLKIN3(1'b0),
 .CLKSEL(4'b0001),.SELFORCE(1'b1),.CLKOUT(clock_logic));
 defparam clock_buffer.DCS_MODE="CLK0";
'''
else:
 s=(R/'src/gowin_pll/audio_pll_mod.v').read_text()
 s=s.replace('(lock, clkout0, clkin,', '(lock, clkout0, clkout1, clkin,')
 s=s.replace('output clkout0;', 'output clkout0;output clkout1;').replace('wire clkout1;','')
 # PA2115 requires the divider channel disabled when selecting raw-input bypass.
 s=s.replace("PLL_inst.CLK1_OUT_SEL = 1'b0", "PLL_inst.CLK1_OUT_SEL = 1'b1")
 (D/'pll.v').write_text(s);shutil.copy2(R/'src/pll_init.v',D/'pll_init.v')
 body+='''
 wire clk_audio,lock,pll_reset,ready;wire [5:0] icp;wire [2:0] lpf;
 audio_PLL_MOD pll(.clkin(clk_50m),.reset(pll_reset),.clkout0(clk_audio),.clkout1(clock_logic),.lock(lock),.icpsel(icp),.lpfres(lpf),.lpfcap(2'b00));
 PLL_INIT #(.CLK_PERIOD(20),.MULTI_FAC(14)) init(.CLKIN(clk_50m),.I_RST(~rst_n),.PLLLOCK(lock),.O_RST(pll_reset),.O_LOCK(ready),.ICPSEL(icp),.LPFRES(lpf));
 reg [7:0] audio_count;always @(posedge clk_audio or negedge rst_n)if(!rst_n)audio_count<=0;else audio_count<=audio_count+1'b1;
'''
src='''(* syn_srlstyle="registers" *) module probe(input clk_50m,rst_n,output [7:0] pins);
'''+body+'''
 reg [63:0] q[0:7];genvar g;generate for(g=0;g<8;g=g+1)begin:bank
 always @(posedge clock_logic or negedge rst_n)if(!rst_n)q[g]<=64'(g+1);else q[g]<={q[g][62:0],q[g][63]^q[g][62]^q[g][60]^q[g][59]};
 assign pins[g]=^q[g];end endgenerate
endmodule
'''
if kind=='pll_bypass':src=src.replace('assign pins[g]=^q[g];','assign pins[g]=(^q[g])^audio_count[g]^ready;')
(D/'probe.v').write_text(src)
cst='IO_LOC "clk_50m" P16;\nIO_PORT "clk_50m" IO_TYPE=LVCMOS33;\nIO_LOC "rst_n" K16;\nIO_PORT "rst_n" IO_TYPE=LVCMOS33;\n'
for i,pin in enumerate(['E22','F24','G24','C24','B24','H15','A20','B21']):cst+=f'IO_LOC "pins[{i}]" {pin};\nIO_PORT "pins[{i}]" IO_TYPE=LVCMOS33;\n'
if kind=='direct':cst+='CLOCK_LOC "clk_50m_d" BUFG = CLK;\n'
if kind=='dcs_pg':cst+='INS_LOC "clock_buffer" PG[0];\n'
(D/'probe.cst').write_text(cst)
sdc='create_clock -name clk_50m -period 20.000 [get_ports {clk_50m}]\n'
if kind=='dcs_pg':sdc+='create_generated_clock -name logic_clock -source [get_ports {clk_50m}] -divide_by 1 [get_pins {clock_buffer/CLKOUT}]\n'
if kind=='pll_bypass':sdc+='create_generated_clock -name logic_clock -source [get_ports {clk_50m}] -divide_by 1 [get_pins {pll/PLL_inst/CLKOUT1}]\n'
(D/'probe.sdc').write_text(sdc)
files=['probe.v']+(['pll.v','pll_init.v'] if kind=='pll_bypass' else [])
(D/'probe.gprj').write_text('<?xml version="1.0"?><Project><Template>FPGA</Template><Version>5</Version><Device name="GW5AST-138C" pn="GW5AST-LV138FPG676AC1/I0">gw5ast138c-003</Device><FileList>'+''.join(f'<File path="{p}" type="file.verilog" enable="1"/>' for p in files)+'<File path="probe.cst" type="file.cst" enable="1"/><File path="probe.sdc" type="file.sdc" enable="1"/></FileList></Project>')
(D/'run.tcl').write_text(f'cd {{{D.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module probe\nset_option -timing_driven 1\nset_option -gen_text_timing_rpt 1\nrun all\nexit\n')
with (D/'console.log').open('w') as f:p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(D/'run.tcl')],cwd=D,stdout=f,stderr=subprocess.STDOUT)
text=(D/'console.log').read_text(errors='replace');print(kind,'return',p.returncode,text[-1800:],flush=True)
(D/'RESULT.json').write_text(json.dumps({'kind':kind,'returncode':p.returncode,'programming':False,'console_tail':text[-4000:]},indent=2))
