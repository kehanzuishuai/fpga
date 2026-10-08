

module waveform_gen #(
    parameter SAMPLE_W = 24
)(
    input      [31:0]                 phase,
    input      [1:0]                  waveform,
    output reg signed [SAMPLE_W-1:0]  sample
);

wire signed [SAMPLE_W-1:0] sine;
wire signed [SAMPLE_W-1:0] square;
wire signed [SAMPLE_W-1:0] saw;
wire signed [SAMPLE_W-1:0] triangle;

waveform_set #(
    .SAMPLE_W(SAMPLE_W)
) u_set (
    .phase    (phase),
    .sine     (sine),
    .square   (square),
    .saw      (saw),
    .triangle (triangle)
);

always @(*) begin
    case (waveform)
        2'd0:    sample = sine;
        2'd1:    sample = square;
        2'd2:    sample = saw;
        default: sample = triangle;
    endcase
end

endmodule
