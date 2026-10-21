`timescale 1ns/1ps
module tb_steps;
 reg clk=0;always #5 clk=~clk;reg rst_n=0,sw=0,fault=0,lm=0,lt=0,mv=0,tv=0;
 wire mr,tr,mnext,tnext,af;reg [1:0] mvalue=0,mrequested=0;reg [2:0] tvalue=0,trequested=0;
 reg freeze=0;integer mpulses=0,tpulses=0;
 wifi_request_steps #(.CLK_HZ(1000)) dut(clk,rst_n,sw,fault,lm,lt,mv,mr,mvalue,mrequested,tv,tr,tvalue,trequested,mnext,tnext,af);
 always @(posedge clk)if(rst_n && !freeze)begin
  if(mnext)begin mrequested<=mrequested==2?2'd0:mrequested+1'b1;mpulses<=mpulses+1;end
  if(tnext)begin trequested<=trequested==4?3'd0:trequested+1'b1;tpulses<=tpulses+1;end
 end
 task mode(input [1:0] v);begin @(negedge clk);mvalue=v;mv=1;wait(mr);@(negedge clk);mv=0;end endtask
 task timbre(input [2:0] v);begin @(negedge clk);tvalue=v;tv=1;wait(tr);@(negedge clk);tv=0;end endtask
 initial begin
  repeat(4)@(negedge clk);rst_n=1;
  mode(2);repeat(15)@(negedge clk);if(mrequested!=2||mpulses!=2)$fatal(1,"mode steps");
  timbre(3);repeat(20)@(negedge clk);if(trequested!=3||tpulses!=3)$fatal(1,"timbre steps");
  timbre(0);repeat(15)@(negedge clk);if(trequested!=0||tpulses!=5)$fatal(1,"wrap");
  sw=1;#1;if(mr||tr)$fatal(1,"busy ready");sw=0;
  lt=1;#1;if(tr)$fatal(1,"local priority");lt=0;
  // A missing selector feedback must fault rather than repeatedly issue NEXT.
  freeze=1;timbre(2);repeat(210)@(negedge clk);
  if(!af||tnext||tr)$fatal(1,"feedback timeout");
  $display("PASS absolute target steps, cyclic wrap, local priority, switching block, feedback timeout");$finish;
 end
 initial begin #100000;$fatal(1,"watchdog");end
endmodule
