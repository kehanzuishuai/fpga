`default_nettype none
// Theremin K-1 and keyboard FX K-1 are selected before the unchanged DAC K
// capture. Keyboard timbre/score fades affect only the keyboard branch.
module live_instrument_master(
 input wire [15:0] volume,synth_gain,mode_gain,input wire [1:0] source_mode,
 input wire signed [23:0] keyboard_pcm,theremin_pcm,
 output wire signed [23:0] pcm,output wire clipped
);
 wire signed [40:0] key_product=keyboard_pcm*$signed({1'b0,synth_gain});
 wire signed [23:0] key_faded=synth_gain==65535?keyboard_pcm:24'(key_product>>>16);
 wire signed [24:0] sum={key_faded[23],key_faded}+{theremin_pcm[23],theremin_pcm};
 wire signed [24:0] half_sum=sum>>>1;
 wire signed [23:0] selected=source_mode==0?key_faded:source_mode==1?theremin_pcm:
  source_mode==2?half_sum[23:0]:24'sd0;
 wire signed [40:0] mode_product=selected*$signed({1'b0,mode_gain});
 wire signed [23:0] faded=mode_gain==65535?selected:24'(mode_product>>>16);
 wire signed [40:0] volume_product=faded*$signed({1'b0,volume});
 assign pcm=volume==65535?faded:24'(volume_product>>>16);
 // Each scale is <=unity; the 25-bit duet sum cannot wrap a 24-bit source.
 assign clipped=1'b0;
endmodule
`default_nettype wire
