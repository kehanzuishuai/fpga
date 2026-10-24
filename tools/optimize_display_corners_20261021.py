"""Exact integer-circle boundary LUT; reserve DSPs for audio and FFT."""
from pathlib import Path
from math import isqrt
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_scene.sv';s=p.read_text()
A=R/'audit/display_integration_20261021/optimization';b=A/'visual_scene.before_corner_lut.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes())
rows=[]
for radius in range(64):
 for dx in range(radius+1):
  limit=isqrt(radius*radius-dx*dx)
  rows.append(f"   12'd{radius*64+dx}:circle_limit=7'd{64+limit};")
  for dy in range(64):assert (dy<=limit)==(dx*dx+dy*dy<=radius*radius)
lut=''' // Exact dx^2+dy^2 <= radius^2 for the original six-bit corner distances.
 // Radius is constant in each pane/key instance, leaving a small 1-D LUT.
 function automatic [6:0] circle_limit(input [5:0] radius,dx);
  begin case({radius,dx})
'''+ '\n'.join(rows)+'''
   default:circle_limit=0;
  endcase end
 endfunction
'''
s=s.replace(' function automatic rounded(',lut+' function automatic rounded(')
s=s.replace('reg [12:0] distance2;', 'reg [6:0] boundary;')
s=s.replace("   distance2=13'(dx)*13'(dx)+13'(dy)*13'(dy);","   boundary=circle_limit(6'(r),dx);")
s=s.replace("distance2<=13'(r*r)","boundary[6] && dy<=boundary[5:0]")
assert 'distance2' not in s
p.write_text(s);print('PASS exhaustive integer corner boundaries; no geometric approximation')
