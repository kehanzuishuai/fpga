`timescale 1ns/1ps
module tb_status_adapter;
 reg clk=0;always #5 clk=~clk;
 reg rst=0,pv=0,kv=0,owned=0,sw=0,sounding=0,resting=0,ready=0;
 reg signed [23:0] l=0,r=0;
 reg [31:0] keys=0,voices=0;reg [223:0] mapping=0,notes=0;
 reg [2:0] instrument=0;reg [6:0] score_note=0;reg [15:0] completed=0;
 wire update;wire [511:0] bus;integer i;
 display_status_adapter #(.SAMPLE_RATE(120)) dut(clk,rst,pv,l,r,kv,keys,mapping,
  instrument,voices,notes,owned,sw,sounding,resting,score_note,completed,
  owned?2'd1:2'd0,32'd0,3'd0,16'd0,ready,update,bus);
 task sample(input signed [23:0] a,b);begin
  @(negedge clk);l=a;r=b;pv=1;@(negedge clk);pv=0;
 end endtask
 initial begin
  #1;rst=1;#1;rst=0;repeat(3)@(negedge clk);rst=1;
  for(i=0;i<32;i=i+1)mapping[i*7+:7]=7'(60+i);
  #1;if(bus[0] || bus[3] || bus[5])$fatal(1,"fabricated touch/note/envelope");
  kv=1;keys=32'h80010001;voices=32'h80000000;notes[31*7+:7]=91;#1;
  if(bus[49:18]!==keys || bus[81:50]!==voices || bus[305:82]!==mapping || bus[17:11]!=91 || !bus[3] || bus[454:450]!=31)$fatal(1,"32-key or real voice association");
  keys=0;#1;if(bus[49:18]!=0 || bus[81:50]!=voices || !bus[3])$fatal(1,"release voice confused with keys");
  owned=1;instrument=2;sounding=1;score_note=76;completed=12;#1;
  if(bus[10:8]!=2 || bus[457:456]!=1 || bus[489:458]!==32'h00010000 || bus[508:493]!=12)$fatal(1,"score inverse mapping");
  mapping[16*7+:7]=40;#1;if(bus[489:458]!=0)$fatal(1,"unmapped score invented key");
  resting=1;sounding=0;#1;if(bus[492:490]!=6 || bus[489:458]!=0)$fatal(1,"rest highlights");
  sw=1;#1;if(bus[492:490]!=1)$fatal(1,"switching state");
  sample(24'sh7fffff,24'sh800000);sample(0,0);sample(0,0);sample(0,0);#1;
  if(bus[441:434]!=255 || bus[449:442]!=255)$fatal(1,"signed peak endpoints");
  repeat(4)sample(0,0);#1;if(bus[449:434]!=0)$fatal(1,"meter stale peak");
  @(negedge clk);pv=1;ready=0;#1;if(update)$fatal(1,"ignores mailbox backpressure");
  ready=1;#1;if(!update)$fatal(1,"snapshot not submitted");
  if(bus[511:509]!=0 || bus[5])$fatal(1,"invalid reserved/env bits");
  $display("PASS 32-key/status adapter: real voice note, release separation, score remap/rest, signed L/R peaks and mailbox handshake");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
