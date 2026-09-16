`default_nettype none
// Linear, continuous crossfade between adjacent oscillator shapes.
module timbre_morph #(
  parameter int SAMPLE_W = 24
) (
  input logic signed [SAMPLE_W-1:0] sine, square, saw, triangle,
  input logic [9:0] morph, // 0=sine, 341=square, 682=saw, 1023=triangle
  output logic signed [SAMPLE_W-1:0] sample
);
  localparam int CALC_W=SAMPLE_W+13;
  logic signed [SAMPLE_W-1:0] a,b;
  logic [9:0] frac;
  logic signed [SAMPLE_W:0] delta;
  logic signed [11:0] frac_signed;
  logic signed [CALC_W-1:0] product,a_extended,interpolated,max_sample,min_sample;
  always @* begin
    if(morph==0) begin a=sine; b=sine; frac=0; end
    else if(morph==10'd1023) begin a=triangle; b=triangle; frac=0; end
    else if(morph < 10'd341) begin a=sine; b=square; frac=morph*3; end
    else if(morph < 10'd682) begin a=square; b=saw; frac=(morph-341)*3; end
    else begin a=saw; b=triangle; frac=(morph-682)*3; end
    // a + (b-a)*frac uses one multiplier instead of two.  frac is Q0.10,
    // so the former /1023 is replaced by a deterministic arithmetic shift.
    delta=$signed({b[SAMPLE_W-1],b})-$signed({a[SAMPLE_W-1],a});
    frac_signed=$signed({2'b00,frac});
    product=delta*frac_signed;
    a_extended={{(CALC_W-SAMPLE_W){a[SAMPLE_W-1]}},a};
    interpolated=a_extended+(product>>>10);
    max_sample=($signed({{(CALC_W-1){1'b0}},1'b1})<<<(SAMPLE_W-1))-1'b1;
    min_sample=-($signed({{(CALC_W-1){1'b0}},1'b1})<<<(SAMPLE_W-1));
    if(morph==0) sample=sine;
    else if(morph==10'd1023) sample=triangle;
    else if(interpolated>max_sample) sample={1'b0,{(SAMPLE_W-1){1'b1}}};
    else if(interpolated<min_sample) sample={1'b1,{(SAMPLE_W-1){1'b0}}};
    else sample=interpolated[SAMPLE_W-1:0];
  end
endmodule
`default_nettype wire
