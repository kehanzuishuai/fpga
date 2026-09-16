`default_nettype none
// Internal event-to-Voice-sample latency.  This deliberately observes the
// newly allocated Voice rather than the global mix, so an already sounding
// Voice cannot produce a false zero-latency result.  It does not include
// sensor, CDC, FIFO backlog, I2S serialization or DAC analog latency.
module latency_monitor #(
  parameter int SAMPLE_W=24,parameter int COUNT_W=24,parameter int VOICES=32,
  parameter logic [SAMPLE_W-1:0] EFFECTIVE_THRESHOLD={{(SAMPLE_W-1){1'b0}},1'b1}
) (
  input logic clk,input logic rst_n,input logic sample_tick,
  input logic event_strobe,input logic [$clog2(VOICES)-1:0] event_voice_index,
  input logic signed [VOICES*SAMPLE_W-1:0] voice_samples,
  output logic dbg_event,output logic dbg_audio,output logic latency_valid,
  output logic [COUNT_W-1:0] latency_samples
);
  logic pending;
  logic [$clog2(VOICES)-1:0] target_index;
  logic signed [SAMPLE_W-1:0] target_sample;
  logic [SAMPLE_W-1:0] abs_target;
  always @* begin
    target_sample=voice_samples[target_index*SAMPLE_W +: SAMPLE_W];
    abs_target=target_sample[SAMPLE_W-1]?-target_sample:target_sample;
  end
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      pending<=0;target_index<='0;latency_samples<='0;latency_valid<=0;dbg_event<=0;dbg_audio<=0;
    end else begin
      dbg_event<=event_strobe;dbg_audio<=0;latency_valid<=0;
      if(event_strobe) begin
        pending<=1;target_index<=event_voice_index;latency_samples<='0;
      end else if(sample_tick&&pending) begin
        if(abs_target>=EFFECTIVE_THRESHOLD) begin
          pending<=0;latency_valid<=1;dbg_audio<=1;
        end else if(&latency_samples) begin
          pending<=0;latency_valid<=1;
        end else latency_samples<=latency_samples+1'b1;
      end
    end
  end
endmodule
`default_nettype wire
