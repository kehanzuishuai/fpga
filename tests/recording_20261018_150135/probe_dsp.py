"""Extract exact DSP instances from the delivered netlist, without changing them."""
from pathlib import Path
import re, hashlib, json, subprocess
R=Path(__file__).resolve().parents[2]; O=Path(__file__).resolve().parent
p=R/'impl/gwsynthesis/yinyue_fashengqi.vg'; s=p.read_text()
blocks=[]
for name in ['mp_lo_0_s','mp_hi_0_s','mr_0_s']:
    b=re.search(r'  MULTALU27X18 '+name+r' \([\s\S]*?defparam '+name+r'\.PSEL_IREG_RESET="RESET0";',s).group()
    blocks.append(b)
fixture='''`timescale 1ns/1ps
module tb_dsp;
reg clk_12m288=0; always #5 clk_12m288=~clk_12m288;
wire GND=1'b0,VCC=1'b1,n1237_8=1'b1; reg n290_6=1;
reg [11:0] level_q=1700,lv_a=1800,lv_b=1850;
reg [19:0] ratio_q=32800,ratio_a=32816;
reg [1:0] note_c=0; wire [8:0] ratio_addr=0;
wire [47:0] DOUT_1,DOUT_2,DOUT_3,CASO_0,CASO_1,CASO_2;
wire [26:0] SOA_0,SOA_1,SOA_2;
wire [15:2] mp_lo,mp_hi; wire [21:2] mr;
GSR GSR(.GSRI(1'b1));
integer k;
initial begin
repeat(5) @(negedge clk_12m288); n290_6=0;
for(k=0;k<4;k=k+1) begin
note_c=k; repeat(4) @(negedge clk_12m288);
$display("PROBE ap=%0d ratio_delta_quarter=%0d expected=%0d level_delta_quarter=%0d expected=%0d",k,$signed(mr),(-16*k)>>>2,$signed(mp_lo),(-100*k)>>>2);
end
$finish; end
'''+ '\n'.join(blocks)+'\nendmodule\n'
(O/'tb_dsp.v').write_text(fixture)
(R/'audit/recording_20261018_150135/DSP_EXTRACTION.json').write_text(json.dumps({'source':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'instances':['mp_lo_0_s','mp_hi_0_s','mr_0_s'],'scope':'Exact instance connections and defparams from delivered full synthesis netlist; only external operands driven by test fixture'},indent=2))
iv=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe'); vv=iv.with_name('vvp.exe')
for label,args in [('compile',[iv,'-g2012','-s','tb_dsp','-o',O/'dsp.vvp',O/'tb_dsp.v',r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v']),('run',[vv,O/'dsp.vvp'])]:
    z=subprocess.run(list(map(str,args)),cwd=R,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (O/f'dsp_{label}.log').write_bytes(z.stdout)
    print(z.stdout.decode(errors='replace')); assert z.returncode==0,(label,z.returncode)
