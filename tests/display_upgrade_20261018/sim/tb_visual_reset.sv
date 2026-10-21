`timescale 1ns/1ps
module tb_visual_reset;
 reg ac=0,pc=0,ar=0,pr=0;
 always #7 ac=~ac;
 always #11 pc=~pc;
 wire [9:0]b,g,r;wire [31:0]fd,wd,sd;
 audio_visualizer #(.LOGN(10)) dut(ac,ar,1'b0,24'sd0,1'b0,24'sd0,24'sd0,
                                  pc,pr,b,g,r,fd,wd,sd,58'd0);
 task settled;
 begin repeat(6)@(negedge ac);repeat(6)@(negedge pc);
 if(!dut.analysis_rst_n || !dut.display_rst_n)$fatal(1,"reset did not release");end
 endtask
 task asserted;
 begin #1;
 if(dut.analysis_rst_n || dut.display_rst_n)$fatal(1,"mailbox domains not reset together");
 if(dut.wave_pending || dut.spec_pending)$fatal(1,"stale snapshot after reset");end
 endtask
 initial begin
 #1;ar=1;pr=1;#1;ar=0;pr=0;asserted();
 ar=1;pr=1;settled();
 @(negedge ac);ar=0;asserted();ar=1;settled();
 @(negedge pc);pr=0;asserted();pr=1;settled();
 $display("PASS audio-only and pixel-only reset assert both CDC ends and release synchronously");
 $finish;
 end
endmodule
