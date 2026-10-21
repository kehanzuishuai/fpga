`default_nettype none
// Future integration seam. Full-gain piano path is bit-for-bit transparent.
module yinse_audio_mux(input wire [2:0] current_id,input wire [15:0] gain,
 input wire signed [23:0] piano_pcm,aux_pcm,output wire signed [23:0] pcm);
 wire signed [23:0] selected=(current_id==0)?piano_pcm:((current_id<=4)?aux_pcm:24'sd0);
 wire signed [40:0] product=selected*$signed({1'b0,gain});
 wire [16:0] unused_quantization={product[40],product[15:0]};
 assign pcm=(gain==65535)?selected:product[39:16];
endmodule
`default_nettype wire
