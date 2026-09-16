`default_nettype none
module voice_bank #(
  parameter int VOICES=32, parameter int SAMPLE_W=24, parameter int AGE_W=32, parameter int SAMPLE_RATE=48000
) (
  input logic clk, input logic rst_n, input logic sample_tick,
  input logic note_on, input logic note_off, input logic [6:0] midi_note,
  input logic [7:0] velocity, input logic [1:0] waveform, input logic [9:0] morph,
  output logic [VOICES*SAMPLE_W-1:0] voice_samples, output logic [VOICES-1:0] voice_active
);
  localparam int IDX_W=$clog2(VOICES);
  logic [31:0] phase_inc;
  logic [VOICES*AGE_W-1:0] ages;
  logic [VOICES*7-1:0] notes;
  logic [VOICES-1:0] starts, stops;
  logic [IDX_W-1:0] chosen;
  logic grant, steal;
  logic [AGE_W-1:0] age_counter;
  integer i;
  note_freq_table #(.SAMPLE_RATE(SAMPLE_RATE)) u_note(.midi_note,.phase_inc);
  voice_allocator #(.VOICES(VOICES),.AGE_W(AGE_W)) u_alloc(.request_valid(note_on),.request_note(midi_note),.active(voice_active),.ages,.grant_valid(grant),.grant_index(chosen),.steal,.note_off_index());
  always @* begin
    i=0; starts='0; stops='0;
    if(note_on && grant) starts[chosen]=1'b1;
    if(note_off) for(i=0;i<VOICES;i=i+1) if(voice_active[i] && notes[i*7 +: 7]==midi_note) stops[i]=1'b1;
  end
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin age_counter<='0; ages<='0; end
    else if(sample_tick) begin
      if(note_on && grant) begin ages[chosen*AGE_W +: AGE_W]<=age_counter; age_counter<=age_counter+1'b1; end
    end
  end
  genvar g;
  generate for(g=0;g<VOICES;g=g+1) begin: G_VOICE
    logic [31:0] unused_inc;
    voice #(.SAMPLE_W(SAMPLE_W)) u_voice(.clk,.rst_n,.sample_tick,.start(starts[g]),.stop(stops[g]),.phase_inc_in(phase_inc),.note_in(midi_note),.velocity_in(velocity),.waveform_in(waveform),.morph_in(morph),.active(voice_active[g]),.note(notes[g*7 +: 7]),.phase_inc(unused_inc),.sample(voice_samples[g*SAMPLE_W +: SAMPLE_W]));
  end endgenerate
endmodule
`default_nettype wire
