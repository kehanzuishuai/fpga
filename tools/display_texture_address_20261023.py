"""Exact row/column quotient decomposition in the existing two address clocks."""
def retime_texture_address(s):
    if 'module visual_texture_address' in s:return s
    marker=' wire [31:0] even_x=';a=s.index(marker);b=s.index(' function automatic [23:0] select_q',a)
    replacement=''' wire [31:0] address00,address01,address10,address11;
 visual_texture_address #(.BW(BW),.WORDS(WORDS)) addresses(
  clk,gx,gy,address00,address01,address10,address11);
 visual_texture_rom24_packed #(.WORDS(WORDS),.FILE(FILE0),.REGISTER_ADDR(2)) rom0(clk,address00,q0);
 visual_texture_rom24_packed #(.WORDS(WORDS),.FILE(FILE1),.REGISTER_ADDR(2)) rom1(clk,address01,q1);
 visual_texture_rom24_packed #(.WORDS(WORDS),.FILE(FILE2),.REGISTER_ADDR(2)) rom2(clk,address10,q2);
 visual_texture_rom24_packed #(.WORDS(WORDS),.FILE(FILE3),.REGISTER_ADDR(2)) rom3(clk,address11,q3);
'''
    s=s[:a]+replacement+s[b:]
    old="wire [AW+1:0] word_addr=REGISTER_ADDR!=0?{2'b0,address_delayed}+{2'b0,quotient}:scaled/(AW+2)'(3);"
    assert s.count(old)==1
    s=s.replace(old,"wire [AW+1:0] word_addr=REGISTER_ADDR==2?addr[AW+3:2]:REGISTER_ADDR!=0?{2'b0,address_delayed}+{2'b0,quotient}:scaled/(AW+2)'(3);",1)
    old="wire [1:0] residue=REGISTER_ADDR!=0?2'(address_delayed)-2'(quotient)-{quotient[0],1'b0}:local_addr%AW'(3);"
    assert s.count(old)==1
    s=s.replace(old,"wire [1:0] residue=REGISTER_ADDR==2?addr[1:0]:REGISTER_ADDR!=0?2'(address_delayed)-2'(quotient)-{quotient[0],1'b0}:local_addr%AW'(3);",1)
    return s+'''
`default_nettype none
// Clock0 registers exact quotients/remainders from small constant tables.
// Clock1 adds them and carries the remainder. The native ROM still reads
// on clock2, so the texture plane keeps its original six-clock latency.
module visual_texture_address #(parameter BW=121,WORDS=8228)(
 input wire clk,input wire [8:0] gx,input wire [7:0] gy,
 output reg [31:0] address00,address01,address10,address11);
 localparam AW=$clog2(WORDS)>0?$clog2(WORDS):1;
 (* syn_romstyle="logic" *) reg [AW+1:0] even_rows[0:255],odd_rows[0:255];
 (* syn_romstyle="logic" *) reg [AW+1:0] even_columns[0:511],odd_columns[0:511];
 reg [AW+1:0] row_even_q,row_odd_q,column_even_q,column_odd_q;
 function automatic [AW+1:0] divided(input integer value);
 begin divided={AW'(value/3),2'(value%3)};end endfunction
 function automatic [AW+3:0] encode(input [AW+1:0] a,b);
 reg [2:0] residual_sum;reg [1:0] residual;reg carry;reg [AW-1:0] quotient;
 begin
  residual_sum={1'b0,a[1:0]}+{1'b0,b[1:0]};
  carry=residual_sum>=3;residual=carry?2'(residual_sum-3):residual_sum[1:0];
  quotient=a[AW+1:2]+b[AW+1:2]+AW'(carry);
  // Packed word=floor(4*texel/3)={quotient,residual}; append residue
  // separately because the ROM also needs it to select the24-bit slice.
  encode={quotient,residual,residual};
 end endfunction
 integer index;
 initial begin
  for(index=0;index<256;index=index+1)begin
   even_rows[index]=divided(((index+(index&1))/2)*BW);
   odd_rows[index]=divided((index/2)*BW);
  end
  for(index=0;index<512;index=index+1)begin
   even_columns[index]=divided((index+(index&1))/2);
   odd_columns[index]=divided(index/2);
  end
 end
 always @(posedge clk)begin
  row_even_q<=even_rows[gy];row_odd_q<=odd_rows[gy];
  column_even_q<=even_columns[gx];column_odd_q<=odd_columns[gx];
  address00<=32'(encode(row_even_q,column_even_q));
  address01<=32'(encode(row_even_q,column_odd_q));
  address10<=32'(encode(row_odd_q,column_even_q));
  address11<=32'(encode(row_odd_q,column_odd_q));
 end
endmodule
`default_nettype wire
'''
