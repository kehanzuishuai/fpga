`timescale 1ns/1ps
module tb_status_cdc;
 reg ac=0,pc=0,rst=0,update=0,frame_start=0;always #7 ac=~ac;always #5 pc=~pc;
 reg [511:0] bus=0;wire ready,valid;wire [511:0] snapshot;
 integer i;
 visual_status_cdc dut(ac,rst,update,bus,ready,pc,rst,frame_start,valid,snapshot);
 task frame;begin @(negedge pc);frame_start=1;@(negedge pc);frame_start=0;end endtask
 task send(input [511:0] data);begin wait(ready);@(negedge ac);bus=data;update=1;@(negedge ac);update=0;end endtask
 initial begin
  #1;rst=1;#1;rst=0;repeat(4)@(negedge ac);rst=1;
  if(valid)$fatal(1,"fake startup telemetry");
  send(512'h123456789abcdef);bus='1;repeat(8)@(negedge pc);
  if(valid || ready)$fatal(1,"snapshot published before boundary");
  frame();if(!valid || snapshot!==512'h123456789abcdef)$fatal(1,"torn snapshot");
  repeat(5)@(negedge ac);if(!ready)$fatal(1,"ack did not cross");
  send(512'hfedcba987654321);repeat(8)@(negedge pc);
  if(snapshot!==512'h123456789abcdef)$fatal(1,"midframe change");
  frame();if(snapshot!==512'hfedcba987654321)$fatal(1,"second snapshot");
  for(i=0;i<59;i=i+1)frame();if(!valid)$fatal(1,"early expiry");
  frame();if(valid)$fatal(1,"stale keys remain valid");
  send(512'h55);repeat(8)@(negedge pc);frame();if(!valid || snapshot!==512'h55)$fatal(1,"expiry recovery");
  rst=0;#1;if(valid || snapshot!=0)$fatal(1,"reset stale telemetry");
  $display("PASS telemetry CDC: atomic frame publish, ready/ack, no startup values, 60-frame expiry and recovery");$finish;
 end
 initial begin #100000;$fatal(1,"status timeout");end
endmodule
