`default_nettype none
// Enables deterministic, spectrally distinct notes for on-site RTL/demo test.
module test_mode #(
  parameter int VOICES=32
) (
  input logic enable, input logic [$clog2(VOICES)-1:0] index,
  output logic force_start, output logic [6:0] midi_note
);
  logic [6:0] index_extended;
  always @* begin
    force_start=enable;
    index_extended='0; index_extended[$clog2(VOICES)-1:0]=index;
    midi_note=7'd36 + (index_extended<<1); // two semitones apart for FFT separation
  end
endmodule
`default_nettype wire
