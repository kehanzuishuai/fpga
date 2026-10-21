from pathlib import Path
R=Path(__file__).resolve().parents[2];p=R/'src/display/piano_status_overlay.sv';s=p.read_text()
params=s[s.index('#(')+2:s.index(')(input')]
bindings=','.join(f'.{n}({n})' for n in ['MAPPING_CONFIRMED','INFO_Y','DETAIL_Y','KEY_X','KEY_Y','KEY_PITCH','KEY_WIDTH','KEY_HEIGHT'])
fa=s.index(' function automatic [34:0] glyph');fb=s.index(' integer noteclass;',fa) if ' integer noteclass;' in s[fa:] else s.index(' reg [5:0] pos;',fa)
glyph=s[fa:fb]
start=s.index(' wire [15:0] keys');end=s.index('endmodule',start)
decoder=s[start:fa]+s[fb:end]
decoder=decoder.replace('reg [2:0] col,row;integer noteclass;reg [7:0] ch;reg [34:0] bits;','integer noteclass;')
decoder=decoder.replace('  bits=glyph(ch);ink=0;\n  if(col<5 && row<7)ink=bits[6\'d34-({3\'d0,row}*6\'d5+{3\'d0,col})];\n','')
assert 'bits=' not in decoder
common=f'''`default_nettype none
// Keep the combinational interface for existing HUD verification and previews.
module piano_status_overlay #({params})(input wire [9:0] x,y,input wire [57:0] status,
 output wire ink,key_area,key_on);
 wire [7:0] ch;wire [2:0] col,row;wire [34:0] bits;
 piano_status_decode #({bindings}) decode(x,y,status,ch,col,row,key_area,key_on);
 piano_status_font font(ch,bits);
 assign ink=col<5 && row<7?bits[6'd34-({{3'd0,row}}*6'd5+{{3'd0,col}})]:1'b0;
endmodule
// Production path: register character decode and then glyph lookup.
module piano_status_overlay_pipeline #({params})(input wire [9:0] x,y,input wire [57:0] status,
 input wire clk,rst_n,output wire ink,output reg key_area,key_on);
 wire [7:0] ch;wire [2:0] col,row;wire area,on;wire [34:0] glyph_bits;
 reg [7:0] char_d;reg [2:0] col_d,row_d;reg area_d,on_d;
 reg [34:0] bits_d;reg [5:0] index_d;reg valid_d;
 piano_status_decode #({bindings}) decode(x,y,status,ch,col,row,area,on);
 piano_status_font font(char_d,glyph_bits);
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  char_d<=32;col_d<=0;row_d<=0;area_d<=0;on_d<=0;
  bits_d<=0;index_d<=0;valid_d<=0;key_area<=0;key_on<=0;
 end else begin
  char_d<=ch;col_d<=col;row_d<=row;area_d<=area;on_d<=on;
  bits_d<=glyph_bits;index_d<=6'd34-({{3'd0,row_d}}*6'd5+{{3'd0,col_d}});
  valid_d<=col_d<5 && row_d<7;key_area<=area_d;key_on<=on_d;
 end
 assign ink=valid_d?bits_d[index_d]:1'b0;
endmodule
module piano_status_font(input wire [7:0] ch,output wire [34:0] bits);
{glyph}
 assign bits=glyph(ch);
endmodule
module piano_status_decode #({params})(input wire [9:0] x,y,input wire [57:0] status,
 output reg [7:0] ch,output reg [2:0] col,row,output wire key_area,key_on);
{decoder}
endmodule
`default_nettype wire
'''
p.write_text(common)
p=R/'src/display/audio_visualizer.sv';s=p.read_text().replace('piano_status_overlay #(','piano_status_overlay_pipeline #(').replace('sx4,sy4,status_pixel,status_ink,key_area,key_on);','sx4,sy4,status_pixel,pixel_clk,display_rst_n,status_ink,key_area,key_on);')
s=s.replace(' reg status_ink_d,key_area_d,key_on_d;','')
s=s.replace('  status_ink_d<=0;key_area_d<=0;key_on_d<=0;','').replace('  status_ink_d<=status_ink;key_area_d<=key_area;key_on_d<=key_on;','')
s=s.replace('wire show_text=STATUS_ENABLE!=0 && status_ink_d;','wire show_text=STATUS_ENABLE!=0 && status_ink;').replace('wire show_key=STATUS_ENABLE!=0 && key_area_d;','wire show_key=STATUS_ENABLE!=0 && key_area;').replace('key_on_d?','key_on?')
s=s.replace(' reg render_de_d,render_hs_d,render_vs_d;',''' reg render_de_d,render_hs_d,render_vs_d;
 reg [7:0] render_r_d2,render_g_d2,render_b_d2;
 reg render_de_d2,render_hs_d2,render_vs_d2;''')
s=s.replace('  render_de_d<=0;render_hs_d<=0;render_vs_d<=0;','''  render_de_d<=0;render_hs_d<=0;render_vs_d<=0;
  render_r_d2<=0;render_g_d2<=0;render_b_d2<=0;
  render_de_d2<=0;render_hs_d2<=0;render_vs_d2<=0;''')
s=s.replace('  render_de_d<=render_de;render_hs_d<=render_hs;render_vs_d<=render_vs;','''  render_de_d<=render_de;render_hs_d<=render_hs;render_vs_d<=render_vs;
  render_r_d2<=render_r_d;render_g_d2<=render_g_d;render_b_d2<=render_b_d;
  render_de_d2<=render_de_d;render_hs_d2<=render_hs_d;render_vs_d2<=render_vs_d;''')
s=s.replace('de_d<=render_de_d;hs_d<=render_hs_d;vs_d<=render_vs_d;','de_d<=render_de_d2;hs_d<=render_hs_d2;vs_d<=render_vs_d2;')
for c in ['r','g','b']:s=s.replace(f'):render_{c}_d);',f'):render_{c}_d2);')
p.write_text(s)
