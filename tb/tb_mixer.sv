`timescale 1ns/1ps
module tb_mixer;
  logic signed [32*24-1:0] samples; logic signed [28:0] sum; logic signed [23:0] clipped;
  tree_mixer #(.VOICES(32),.SAMPLE_W(24)) mix(.samples,.mixed(sum));
  saturator #(.IN_W(29),.OUT_W(24)) sat(.in(sum),.out(clipped));
  integer i;
  initial begin
    samples='0; for(i=0;i<32;i=i+1) samples[i*24 +: 24]=24'sh7f_ffff; #1;
    if(clipped!==24'sh7f_ffff) $fatal(1,"positive saturation failed");
    samples='0; for(i=0;i<32;i=i+1) samples[i*24 +: 24]=-24'sh80_0000; #1;
    if(clipped!==-24'sh80_0000) $fatal(1,"negative saturation failed");
    $display("TB_MIXER PASS: 32-way tree sum and both saturation limits"); $finish;
  end
endmodule
