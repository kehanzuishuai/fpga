`timescale 1ns/1ps
module tb_capture_cdc;
 reg ac=0,pc=0,ar=0,pr=0,valid=0;always #5 ac=~ac;always #3 pc=~pc;
 reg signed [23:0] pcm=0,xx=0,yy=0;wire [9:0] b,g,r;wire [31:0] fd,wd,sd;
 integer n,i,wv,xv,yv;reg [48:0] expected;
 audio_visualizer #(.LOGN(10)) dut(ac,ar,valid,pcm,1'b1,xx,yy,pc,pr,b,g,r,fd,wd,sd);
 initial begin
 repeat(4)@(negedge ac);ar=1;pr=1;repeat(8)@(negedge ac);
 for(n=0;n<1100;n=n+1)begin
  wv=$rtoi(1000.0*$sin(6.283185307179586*n/32.0));
  xv=$rtoi(100.0*$sin(6.283185307179586*n/16.0));
  yv=$rtoi(50.0*$cos(6.283185307179586*n/16.0));
  @(negedge ac);pcm=24'(wv*256);xx=24'(xv*256);yy=24'(yv*256);valid=1;
  @(negedge ac);valid=0;repeat(62)@(negedge ac);
 end
 repeat(8)@(negedge pc);if(!dut.wave_pending)$fatal(1,"no complete trace");
 // First valid paired PCM is n63; rising crossing n64 starts snapshot.
 for(i=0;i<512;i=i+1)begin
  n=i+64;wv=$rtoi(1000.0*$sin(6.283185307179586*n/32.0));
  xv=$rtoi(100.0*$sin(6.283185307179586*n/16.0));
  yv=$rtoi(50.0*$cos(6.283185307179586*n/16.0));
  expected={16'(wv),1'b1,16'(xv),16'(yv)};
  if(dut.wave_frames.ram[i]!==expected)$fatal(1,"paired snapshot %d got %h expected %h",i,dut.wave_frames.ram[i],expected);
 end
 @(negedge pc);pr=0;#1;if(dut.analysis_rst_n||dut.display_rst_n||dut.wave_pending)$fatal(1,"pixel reset CDC");
 pr=1;repeat(8)@(negedge ac);repeat(8)@(negedge pc);
 if(!dut.analysis_rst_n||!dut.display_rst_n)$fatal(1,"reset release");
 $display("PASS full audio_visualizer: same-input-tick 16-bit XY -> triggered512 snapshot -> frozen CDC bank; video reset clears both endpoints");$finish;
 end
 initial begin #20000000;$fatal(1,"timeout");end
endmodule
