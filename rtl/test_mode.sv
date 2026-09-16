`default_nettype none
// Enables deterministic, spectrally distinct notes for on-site RTL/demo test.
module test_mode #(
  parameter int VOICES=32
) (
  input logic enable, input logic [$clog2(VOICES)-1:0] index,
  output logic force_start, output logic [6:0] midi_note
);
  always @* begin
    force_start=enable;
    midi_note=7'd36 + index; // C2 upward: 32 distinct equal-tempered pitches
  end
endmodule
`default_nettype wire
