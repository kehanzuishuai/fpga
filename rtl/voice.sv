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
  logic [1:0] env_stage;
  logic signed [SAMPLE_W-1:0] sine_v, square_v, saw_v, tri_v, raw;
  logic [7:0] velocity;
  logic signed [2*SAMPLE_W-1:0] product;
  logic signed [SAMPLE_W-1:0] env_sample;
  logic signed [SAMPLE_W+7:0] velocity_product;
  dds_phase_accum #(.PHASE_W(PHASE_W)) u_phase(.clk,.rst_n,.sample_tick,.phase_reset(start),.phase_inc,.phase);
  adsr_env #(.ENV_W(SAMPLE_W)) u_env(.clk,.rst_n,.sample_tick,.gate_on(start),.gate_off(stop),.level(env),.active,.stage(env_stage));
  waveform_gen #(.SAMPLE_W(SAMPLE_W)) u_sine(.phase,.waveform(2'd0),.sample(sine_v));
  waveform_gen #(.SAMPLE_W(SAMPLE_W)) u_square(.phase,.waveform(2'd1),.sample(square_v));
  waveform_gen #(.SAMPLE_W(SAMPLE_W)) u_saw(.phase,.waveform(2'd2),.sample(saw_v));
  waveform_gen #(.SAMPLE_W(SAMPLE_W)) u_tri(.phase,.waveform(2'd3),.sample(tri_v));
  timbre_morph #(.SAMPLE_W(SAMPLE_W)) u_morph(.sine(sine_v),.square(square_v),.saw(saw_v),.triangle(tri_v),.morph(morph_in),.sample(raw));
  always @(posedge clk or negedge rst_n)
    if(!rst_n) begin note<='0; phase_inc<='0; velocity<='0; end
    else if(start) begin note<=note_in; phase_inc<=phase_inc_in; velocity<=velocity_in; end
  always @* begin
    product = raw * $signed({1'b0,env});
    env_sample = product >>> (SAMPLE_W-1);
    velocity_product = env_sample * $signed({1'b0,velocity});
    sample = active ? (velocity_product >>> 7) : '0;
  end
endmodule
`default_nettype wire
