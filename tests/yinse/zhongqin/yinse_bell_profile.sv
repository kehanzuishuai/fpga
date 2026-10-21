`default_nettype none
// One FM pair: ratio ~sqrt(2); independent exponential modulation decay.
module yinse_bell_profile(input wire [31:0] increment,
 output wire [31:0] mod_increment);
 wire [63:0] ratio_product={32'd0,increment}*64'd92682;
 wire [31:0] unused_quantization={ratio_product[63:48],ratio_product[15:0]};
 assign mod_increment=ratio_product[47:16]; // Q16.16 ratio 1.414215
endmodule
`default_nettype wire
