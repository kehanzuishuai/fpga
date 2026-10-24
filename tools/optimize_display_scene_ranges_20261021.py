"""Exact coordinate and lighting divisions for selected pane/key rectangles."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_scene.sv';s=p.read_text()
A=R/'audit/display_integration_20261021/optimization'
b=A/'visual_scene.fade_only.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes())
helper=''' // All these selected-pane/key numerators are within signed 14 bits.
 function automatic integer divide14(input signed [13:0] n,d);
  reg signed [13:0] q;begin q=n/d;divide14={{18{q[13]}},q};end
 endfunction
 function automatic integer remainder96(input signed [13:0] n);
  reg signed [13:0] q;begin q=n%14'sd96;remainder96={{18{q[13]}},q};end
 endfunction
'''
s=s.replace('\n integer sx,sy,','\n'+helper+' integer sx,sy,')
replacements=[
 ('(rr+gg+bb)/3',"divide14(rr+gg+bb,14'sd3)"),
 ('rim*rim/13',"divide14(rim*rim,14'sd13)"),
 ('(sx-px)/13',"divide14(sx-px,14'sd13)"),
 ('(sy-py)/5',"divide14(sy-py,14'sd5)"),
 ('(px+pw-1-sx)/13',"divide14(px+pw-1-sx,14'sd13)"),
 ('(py+ph-1-sy)/5',"divide14(py+ph-1-sy,14'sd5)"),
 ('light/3',"divide14(light,14'sd3)"),
 ('(sx-base)/96',"divide14(sx-base,14'sd96)"),
 ('(sx-base)%96','remainder96(sx-base)'),
 ('ab(remainder96(sx-base)-47)/5',"divide14(ab(remainder96(sx-base)-47),14'sd5)"),
 ('(sy-846)/20',"divide14(sy-846,14'sd20)"),
 ('ab(sx-kx-26)/3',"divide14(ab(sx-kx-26),14'sd3)"),
 ('(sy-846)/10',"divide14(sy-846,14'sd10)")]
for a,b in replacements:
 assert a in s,a
 s=s.replace(a,b)
p.write_text(s)
print('Applied exact 14-bit selected-pane/key division bounds')
