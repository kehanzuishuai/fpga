"""Delay all scene/plot/sync outputs by the font ROM's one clock."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_renderer.sv';s=p.read_text()
A=R/'audit/display_integration_20261021/optimization';b=A/'visual_renderer.before_font_rom.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes())
s=s.replace('.x(draw_x),.y(draw_y),.peak_valid', '.clk(clk),.x(draw_x),.y(draw_y),.peak_valid')
start=s.index(' always @(posedge clk or negedge rst_n)\n if(!rst_n)begin\n  red<=0;')
end=s.index(' initial if(LOGN',start)
body=s[start:end]
assert 'if(label_ink){red,green,blue}<=text_blend(scene_color,label_color,label_coverage);' in body
body=body.replace('   if(label_ink){red,green,blue}<=text_blend(scene_color,label_color,label_coverage);\n','')
for ident in ['red','green','blue','out_de','out_hs','out_vs']:
 body=re.sub(r'\b'+ident+r'\b','base_'+ident,body)
pipeline=''' // The exact font ROM adds one cycle. Delay the complete non-text image,
 // original scene blend base and all timing signals together.
 reg [7:0] base_red,base_green,base_blue;
 reg base_out_de,base_out_hs,base_out_vs;
 reg [23:0] text_scene_q;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  red<=0;green<=0;blue<=0;out_de<=0;out_hs<=0;out_vs<=0;text_scene_q<=0;
 end else begin
  text_scene_q<=scene_color;
  out_de<=base_out_de;out_hs<=base_out_hs;out_vs<=base_out_vs;
  {red,green,blue}<=base_out_de && label_ink?
   text_blend(text_scene_q,label_color,label_coverage):{base_red,base_green,base_blue};
 end
'''
s=s[:start]+pipeline+body+s[end:];p.write_text(s)
print('Aligned all image and timing paths to synchronous exact font ROM')
