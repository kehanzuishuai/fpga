"""Keep exact signed key blending, using proven bounded numerators."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_scene.sv'
O=R/'audit/display_integration_20261021/optimization';O.mkdir(exist_ok=True)
original=O/'visual_scene.original.sv'
if original.exists():raise RuntimeError('Already applied')
original.write_bytes(p.read_bytes());s=p.read_text()
helper=''' // Key blends have numerators in [-651,1330] for all shades 0..18,
 // board colors and 3-bit release amounts. Signed division truncates to zero,
 // exactly as the original integer arithmetic (including negative fades).
 function automatic integer fade7(input signed [11:0] numerator);
  reg signed [11:0] quotient;begin
   quotient=numerator/12'sd7;
   fade7={{20{quotient[11]}},quotient};
  end
 endfunction
'''
s=s.replace('\n integer sx,sy,','\n'+helper+' integer sx,sy,')
expressions=[
 '( (i==0?158-shade:158-shade)-rr)*amount',
 '( (i==0?226-shade:244-shade)-gg)*amount',
 '( (i==0?249-shade:212-shade)-bb)*amount',
 'clamp(5-light,0,5)*amount',
 '((i==0?115:105)-rr)*amount',
 '((i==0?182:200)-gg)*amount',
 '((i==0?227:189)-bb)*amount',
 '((i==0?161:157)-rr)*amount',
 '((i==0?222:236)-gg)*amount',
 '((i==0?248:220)-bb)*amount']
for expr in expressions:
 assert s.count(expr+'/7')==1,expr
 s=s.replace(expr+'/7','fade7('+expr+')')
# Exhaust all valid independent color/shade/amount inputs, including both
# boards and each signed fade direction. This is not an approximate LUT.
lo=0;hi=0
for shade in range(19):
 for board in range(2):
  cases=[(158-shade-(251-shade)),
   (226 if board==0 else 244)-shade-(249-shade),
   (249 if board==0 else 212)-shade-(245-shade),
   (115 if board==0 else 105)-(38-shade),
   (182 if board==0 else 200)-(48-shade),
   (227 if board==0 else 189)-(55-shade)]
  for y in range(38):
   cases.extend([(161 if board==0 else 157)-(119-y//2),
    (222 if board==0 else 236)-(148-y//2),
    (248 if board==0 else 220)-(173-y//2)])
  for amount in range(8):
   for delta in cases:
    n=delta*amount;lo=min(lo,n);hi=max(hi,n);assert -2048<=n<2048
    signed=((n+2048)%4096)-2048
    assert int(n/7)==int(signed/7)
p.write_text(s)
(O/'scene_arithmetic.json').write_text(json.dumps({'numerator_bounds':[lo,hi],
 'changes':len(expressions),'proof':'All board/shade/release colors exhausted; exact signed truncation toward zero',
 'original_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),
 'optimized_sha256':hashlib.sha256(p.read_bytes()).hexdigest()},indent=2))
print('PASS exact signed fade numerators:',lo,hi)
