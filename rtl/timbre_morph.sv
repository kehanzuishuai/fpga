`default_nettype none
// Linear, continuous crossfade between adjacent oscillator shapes.
module timbre_morph #(
  parameter int SAMPLE_W = 24
) (
  input logic signed [SAMPLE_W-1:0] sine, square, saw, triangle,
  input logic [9:0] morph, // 0=sine, 341=square, 682=saw, 1023=triangle
  output logic signed [SAMPLE_W-1:0] sample
);
  logic signed [SAMPLE_W-1:0] a,b;
  logic [9:0] frac;
  logic signed [SAMPLE_W+10:0] blend;
  always @* begin
    if(morph==0) begin a=sine; b=sine; frac=0; end
    else if(morph==10'd1023) begin a=triangle; b=triangle; frac=0; end
    else if(morph < 10'd341) begin a=sine; b=square; frac=morph*3; end
    else if(morph < 10'd682) begin a=square; b=saw; frac=(morph-341)*3; end
    else begin a=saw; b=triangle; frac=(morph-682)*3; end
    blend = a * $signed({1'b0,10'd1023-frac}) + b * $signed({1'b0,frac});
    if(morph==0) sample=sine;
    else if(morph==10'd1023) sample=triangle;
    else sample = blend >>> 10;
  end
endmodule
`default_nettype wire
