"""Bound working colors; keep signed fades and final channel clamps exact."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];A=R/'audit/display_integration_20261021/optimization'
p=R/'src/display/visual_scene.sv';s=p.read_text();b=A/'visual_scene.before_color_bounds.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes())
s=s.replace(' integer sx,sy,rr,gg,bb,',' reg signed [11:0] rr,gg,bb;\n integer sx,sy,')
s=s.replace('function automatic [95:0] guidance(input [95:0] original','function automatic [35:0] guidance(input [35:0] original')
for color in ['222,139,131','255,224,159','255,221,148']:
 values=color.split(',');old='{'+','.join("32'd"+v for v in values)+'}'
 new='{'+','.join("12'd"+v for v in values)+'}'
 assert old in s;s=s.replace(old,new)
for color in ['rr','gg','bb']:s=s.replace(color+'[31:8]',color+'[11:8]')
p.write_text(s)
p=R/'src/display/visual_renderer.sv';s=p.read_text();b=A/'visual_renderer.before_blend_bounds.sv';b.write_bytes(p.read_bytes())
old='''  integer c;begin
   for(c=0;c<3;c=c+1)text_blend[c*8+:8]=8'((32'(base_color[c*8+:8])*(3-32'(coverage))+
    32'(foreground[c*8+:8])*32'(coverage)+1)/3);
  end'''
new='''  integer c;reg [9:0] sum,quotient;begin
   // Coverage is 0..3: exact weighted channel sum + rounding is 0..766.
   for(c=0;c<3;c=c+1)begin
    sum=10'(base_color[c*8+:8])*(10'd3-10'(coverage))+
     10'(foreground[c*8+:8])*10'(coverage)+10'd1;
    quotient=sum/10'd3;text_blend[c*8+:8]=quotient[7:0];
   end
  end'''
assert old in s;s=s.replace(old,new);p.write_text(s)
print('Bound working signed colors and exact anti-aliasing channel sum')
