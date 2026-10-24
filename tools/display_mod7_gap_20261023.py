"""Exact modulo7 separator using four base8 digits (8 == 1 modulo7)."""
def gap_module():
 return '''`default_nettype none
module visual_mod7_gap(input wire [11:0] value,output wire gap);
 (* syn_keep=1 *) wire [3:0] low_pair={1'b0,value[2:0]}+{1'b0,value[5:3]};
 (* syn_keep=1 *) wire [3:0] high_pair={1'b0,value[8:6]}+{1'b0,value[11:9]};
 wire [4:0] digit_sum={1'b0,low_pair}+{1'b0,high_pair};
 assign gap=digit_sum==5'd6 || digit_sum==5'd13 || digit_sum==5'd20 || digit_sum==5'd27;
endmodule
`default_nettype wire
'''

def shorten_mod7(source):
 if 'module visual_mod7_gap' in source:return source
 old="grid_x1%12'd7!=6";assert source.count(old)==1
 marker=' reg [16:0] gradient_r2,gradient_g2,gradient_b2;';assert source.count(marker)==1
 source=source.replace(marker,''' wire spectrum_separator;
 visual_mod7_gap separator_gap(grid_x1,spectrum_separator);
'''+marker)
 return source.replace(old,'!spectrum_separator')+'\n'+gap_module()
