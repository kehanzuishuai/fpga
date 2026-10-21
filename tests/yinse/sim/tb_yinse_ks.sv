`timescale 1ns/1ps
module tb_yinse_ks;
 reg clk=0,rst_n=0,tick=0,start=0,clear=0;always #5 clk=~clk;
 wire signed [23:0] sample;wire busy,overrun,clip;
 yinse_ks_loop ks(clk,rst_n,tick,start,clear,1'b1,11'd109,16'sd8426,sample,busy,overrun,clip);
 integer clocks=0,n=0,f;reg [2047:0] output_path;
 always @(negedge clk)begin clocks=clocks+1;tick=clocks%16==0;end
 initial begin
  if(!$value$plusargs("output=%s",output_path))output_path="sim/out/ks_raw.txt";
  f=$fopen(output_path,"w");if(!f)$fatal(1,"output missing");
  #1;rst_n=1;#1;rst_n=0;repeat(4)@(negedge clk);rst_n=1;start=1;
  @(negedge clk);start=0;repeat(140)@(negedge clk);
  $display("KS length=%0d coefficient=%0d ptr=%0d",ks.length,ks.coefficient,ks.ptr);
  while(n<4096)begin
   @(posedge clk);#1;
   if(ks.state==0 && !tick && (clocks%16)==7)begin
    $fdisplay(f,"%0d",sample);n=n+1;
    if(overrun || clip)$fatal(1,"KS status");
   end
  end
  $fclose(f);$display("PASS KS diagnostic raw trace");$finish;
 end
endmodule
