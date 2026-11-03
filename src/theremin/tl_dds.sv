`default_nettype none
module tl_dds(input wire clk,rst_n,sample_tick,clear,
 input wire [31:0] phase_increment,input wire [15:0] level,input wire [15:0] frame_id,
 output reg signed [23:0] pcm,output reg valid,output reg [15:0] pcm_frame_id
);
 reg [31:0] phase;
 wire signed [15:0] sine;
 tl_sine_rom sine_lookup(phase[31:24],sine);
 wire signed [32:0] product=sine*$signed({1'b0,level});
 wire [8:0] unused_quantization={product[32],product[7:0]};
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin phase<=0;pcm<=0;valid<=0;pcm_frame_id<=0;end
 else begin
  valid<=0;
  if(clear)begin phase<=0;pcm<=0;end
  else if(sample_tick)begin phase<=phase+phase_increment;pcm<=product[31:8];valid<=1;pcm_frame_id<=frame_id;end
 end
endmodule
`default_nettype wire
