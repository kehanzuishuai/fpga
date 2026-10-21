`timescale 1ns/1ps
module tb_yinse_switch_edges;
 reg clk=0,rst_n=0,tick=0,loader=0;
 reg [2:0] requested=0;reg [15:0] keys=0;
 always #5 clk=~clk;
 wire [2:0] current;wire [15:0] gain;
 wire blocked,flush,clear,commit,busy;
 yinse_switch #(.FADE_SAMPLES(4)) dut(clk,rst_n,tick,requested,keys,loader,
 current,gain,blocked,flush,clear,commit,busy);
 task frame;
  begin @(negedge clk);tick=1;@(negedge clk);tick=0;repeat(2)@(negedge clk);end
 endtask
 integer n;
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(3)@(negedge clk);rst_n=1;
  requested=1;n=0;
  while(current!=1 && n<20)begin frame;n=n+1;end
  if(current!=1 || gain!=0 || !busy)$fatal(1,"commit not at silence");
  // A fresh NoteOn during fade-in must be deliverable; otherwise a held key
  // is silently lost after the ramp, since no second keyboard edge occurs.
  frame;keys=1;
  if(blocked)$fatal(1,"fresh NoteOn during fade-in would be lost");
  repeat(6)frame;
  if(busy || blocked || gain!=65535)$fatal(1,"fade-in did not finish");
  requested=2;frame;repeat(8)frame;
  if(current!=1 || gain!=0 || !blocked)$fatal(1,"held-key barrier bypassed");
  keys=0;loader=1;repeat(3)frame;
  if(current!=1)$fatal(1,"loader barrier bypassed");
  loader=0;frame;requested=3;frame;
  if(!blocked)$fatal(1,"new switch during fade-in must block NoteOn");
  repeat(20)frame;
  if(current!=3 || gain!=65535 || busy)$fatal(1,"latest request failed");
  requested=7;repeat(8)frame;
  if(current!=3 || blocked || busy)$fatal(1,"invalid selection changed state");
  $display("PASS switch edges: fresh key during fade-in, held-key/loader barrier, ramp interruption and invalid request");$finish;
 end
 initial begin #100000;$fatal(1,"watchdog");end
endmodule
