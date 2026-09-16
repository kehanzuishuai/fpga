`default_nettype none
module tree_mixer #(
  parameter int VOICES=32,parameter int SAMPLE_W=24
) (
  input logic signed [VOICES*SAMPLE_W-1:0] samples,
  output logic signed [SAMPLE_W+$clog2(VOICES)-1:0] mixed
);
  localparam int MIX_W=SAMPLE_W+$clog2(VOICES);
  localparam int N1=VOICES/2,N2=VOICES/4,N3=(VOICES>=8)?VOICES/8:1,N4=(VOICES>=16)?VOICES/16:1,N5=(VOICES>=32)?VOICES/32:1;
  wire signed [MIX_W-1:0] l0[0:VOICES-1];
  wire signed [MIX_W-1:0] l1[0:N1-1]; wire signed [MIX_W-1:0] l2[0:N2-1];
  wire signed [MIX_W-1:0] l3[0:N3-1]; wire signed [MIX_W-1:0] l4[0:N4-1]; wire signed [MIX_W-1:0] l5[0:N5-1];
  genvar i;
  generate
    for(i=0;i<VOICES;i=i+1) assign l0[i]={{(MIX_W-SAMPLE_W){samples[i*SAMPLE_W+SAMPLE_W-1]}},samples[i*SAMPLE_W+:SAMPLE_W]};
    for(i=0;i<N1;i=i+1) assign l1[i]=l0[2*i]+l0[2*i+1];
    for(i=0;i<N2;i=i+1) assign l2[i]=l1[2*i]+l1[2*i+1];
    if(VOICES>=8) begin:G_L3 for(i=0;i<N3;i=i+1) assign l3[i]=l2[2*i]+l2[2*i+1]; end else begin:G_NO_L3 assign l3[0]='0; end
    if(VOICES>=16) begin:G_L4 for(i=0;i<N4;i=i+1) assign l4[i]=l3[2*i]+l3[2*i+1]; end else begin:G_NO_L4 assign l4[0]='0; end
    if(VOICES>=32) begin:G_L5 for(i=0;i<N5;i=i+1) assign l5[i]=l4[2*i]+l4[2*i+1]; end else begin:G_NO_L5 assign l5[0]='0; end
    if(VOICES==4) begin:G_OUT4 assign mixed=l2[0]; end
    else if(VOICES==8) begin:G_OUT8 assign mixed=l3[0]; end
    else if(VOICES==16) begin:G_OUT16 assign mixed=l4[0]; end
    else begin:G_OUT32 assign mixed=l5[0]; end
  endgenerate
endmodule
`default_nettype wire
