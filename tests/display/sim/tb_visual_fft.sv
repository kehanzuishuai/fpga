`timescale 1ns/1ps
module tb_visual_fft;
 parameter LOGN=11,WINDOW=1;
 localparam N=1<<LOGN;
 reg clk=0,rst_n=0,valid=0;reg signed [15:0] sample=0;
 always #5 clk=~clk;
 wire [31:0] dropped;wire bv;wire [LOGN-2:0] idx;
 wire signed [17:0] re,im;wire [36:0] power_value;
 visual_fft #(.LOGN(LOGN),.WINDOW(WINDOW)) dut(clk,rst_n,valid,sample,dropped,bv,idx,re,im,power_value);
 reg [15:0] stimulus[0:4*N-1];
 integer output_file,frames=0,expected_idx=0,i,f,cycles=0,last_input=0;
 always @(posedge clk) begin
   cycles=cycles+1;
   if(bv)begin
     if(idx!=expected_idx) $fatal(1,"bin order");
     $fdisplay(output_file,"%0d %0d %0d %0d %0d",frames,idx,re,im,power_value);
     if(idx==N/2-1)begin
       $display("FFT frame %0d complete; %0d clocks after final input",frames,cycles-last_input);
       frames=frames+1;expected_idx=0;
     end else expected_idx=expected_idx+1;
   end
 end
 initial begin
   output_file=$fopen("sim_out_visual/fft_rtl.txt","w");
   $readmemh("sim_out_visual/fft_input.hex",stimulus);
   #1;rst_n=1;#1;rst_n=0;repeat(4)@(negedge clk);rst_n=1;
   for(f=0;f<4;f=f+1)begin
     for(i=0;i<N;i=i+1)begin
       @(negedge clk);sample=stimulus[f*N+i];valid=1;
       @(negedge clk);valid=0;repeat(254)@(negedge clk);
     end
     last_input=cycles;
     wait(frames==f+1);repeat(10)@(negedge clk);
   end
   if(dropped!=0)$fatal(1,"FFT drops at normal rate");
   // Busy acquisition overload: producer must keep running, report whole drops.
   for(i=0;i<4*N;i=i+1)begin @(negedge clk);valid=1;sample=16'(i);end
   @(negedge clk);valid=0;
   if(dropped==0)$fatal(1,"overload not reported");
   rst_n=0;#1;if(bv!==0)$fatal(1,"FFT reset");
   $fclose(output_file);$display("PASS FFT streaming, ordered bins, overload accounting, reset");$finish;
 end
 initial begin #100000000;$fatal(1,"FFT timeout");end
endmodule
