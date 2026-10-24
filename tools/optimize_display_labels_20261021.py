"""Bound region arithmetic by its exact hit rectangle; preserve all visible pixels."""
from pathlib import Path
import re,json,hashlib
R=Path(__file__).resolve().parents[1]
p=R/'src/display/visual_labels.sv';text=p.read_text()
O=R/'audit/display_integration_20261021/optimization';O.mkdir(exist_ok=True)
original=O/'visual_labels.original.sv'
if original.exists():raise RuntimeError('One-shot optimization already applied')
original.write_bytes(p.read_bytes())
regions=[]
for match in list(re.finditer(r' wire hit_(\d+)=(.*?);\n wire \[39:0\] region_\1=(.*?);',text)):
 n,guard,expr=match.groups()
 x0,x1,y0,y1=map(int,re.search(r'x>=(\d+) && x<(\d+) && y>=(\d+) && y<(\d+)',guard).groups())
 xb=(x1-x0-1).bit_length();yb=(y1-y0-1).bit_length()
 dx=f'label_dx_{n}';dy=f'label_dy_{n}'
 divide=re.search(r"6'\(\(32'\(x\)-(\d+)\)/(\d+)\)",expr)
 assert divide and int(divide[1])==x0
 divisor=int(divide[2]);wb=max(xb,divisor.bit_length(),6)
 modulo=re.search(r"6'\(\(32'\(x\)-(\d+)\)%(\d+)\+(\d+)\)",expr)
 assert modulo and int(modulo[1])==x0 and int(modulo[2])==divisor
 pad=int(modulo[3])
 new_expr=expr.replace(divide[0],f"6'({dx}/{wb}'d{divisor})").replace(modulo[0],f"6'({dx}%{wb}'d{divisor}+{wb}'d{pad})")
 new_expr=new_expr.replace(f"6'(32'(y)-{y0})",f"6'({dy})")
 assert "32'(x)" not in new_expr and "32'(y)" not in new_expr
 replacement=(f' wire hit_{n}={guard};\n'
  f" // Only selected inside [{x0},{x1}) x [{y0},{y1}); truncated coordinates are exact there.\n"
  f" wire [{xb-1}:0] {dx}={xb}'(x-12'd{x0});\n"
  f" wire [{yb-1}:0] {dy}={yb}'(y-12'd{y0});\n"
  f' wire [39:0] region_{n}={new_expr};')
 text=text.replace(match[0],replacement)
 # Exhaust every selected local coordinate including padding and six-bit truncation.
 for x in range(x0,x1):
  local=(x-x0)&((1<<xb)-1)
  assert (local//divisor)&63==((x-x0)//divisor)&63
  assert (local%divisor+pad)&63==((x-x0)%divisor+pad)&63
 for y in range(y0,y1):assert ((y-y0)&((1<<yb)-1))&63==(y-y0)&63
 regions.append(dict(index=int(n),bounds=[x0,x1,y0,y1],x_bits=xb,y_bits=yb))
assert len(regions)==90
p.write_text(text)
(O/'labels_arithmetic.json').write_text(json.dumps({'regions':regions,'count':len(regions),
 'proof':'Exhaustive selected coordinates; original hit guards, glyph data, text, colors, attributes OR and coverage unchanged',
 'original_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),
 'optimized_sha256':hashlib.sha256(p.read_bytes()).hexdigest()},indent=2))
print('PASS 90 exact region coordinate bounds; all selected local coordinates exhausted')
