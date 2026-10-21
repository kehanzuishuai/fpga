from pathlib import Path
R=Path(__file__).resolve().parents[2]
p=R/'src/display/visual_labels.sv';s=p.read_text()
s=s.replace('input integer position','input [3:0] position')
s=s.replace('integer pos,col,row;','reg [4:0] pos;reg [3:0] col,row;\n reg [15:0] char_d;reg [3:0] col_d,row_d;\n reg [143:0] bits_d;reg [7:0] index_d;reg valid_d;')
s=s.replace("32'(x)","10'(x)").replace("32'(y)","10'(y)")
import re
s=re.sub(r"\(10'\(x\)-(\d+)\)/12",r"(10'(x)-10'd\1)/10'd12",s)
s=re.sub(r"\(10'\(x\)-(\d+)\)%12",r"(10'(x)-10'd\1)%10'd12",s)
s=s.replace('   bits=glyph(ch);ink=0;\n   if(col<12 && row<12)ink=bits[143-(row*12+col)];','')
s=s.replace('endmodule','''// Split character selection, glyph lookup, and pixel selection. All three
 // stages advance for every pixel, including blanking.
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin char_d<=32;col_d<=0;row_d<=0;bits_d<=0;index_d<=0;valid_d<=0;end
 else begin
  char_d<=ch;col_d<=col;row_d<=row;
  bits_d<=glyph(char_d);
  index_d<=8'd143-({4'd0,row_d}*8'd12+{4'd0,col_d});
  valid_d<=col_d<12 && row_d<12;
 end
 always @* ink=valid_d?bits_d[index_d]:1'b0;
endmodule''')
p.write_text(s)
p=R/'src/display/visual_renderer.sv';s=p.read_text()
s=s.replace(' wire label_ink;',''' reg [7:0] base_r,base_g,base_b,delay_r,delay_g,delay_b;
 reg base_de,base_hs,base_vs,delay_de,delay_hs,delay_vs;
 wire label_ink;''')
start=s.index(' always @(posedge clk or negedge rst_n)',s.index(' wire label_ink;'))
a=s[:start];b=s[start:]
for old,new in [('red<=','base_r<='),('green<=','base_g<='),('blue<=','base_b<='),('out_de<=','base_de<='),('out_hs<=','base_hs<='),('out_vs<=','base_vs<=')]:b=b.replace(old,new)
b=b.replace('   if(label_ink)begin base_r<=180;base_g<=210;base_b<=224;end','')
b=b.replace(' initial if(LOGN', ''' // Match the two label lookup stages with graphics and raster controls.
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  delay_r<=0;delay_g<=0;delay_b<=0;delay_de<=0;delay_hs<=0;delay_vs<=0;
  red<=0;green<=0;blue<=0;out_de<=0;out_hs<=0;out_vs<=0;
 end else begin
  delay_r<=base_r;delay_g<=base_g;delay_b<=base_b;
  delay_de<=base_de;delay_hs<=base_hs;delay_vs<=base_vs;
  red<=delay_de && label_ink?8'd180:delay_r;
  green<=delay_de && label_ink?8'd210:delay_g;
  blue<=delay_de && label_ink?8'd224:delay_b;
  out_de<=delay_de;out_hs<=delay_hs;out_vs<=delay_vs;
 end
 initial if(LOGN''')
p.write_text(a+b)
p=R/'src/display/audio_visualizer.sv';s=p.read_text().replace('its two pipeline stages','its four pipeline stages').replace('sx1,sy1,sx2,sy2;','sx1,sy1,sx2,sy2,sx3,sy3,sx4,sy4;').replace('sx2<=0;sy2<=0;','sx2<=0;sy2<=0;sx3<=0;sy3<=0;sx4<=0;sy4<=0;').replace('sx2<=sx1;sy2<=sy1;','sx2<=sx1;sy2<=sy1;sx3<=sx2;sy3<=sy2;sx4<=sx3;sy4<=sy3;').replace(' sx2,sy2,status_pixel',' sx4,sy4,status_pixel');p.write_text(s)
p=R/'tests/display_upgrade_20261018/run_checks.py';s=p.read_text().replace("    p.write_text(s,encoding='utf8')","    if p.name=='tb_renderer_1080.sv':s=s.replace('repeat(2)@(negedge clk)','repeat(4)@(negedge clk)')\n    p.write_text(s,encoding='utf8')");p.write_text(s)
p=R/'tests/display_upgrade_20261018/sim/tb_renderer_1080.sv';s=p.read_text().replace('repeat(2)@(negedge clk)','repeat(4)@(negedge clk)');p.write_text(s)
