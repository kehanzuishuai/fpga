`default_nettype none
// Board-independent, sample-domain event-to-audio latency monitor.
module latency_monitor #(
  parameter int SAMPLE_W=24, parameter int COUNT_W=24,
  parameter logic [SAMPLE_W-1:0] AUDIBLE_THRESHOLD=24'd1024
) (
  input logic clk, input logic rst_n, input logic sample_tick,
  input logic event_strobe, input logic signed [SAMPLE_W-1:0] audio,
  output logic dbg_event, output logic dbg_audio, output logic latency_valid,
  output logic [COUNT_W-1:0] latency_samples
);
  logic pending;
  logic signed [SAMPLE_W-1:0] abs_audio;
  always @* abs_audio = audio[SAMPLE_W-1] ? -audio : audio;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin pending<=0; latency_samples<='0; latency_valid<=0; dbg_event<=0; dbg_audio<=0; end
    else begin
      dbg_event<=event_strobe; dbg_audio<=0; latency_valid<=0;
      if(event_strobe) begin pending<=1; latency_samples<='0; end
      else if(sample_tick && pending) begin
        if(abs_audio >= $signed(AUDIBLE_THRESHOLD)) begin pending<=0; latency_valid<=1; dbg_audio<=1; end
        else if(&latency_samples) begin pending<=0; latency_valid<=1; end
        else latency_samples<=latency_samples+1'b1;
      end
    end
  end
endmodule
`default_nettype wire
