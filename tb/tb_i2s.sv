`timescale 1ns/1ps
module tb_i2s;
  logic clk=0,rst_n=0,bclk,lrclk,sd; integer edges=0;
  always #5 clk=~clk;
  i2s_tx #(.CLK_HZ(6400),.SAMPLE_RATE(100),.SAMPLE_W(8),.SLOT_W(8)) dut(.clk,.rst_n,.left_sample(8'hA5),.right_sample(8'h3C),.bclk,.lrclk,.sdata(sd));
  always @(posedge bclk) begin edges=edges+1; if(^sd===1'bx) $fatal(1,"I2S data unknown"); end
  initial begin repeat(3) @(posedge clk); rst_n=1; repeat(300) @(posedge clk); if(edges<16) $fatal(1,"I2S did not produce a frame"); $display("TB_I2S PASS: %0d BCLK sample edges",edges); $finish; end
endmodule
