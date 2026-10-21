`timescale 1ns/1fs
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
