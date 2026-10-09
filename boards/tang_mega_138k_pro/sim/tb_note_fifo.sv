`timescale 1ns/1ps
module tb_note_fifo #(parameter DEPTH=16,AW=$clog2(DEPTH)<1?1:$clog2(DEPTH));
 reg clk=0,rst_n=0,iv=0,ready=0;reg [17:0] payload=0;
 always #5 clk=~clk;
 wire ir,ov;wire [17:0] output_payload;wire [AW:0] level;
 note_event_fifo #(.DEPTH(DEPTH),.ADDR_W(AW)) dut(clk,rst_n,iv,ir,
 payload[17],payload[16:10],payload[9:2],payload[1:0],ov,ready,
 output_payload[17],output_payload[16:10],output_payload[9:2],output_payload[1:0],level);
 reg [17:0] expected[0:DEPTH-1];
 integer head=0,tail=0,size=0,pushed=0,popped=0,i;
 reg accepted=0,stalled=0;reg [17:0] held=0;
 reg [31:0] rng=32'hdeadbeef;
 always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin head=0;tail=0;size=0;pushed=0;popped=0;accepted=0;stalled=0;end
 else begin
   if(ov!==(size!=0) || ir!==(size<DEPTH))$fatal(1,"FIFO ready/valid level mismatch");
   if(stalled && output_payload!==held)$fatal(1,"FIFO changed stalled output");
   stalled=ov && !ready;held=output_payload;accepted=iv && ir;
   if(ov && ready)begin
     if(output_payload!==expected[head])$fatal(1,"FIFO event lost/reordered");
     head=(head+1)%DEPTH;size=size-1;popped=popped+1;
   end
   if(accepted)begin expected[tail]=payload;tail=(tail+1)%DEPTH;size=size+1;pushed=pushed+1;end
   #1;if(integer'(level)!=size)$fatal(1,"FIFO post-edge level mismatch");
 end end
 initial begin
 #1;rst_n=1;#1;rst_n=0;repeat(3)@(negedge clk);rst_n=1;
 for(i=0;i<10000;i=i+1)begin
   @(negedge clk);
   if(i==5000)begin
     rst_n=0;iv=0;ready=0;repeat(3)@(negedge clk);rst_n=1;
   end
   rng=(rng<<1)^(rng[31]?32'h04c11db7:32'd0);
   ready=(i%97<31)?0:rng[3];
   // Producer holds valid and all fields until the actual handshake.
   if(!iv || accepted)begin iv=(i<100)?1:rng[5];payload=18'(pushed*16637+913);end
 end
 @(negedge clk);iv=0;ready=1;repeat(DEPTH+3)@(negedge clk);
 if(level || pushed!=popped || pushed<100)$fatal(1,"FIFO drain/reset accounting");
 $display("PASS note FIFO depth%0d random continuous events/backpressure/full/wrap/reset, %0d events in finalepoch",DEPTH,pushed);$finish;
 end
endmodule
