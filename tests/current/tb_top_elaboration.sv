`timescale 1ns/1ps
// Elaboration only: vendor memory models look up this global-reset instance.
module tb_top_elaboration;
 GSR GSR(.GSRI(1'b1));
 tang_mega_138k_pro_top dut(.clk_50m(1'b0),.rst_n(1'b0));
endmodule
