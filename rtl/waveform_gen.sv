`default_nettype none
module waveform_gen #(parameter int SAMPLE_W=24) (
  input logic [31:0] phase,input logic [1:0] waveform,
  output logic signed [SAMPLE_W-1:0] sample
);
  logic signed [SAMPLE_W-1:0] sine,square,saw,triangle;
  waveform_set #(.SAMPLE_W(SAMPLE_W)) u_set(.phase,.sine,.square,.saw,.triangle);
  always @* begin
    case(waveform)
      2'd0:sample=sine;2'd1:sample=square;2'd2:sample=saw;default:sample=triangle;
    endcase
  end
endmodule
`default_nettype wire
