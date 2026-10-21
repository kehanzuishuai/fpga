`default_nettype none
// One FM pair: ratio ~sqrt(2); independent exponential modulation decay.
module yinse_bell_profile(input wire [31:0] increment,
 output wire [31:0] mod_increment);
 // Exact constant 92682 = 2^16+2^14+2^13+2^11+2^9+2^3+2^1.
 // Explicit additions avoid Gowin allocating a wide DSP for a constant ratio.
 wire [63:0] inc_w={32'd0,increment};
 wire [63:0] ratio_product=(inc_w<<16)+(inc_w<<14)+(inc_w<<13)+
                          (inc_w<<11)+(inc_w<<9)+(inc_w<<3)+(inc_w<<1);
 wire [31:0] unused_quantization={ratio_product[63:48],ratio_product[15:0]};
 assign mod_increment=ratio_product[47:16]; // Q16.16 ratio 1.414215
endmodule
`default_nettype wire
