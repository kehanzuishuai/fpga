`default_nettype none
module audio_telemetry #(
  parameter int VOICES=32, parameter int SAMPLE_W=24, parameter int DECIMATE=48
) (
  input logic clk, input logic rst_n, input logic sample_tick,
  input logic [VOICES-1:0] active_voices, input logic signed [SAMPLE_W-1:0] audio,
  output logic [$clog2(VOICES+1)-1:0] active_voice_count,
  output logic [SAMPLE_W-1:0] audio_peak,
  output logic pcm_strobe, output logic signed [SAMPLE_W-1:0] pcm_sample
);
  localparam int DW=(DECIMATE<=1)?1:$clog2(DECIMATE);
  localparam integer DECIM_LAST_INT=DECIMATE-1;
  localparam logic [DW-1:0] DECIM_LAST=DECIM_LAST_INT[DW-1:0];
  logic [DW-1:0] decim_count;
  integer i;
  logic [SAMPLE_W-1:0] abs_audio;
  always @* begin
    active_voice_count='0;
    for(i=0;i<VOICES;i=i+1) active_voice_count=active_voice_count+active_voices[i];
    abs_audio=audio[SAMPLE_W-1] ? -audio : audio;
  end
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin audio_peak<='0; decim_count<='0; pcm_strobe<=0; pcm_sample<='0; end
    else begin
      pcm_strobe<=0;
      if(sample_tick) begin
        if(abs_audio>audio_peak) audio_peak<=abs_audio;
        if(decim_count==DECIM_LAST) begin decim_count<='0; pcm_strobe<=1; pcm_sample<=audio; end
        else decim_count<=decim_count+1'b1;
      end
    end
  end
endmodule
`default_nettype wire
