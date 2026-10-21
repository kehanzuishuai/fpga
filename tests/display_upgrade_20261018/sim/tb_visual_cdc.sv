`timescale 1ns/1ps
module tb_visual_cdc;
 reg wc=0,rc=0,rst_n=0,valid=0,release_frame=0;
 always #7 wc=~wc;always #11 rc=~rc;
 reg [15:0] data=0;reg [3:0] addr=0;
 wire [15:0] q;wire pending;wire [31:0] drops;
 visual_frame_store #(.AW(4),.W(16)) dut(wc,rst_n,valid,data,drops,rc,rst_n,addr,q,pending,release_frame);
 integer n,k,base;
 initial begin
   #1;rst_n=1;#1;rst_n=0;repeat(4)@(negedge wc);rst_n=1;valid=1;
   for(n=0;n<800;n=n+1)begin @(negedge wc);data=data+1'b1;end
   valid=0;
 end
 initial begin
   wait(rst_n);wait(pending);repeat(30)@(negedge rc);
   for(k=0;k<16;k=k+1)begin
     @(negedge rc);addr=4'(k);repeat(2)@(negedge rc);
     if(k==0)base=q;
     else if(q!=base+k)$fatal(1,"torn snapshot");
     if(!pending)$fatal(1,"pending vanished without ack");
   end
   if(drops==0)$fatal(1,"slow reader drops missing");
   release_frame=1;@(negedge rc);release_frame=0;
   wait(!pending);wait(pending);
   $display("PASS asynchronous stable snapshot, full-frame drops, release and next frame");$finish;
 end
 initial begin #100000;$fatal(1,"CDC timeout");end
endmodule
