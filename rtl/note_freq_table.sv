`default_nettype none
// MIDI note number to 32-bit DDS phase increment. Values are calculated for
// C4..B4 at 48 kHz, then octave shifted and sample-rate scaled at elaboration.
module note_freq_table #(
  parameter int SAMPLE_RATE = 48000,
  parameter int REFERENCE_SAMPLE_RATE = 48000
) (
  input  logic [6:0] midi_note,
  output logic [31:0] phase_inc
);
  function automatic [31:0] c4_semitone(input logic [3:0] n);
    case (n)
      0: c4_semitone=32'd23409859;  1: c4_semitone=32'd24801882;
      2: c4_semitone=32'd26276679;  3: c4_semitone=32'd27839171;
      4: c4_semitone=32'd29494575;  5: c4_semitone=32'd31248413;
      6: c4_semitone=32'd33106541;  7: c4_semitone=32'd35075158;
      8: c4_semitone=32'd37160835;  9: c4_semitone=32'd39370534;
      10:c4_semitone=32'd41711627; default:c4_semitone=32'd44191930;
    endcase
  endfunction
  integer octave;
  integer semitone;
  logic [63:0] scaled;
  always @* begin
    octave = midi_note / 12;
    semitone = midi_note % 12;
    scaled = ({32'd0,c4_semitone(semitone)} * REFERENCE_SAMPLE_RATE) / SAMPLE_RATE;
    if (octave >= 5) phase_inc = scaled << (octave - 5);
    else             phase_inc = scaled >> (5 - octave);
  end
endmodule
`default_nettype wire
