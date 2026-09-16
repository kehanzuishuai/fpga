`default_nettype none
module tree_mixer #(
  parameter int VOICES=32, parameter int SAMPLE_W=24
) (
  input logic signed [VOICES*SAMPLE_W-1:0] samples,
  output logic signed [SAMPLE_W+$clog2(VOICES)-1:0] mixed
);
  localparam int LEVELS=$clog2(VOICES);
  // VOICES must be a power of two. Every level is explicitly parallel and
  // registers no state; a timing-constrained implementation may pipeline
  // between levels without changing the arithmetic contract.
  wire signed [SAMPLE_W+LEVELS-1:0] tree [0:LEVELS][0:VOICES-1];
  genvar i,l;
  generate
    for(i=0;i<VOICES;i=i+1) begin: G_INPUT
      assign tree[0][i] = {{LEVELS{samples[i*SAMPLE_W+SAMPLE_W-1]}},samples[i*SAMPLE_W +: SAMPLE_W]};
    end
    for(l=0;l<LEVELS;l=l+1) begin: G_LEVEL
      for(i=0;i<(VOICES>>(l+1));i=i+1) begin: G_ADD
        assign tree[l+1][i] = tree[l][2*i] + tree[l][2*i+1];
      end
    end
  endgenerate
  assign mixed=tree[LEVELS][0];
endmodule
`default_nettype wire
