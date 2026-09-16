`default_nettype none
module voice #(
  parameter int SAMPLE_W=24, parameter int PHASE_W=32
) (
  input logic clk, input logic rst_n, input logic sample_tick,
  input logic start, stop, input logic [PHASE_W-1:0] phase_inc_in,
  input logic [6:0] note_in, input logic [7:0] velocity_in,
  input logic [1:0] waveform_in, input logic [9:0] morph_in,
  output logic active, output logic [6:0] note, output logic [PHASE_W-1:0] phase_inc,
  output logic signed [SAMPLE_W-1:0] sample
);
  logic [PHASE_W-1:0] phase;
  logic [SAMPLE_W-1:0] env;
  logic signed [SAMPLE_W-1:0] sine_v, square_v, saw_v, tri_v, raw;
  logic [7:0] velocity;
  logic [9:0] effective_morph;
  logic [1:0] unused_stage;
  function automatic logic signed [SAMPLE_W-1:0] scale_audio(
    input logic signed [SAMPLE_W-1:0] audio_q23,
    input logic [SAMPLE_W-1:0] envelope_q24,
    input logic [7:0] midi_velocity
  );
    logic signed [SAMPLE_W:0] envelope_signed;
    logic signed [8:0] velocity_gain_q7;
    logic signed [2*SAMPLE_W:0] envelope_product;
    logic signed [2*SAMPLE_W+9:0] velocity_product_narrow;
    logic signed [63:0] velocity_product_full,scaled_full,positive_limit,negative_limit;
    begin
      envelope_signed=$signed({1'b0,envelope_q24});
      // Q1.7 gain: MIDI 127 maps to 128 so full velocity remains unity.
      velocity_gain_q7=(midi_velocity==8'd127)?9'sd128:$signed({1'b0,midi_velocity});
      envelope_product=audio_q23*envelope_signed;
      velocity_product_narrow=envelope_product*velocity_gain_q7;
      velocity_product_full={{(64-(2*SAMPLE_W+10)){velocity_product_narrow[2*SAMPLE_W+9]}},velocity_product_narrow};
      // Envelope Q0.SAMPLE_W followed by velocity Q1.7: constant shifts,
      // never a synthesized general divider.
      scaled_full=velocity_product_full>>>(SAMPLE_W+7);
      positive_limit=(64'sd1<<<(SAMPLE_W-1))-1;
      negative_limit=-(64'sd1<<<(SAMPLE_W-1));
      if(scaled_full>positive_limit) scale_audio={1'b0,{(SAMPLE_W-1){1'b1}}};
      else if(scaled_full<negative_limit) scale_audio={1'b1,{(SAMPLE_W-1){1'b0}}};
      else scale_audio=scaled_full[SAMPLE_W-1:0];
    end
  endfunction
  dds_phase_accum #(.PHASE_W(PHASE_W)) u_phase(.clk,.rst_n,.sample_tick,.phase_reset(start),.phase_inc,.phase);
  adsr_env #(.ENV_W(SAMPLE_W)) u_env(.clk,.rst_n,.sample_tick,.gate_on(start),.gate_off(stop),.level(env),.active,.stage(unused_stage));
  waveform_set #(.SAMPLE_W(SAMPLE_W)) u_waveforms(.phase,.sine(sine_v),.square(square_v),.saw(saw_v),.triangle(tri_v));
  always @* effective_morph=(morph_in==0)?(waveform_in*10'd341):morph_in;
  timbre_morph #(.SAMPLE_W(SAMPLE_W)) u_morph(.sine(sine_v),.square(square_v),.saw(saw_v),.triangle(tri_v),.morph(effective_morph),.sample(raw));
  always @(posedge clk or negedge rst_n)
    if(!rst_n) begin note<='0; phase_inc<='0; velocity<='0; end
    else if(start) begin note<=note_in; phase_inc<=phase_inc_in; velocity<=velocity_in; end
  always @* begin
    sample = active ? scale_audio(raw,env,velocity) : '0;
  end
endmodule
`default_nettype wire
