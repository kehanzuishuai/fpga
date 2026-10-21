`timescale 1ns/1ps
module tb_tmds_receiver;
 reg clk=0,rst_n=0,de=0,hs=1,vs=1;reg [23:0] rgb=0;reg [2:0] fault=0;
 always #20 clk=~clk;
 wire [9:0] r,g,b;
 visual_tmds er(clk,rst_n,de,2'b00,rgb[23:16],r);
 visual_tmds eg(clk,rst_n,de,2'b00,rgb[15:8],g);
 visual_tmds eb(clk,rst_n,de,{vs,hs},rgb[7:0],b);
 wire [9:0] cr=(fault==1)?g:((fault==2)?(r^10'd1):r);
 wire [9:0] cb=(fault==3)?10'b0010101011:b;
 wire rd;wire [7:0] rr,rg,rb;integer pixels,blanks,errors,i,previous;
 tmds_stream_checker #(.FATAL_ON_ERROR(0)) rx(clk,rst_n,de,hs,vs,rgb[23:16],rgb[15:8],rgb[7:0],
 cr,g,cb,rd,rr,rg,rb,pixels,blanks,errors);
 initial begin
 #1;rst_n=1;#1;rst_n=0;repeat(3)@(negedge clk);rst_n=1;
 for(i=0;i<4096;i=i+1)begin
   @(negedge clk);de=(i%37)<31;hs=(i%7)!=0;vs=(i%11)!=0;
   rgb=24'(i*32'h123457)^24'hfe0123;
 end
 @(negedge clk);if(errors || pixels<1000 || blanks<100)$fatal(1,"receiver false positive");
 de=1;rgb=24'h123456;
 for(i=1;i<=2;i=i+1)begin
   repeat(2)@(negedge clk);previous=errors;fault=3'(i);
   repeat(2)@(negedge clk);fault=0;
   if(errors<=previous)$fatal(1,"receiver missed lane/bit fault");
 end
 de=0;hs=0;vs=1;previous=errors;fault=3;
 repeat(2)@(negedge clk);fault=0;
 if(errors<=previous)$fatal(1,"receiver missed blank control fault");
 rst_n=0;#1;if(pixels || errors || rd)$fatal(1,"receiver reset");
 repeat(3)@(negedge clk);rst_n=1;de=1;
 repeat(10)@(negedge clk);if(errors || pixels<9)$fatal(1,"receiver recovery");
 rst_n=0;repeat(3)@(negedge clk);rst_n=1;de=0;
 repeat(5)@(negedge clk);if(errors || blanks<4)$fatal(1,"blank reset recovery");
 $display("PASS independent TMDS receiver RGB/control/disparity, lane/bit/control fault sensitivity and reset");$finish;
 end
endmodule
