"""Exact conditional negation with kept short prefix groups for display paths."""
PREFIX_MODULE='''
`default_nettype none
// -value bit i equals value[i] XOR any(value[i-1:0]). Keep small group
// boundaries so prefix reductions do not become a long LUT ripple chain.
module visual_conditional_negate #(parameter WIDTH=27,GROUP_BITS=6)(
 input wire [WIDTH-1:0] value,input wire negative,output wire [WIDTH-1:0] result
);
 localparam GROUPS=(WIDTH-1)/GROUP_BITS;
 (* syn_keep=1 *) wire [GROUPS-1:0] group_any;
 genvar g,i;
 generate for(g=0;g<GROUPS;g=g+1)begin:G
  assign group_any[g]=|value[g*GROUP_BITS+:GROUP_BITS];
 end
 for(i=0;i<WIDTH;i=i+1)begin:B
  if(i==0)assign result[i]=value[i];
  else begin:N
   localparam PREVIOUS=i/GROUP_BITS,PARTIAL=i%GROUP_BITS;
   wire lower_any;
   if(PREVIOUS==0)assign lower_any=|value[i-1:0];
   else if(PARTIAL==0)assign lower_any=|group_any[PREVIOUS-1:0];
   else assign lower_any=(|group_any[PREVIOUS-1:0]) || (|value[i-1:PREVIOUS*GROUP_BITS]);
   assign result[i]=value[i] ^ (negative && lower_any);
  end
 end endgenerate
 initial if(WIDTH<=GROUP_BITS || GROUP_BITS<1)$fatal(1,"Invalid conditional-negation prefix geometry");
endmodule
`default_nettype wire
'''

def prefix_renderer(s):
    if 'module visual_conditional_negate' in s:return s
    marker=' reg signed [26:0] wave_product_a,wave_product_b,wave_sum;'
    assert s.count(marker)==1
    s=s.replace(marker,marker+'''
 wire [26:0] wave_absolute_bits;wire [15:0] wave_restored_bits;
 visual_conditional_negate #(.WIDTH(27),.GROUP_BITS(6)) magnitude_prefix(wave_sum,wave_sum[26],wave_absolute_bits);
 visual_conditional_negate #(.WIDTH(16),.GROUP_BITS(4)) restore_prefix(wave_reciprocal[41:26],wave_reciprocal_negative,wave_restored_bits);
''',1)
    a="wave_magnitude<=21'((wave_sum<0?-wave_sum:wave_sum)>>4);wave_negative<=wave_sum<0;"
    b="wave_sample<=wave_reciprocal_negative?-16'(wave_reciprocal>>26):16'(wave_reciprocal>>26);"
    assert s.count(a)==1 and s.count(b)==1
    return s.replace(a,'wave_magnitude<=wave_absolute_bits[24:4];wave_negative<=wave_sum[26];',1).replace(b,'wave_sample<=wave_restored_bits;',1)+PREFIX_MODULE
