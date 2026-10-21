`default_nettype none
// Displayed volume is the applied gain, not an echo of the request. One audio-clock
// latency; gain moves at sample boundaries to avoid a hard discontinuity.
module wifi_volume #(parameter integer GAIN_STEP=256)(
 input wire clk,rst_n,sample_tick,cfg_valid,input wire [15:0] cfg_value,
 output wire cfg_ready,output reg [15:0] actual_volume,
 input wire pcm_valid,input wire signed [23:0] pcm_in,
 output reg out_valid,output reg signed [23:0] pcm_out
);
 reg [15:0] target;
 wire signed [40:0] product=$signed(pcm_in)*$signed({1'b0,actual_volume});
 assign cfg_ready=sample_tick;
 initial if(GAIN_STEP<1 || GAIN_STEP>65535)$fatal(1,"gain step");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin target<=65535;actual_volume<=65535;out_valid<=0;pcm_out<=0;end
 else begin
  if(cfg_valid && cfg_ready)target<=cfg_value;
  if(sample_tick)begin
   if(actual_volume<target)actual_volume<=17'(target)-17'(actual_volume)<=17'(GAIN_STEP)?target:actual_volume+16'(GAIN_STEP);
   else if(actual_volume>target)actual_volume<=17'(actual_volume)-17'(target)<=17'(GAIN_STEP)?target:actual_volume-16'(GAIN_STEP);
  end
  out_valid<=pcm_valid;
  if(pcm_valid)pcm_out<=actual_volume==65535?pcm_in:24'(product>>>16);
 end
endmodule
`default_nettype wire
