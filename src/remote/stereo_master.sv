`default_nettype none
// 24-bit stereo saturating mix and click-reduced volume. Unity with no WAV is
// bit-identical to the pre-integration piano signal (including DAC timing).
module stereo_master(
 input wire clk,rst_n,input wire [15:0] volume,synth_gain,
 input wire signed [23:0] synth_pcm,wav_left,wav_right,
 output wire signed [23:0] left_pcm,right_pcm,mono_pcm,output wire clipped
);
 wire signed [40:0] ps=synth_pcm*$signed({1'b0,synth_gain});
 wire signed [23:0] faded_synth=synth_gain==65535?synth_pcm:24'(ps>>>16);
 wire signed [24:0] sl={faded_synth[23],faded_synth}+{wav_left[23],wav_left};
 wire signed [24:0] sr={faded_synth[23],faded_synth}+{wav_right[23],wav_right};
 function automatic signed [23:0] clamp(input signed [24:0] x);
  if(x>8388607)clamp=24'sh7fffff;else if(x< -8388608)clamp=24'sh800000;else clamp=x[23:0];
 endfunction
 wire signed [41:0] pl=sl*$signed({1'b0,volume}),pr=sr*$signed({1'b0,volume});
 wire signed [24:0] gained_l=volume==65535?sl:25'(pl>>>16);
 wire signed [24:0] gained_r=volume==65535?sr:25'(pr>>>16);
 // The combinational outputs preserve the original frame capture edge. DSP
 // inputs are stable for hundreds of clocks between DAC frame captures.
 assign left_pcm=clamp(gained_l);
 assign right_pcm=clamp(gained_r);
 assign clipped=gained_l>8388607 || gained_l< -8388608 || gained_r>8388607 || gained_r< -8388608;
 wire signed [24:0] mono={left_pcm[23],left_pcm}+{right_pcm[23],right_pcm};
 assign mono_pcm=mono[24:1];
 wire unused=clk^rst_n;
endmodule
`default_nettype wire
