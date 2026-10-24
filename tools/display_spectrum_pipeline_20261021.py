"""Exact unsigned visible FFT address, with two additional read clocks."""
def pipeline_spectrum(s):
    import re
    old_height=re.search(r' function \[7:0\] power_height.*? endfunction',s,re.S)
    assert old_height
    s=s[:old_height.start()]+''' function [7:0] power_height(input [36:0] p);
  integer k;begin
   // Mutually exclusive highest-one terms, combined as an OR tree. Constants
   // encode3*log2 directly, avoiding a37-way priority chain followed by*3.
   power_height=0;
   for(k=1;k<37;k=k+1)
    if(p[k] && (p>>(k+1))==0)power_height=power_height | 8'(k*3);
  end
 endfunction'''+s[old_height.end():]
    # Visible domain n=(x-80)*(range+1)*4 <=64240; reciprocal error <1/55.
    assert all((n*76261)>>22==n//55 for n in range(64241))
    old=" wire [8:0] spectrum_index=9'(((32'(x)-80)*128*(32'(spectrum_range)+1))/1760);"
    assert old in s
    s=s.replace(old,''' wire [11:0] spectrum_local_x=x>=80?x-12'd80:12'd0;
 reg [15:0] spectrum_numerator;reg [32:0] spectrum_reciprocal;
 always @(posedge clk)begin
  spectrum_numerator<=16'(spectrum_local_x)*(16'(spectrum_range)+16'd1)*16'd4;
  spectrum_reciprocal<=33'(spectrum_numerator)*33'd76261;
 end
 wire [8:0] spectrum_index=9'(spectrum_reciprocal>>22);''')
    old=" wire [36:0] significant_floor=(peak_power>>12)!=0?(peak_power>>12):37'd1;"
    assert old in s
    s=s.replace(old,''' reg [24:0] significant_floor;
 // Peak stops changing before SCAN's first primed bin: one preparation clock
 // preserves the final COPY bin while removing a compare from the scan path.
 always @(posedge clk)significant_floor<=peak_power[36:12]!=0?peak_power[36:12]:25'd1;''')
    s=s.replace('wire significant=prev_count!=0 && spec_data>=significant_floor;',
        "wire significant=prev_count!=0 && ((|spec_data[36:25]) || spec_data[24:0]>=significant_floor);")
    s=s.replace('wire [7:0] spec_height=power_height(spec_data);', '''reg [7:0] spec_height;reg [15:0] pool_count;reg pool_valid;
 always @(posedge clk)begin spec_height<=power_height(spec_data);pool_count<=prev_count;end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)pool_valid<=0;else pool_valid<=state==SPEC_COPY && primed;''')
    s=s.replace("bar_index=9'(prev_count>>", "bar_index=9'(pool_count>>")
    s=s.replace('(prev_count & POOL_MASK)', '(pool_count & POOL_MASK)')
    s=s.replace('if(state==SPEC_COPY && primed && pool_last)', 'if(pool_valid && pool_last)')
    s=s.replace('    if(primed)pool_peak<=pool_value;\n', '')
    s=s.replace('  xy_start<=0;spec_release<=0;', '''  xy_start<=0;spec_release<=0;
  // The final delayed bin is pooled on SCAN's unprimed first clock, before
  // publication. Native RAM decode and max pooling have separate registers.
  if(pool_valid)pool_peak<=pool_value;''')
    return s
