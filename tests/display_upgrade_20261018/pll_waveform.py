"""Measure current real Gowin PLL-model outputs; no clock-frequency stubs."""
from pathlib import Path
import subprocess,json,hashlib,statistics,math,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
tb='''`timescale 1ns/1fs
module tb_pll_waveform;
reg ref_clk=0,reset=1,recording=0;always#18.518518518 ref_clk=~ref_clk;
wire lock,sc,pc,rc;integer fo;
GSR GSR(.GSRI(1'b1));
visual_PLL_MOD p(.lock(lock),.clkout0(sc),.clkout1(pc),.clkout2(rc),.clkin(ref_clk),.reset(reset),.icpsel(6'd0),.lpfres(3'd0),.lpfcap(2'b00));
always@(posedge sc)if(recording)$fdisplay(fo,"S %0.6f",$realtime);
always@(posedge pc)if(recording)$fdisplay(fo,"P %0.6f",$realtime);
always@(posedge rc)if(recording)$fdisplay(fo,"R %0.6f",$realtime);
always@(negedge rc)if(recording)$fdisplay(fo,"F %0.6f",$realtime);
initial begin
fo=$fopen("tests/display_upgrade_20261018/pll_trace.txt","w");
#100;reset=0;wait(lock===1);repeat(10)@(negedge pc);recording=1;
repeat(40)@(negedge pc);recording=0;$fclose(fo);$display("PASS raw Gowin PLL model locked and captured");$finish;
end
initial begin#1000000;$fatal(1,"PLL lock timeout");end
endmodule
'''
(O/'tb_pll_waveform.sv').write_text(tb)
# Icarus constant-folds each static phase decoder's always@(*) into an
# empty sensitivity list and never executes it (its own warning confirms
# this). The vendor decoder intends combinational parameter assignment.
# Use always_comb's standard time-zero execution in a private model copy.
# Phase/duty algorithms and all other primitive code are unmodified.
vendor=Path(r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')
original=vendor.read_text();aa=original.index('module PLL (');bb=original.index('endmodule',aa)
pll=original[aa:bb]
pll,count=re.subn(r'always @\(\*\)(\s*\nbegin\s*\n    if\(DYN_PE[0-6]_SEL)',r'always_comb\1',pll)
assert count==7,count
compatible=original[:aa]+pll+original[bb:]
model=O/'prim_sim_static_phase_compat.sv';model.write_text(compatible)
iv=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');vv=iv.with_name('vvp.exe')
for label,args in [('compile',[iv,'-g2012','-s','tb_pll_waveform','-o',O/'pll_waveform.vvp',O/'tb_pll_waveform.sv',R/'src/display/gowin_pll/visual_pll_mod.v',model]),('run',[vv,O/'pll_waveform.vvp'])]:
 z=subprocess.run(list(map(str,args)),cwd=R,capture_output=True);(O/('pll_'+label+'.log')).write_bytes(z.stdout+z.stderr);assert z.returncode==0,z.stdout[-1000:]+z.stderr[-1000:]
events={k:[] for k in 'SPRF'}
for line in (O/'pll_trace.txt').read_text().splitlines():
 k,t=line.split();events[k].append(float(t))
periods={k:statistics.median(b-a for a,b in zip(v,v[1:])) for k,v in events.items() if k in 'SPR'}
for k,expect in [('S',1000/371.25),('P',1000/74.25),('R',1000/74.25)]:assert abs(periods[k]-expect)<.005,(k,periods[k],expect)
phases=[min(t-p for p in events['P'] if p<=t) for t in events['R'][1:]]
high=[min(f-t for f in events['F'] if f>t) for t in events['R'][:-1]]
expected_phase=1000/742.5*(1+7/8)+.1
expected_high=1000/74.25/2-.1
assert all(abs(p-expected_phase)<.005 for p in phases),phases
assert all(abs(p-expected_high)<.005 for p in high),high
result={'status':'PASS','model':'Current production visual_PLL_MOD plus private Gowin GW5A primitive model copy;27MHz reference; no PLL_INIT analog-startup claim','model_compatibility':'Only7 static phase decoder always@(*) blocks changed to always_comb, enabling time-zero execution under Icarus. Original emits empty-sensitivity warnings and incorrectly leaves static coarse/fine at0. Phase/duty algorithms unchanged; no production source or installed vendor files modified.','original_vendor_sha256':hashlib.sha256(vendor.read_bytes()).hexdigest(),'compatible_model_sha256':hashlib.sha256(model.read_bytes()).hexdigest(),'period_ns':periods,'reset_rise_after_pixel_ns':[min(phases),max(phases)],'reset_high_ns':[min(high),max(high)],'expected_reset_phase_ns':expected_phase,'expected_reset_high_ns':expected_high,'scope':'Frequency/relative phase/duty in compatibility-adapted vendor digital model. Model timestamps rounded to1ps; actual routed delays covered separately by STA.','source_sha256':{'src/display/gowin_pll/visual_pll_mod.v':hashlib.sha256((R/'src/display/gowin_pll/visual_pll_mod.v').read_bytes()).hexdigest()}}
(O/'PLL_WAVEFORM.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True)
