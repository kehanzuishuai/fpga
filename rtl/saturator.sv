`default_nettype none
module saturator #(parameter int IN_W=29, parameter int OUT_W=24) (
  input logic signed [IN_W-1:0] in, output logic signed [OUT_W-1:0] out
);
  logic signed [IN_W-1:0] max_v, min_v;
  always @* begin
    max_v=(1<<<(OUT_W-1))-1; min_v=-(1<<<(OUT_W-1));
    if(in>max_v) out={1'b0,{(OUT_W-1){1'b1}}};
    else if(in<min_v) out={1'b1,{(OUT_W-1){1'b0}}};
    else out=in[OUT_W-1:0];
  end
endmodule
`default_nettype wire
