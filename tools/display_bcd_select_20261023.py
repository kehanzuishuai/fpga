"""Bound decimal-place selection to the five existing BCD digits."""
def select_bcd(s):
    if 'function automatic [3:0] selected_bcd_digit' in s:return s
    marker='reg [31:0] numeric_value;integer numeric_place;';assert s.count(marker)==1
    s=s.replace(marker,'reg [31:0] numeric_value;reg [2:0] numeric_place;',1)
    start=s.index(" wire [15:0] digit_value=16'd48+16'(numeric_bcd[numeric_place*4+:4]);")
    end=s.index('\n\n always_comb begin',start)
    original=s[start:end]
    assert 'trimmed_value=' in original
    replacement=''' function automatic [3:0] selected_bcd_digit(input [19:0] value,input [2:0] place);
 begin case(place)
  0:selected_bcd_digit=value[3:0];1:selected_bcd_digit=value[7:4];
  2:selected_bcd_digit=value[11:8];3:selected_bcd_digit=value[15:12];
  4:selected_bcd_digit=value[19:16];default:selected_bcd_digit=0;
 endcase end endfunction
 function automatic bcd_digit_visible(input [19:0] value,input [2:0] place);
 begin case(place)
  1:bcd_digit_visible=|value[19:4];2:bcd_digit_visible=|value[19:8];
  3:bcd_digit_visible=|value[19:12];4:bcd_digit_visible=|value[19:16];
  default:bcd_digit_visible=1;
 endcase end endfunction
 wire [15:0] digit_value={12'd3,selected_bcd_digit(numeric_bcd,numeric_place)};
 wire [15:0] trimmed_value=bcd_digit_visible(numeric_bcd,numeric_place)?digit_value:16'd32;'''
    return s[:start]+replacement+s[end:]
