"""Lossless synchronous font ROM; renderer alignment retains the original pixels."""
from pathlib import Path
import re,json,hashlib
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_labels.sv';s=p.read_text()
A=R/'audit/display_integration_20261021/optimization';b=A/'visual_labels.before_font_rom.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes())
glyphs=re.findall(r"24'h([0-9a-f]+):glyph=3528'h([0-9a-f]+)",s)
pixels=[];entries=[]
for code,bits in glyphs:
 size=int(code,16)>>16;v=int(bits,16);base=len(pixels)
 for y in range(42):
  for x in range(42):
   c=(v>>(3526-y*84-x*2))&3
   if y>=size or x>=size:assert c==0
   else:pixels.append(c)
 entries.append(f"   24'h{code}:begin font_base=17'd{base};font_found=1'b1;end")
font=R/'assets/display_font_coverage.hex';font.write_text(''.join(f'{x:x}\n' for x in pixels))
s=re.sub(r' function automatic \[3527:0\] glyph\(.*?endcase end endfunction\n','',s,flags=re.S)
assert 'glyph(' not in s.replace('wire [3527:0] bits=glyph({font_size,ch});','')
s=s.replace('input wire [1:0] spectrum_range\n','input wire [1:0] spectrum_range,input wire clk\n')
rom=f''' // Exact original 2-bit anti-aliased coverage, tightly packed by font size.
 reg [1:0] font_rom[0:{len(pixels)-1}];
 initial $readmemh("assets/display_font_coverage.hex",font_rom);
 reg [16:0] font_base;reg font_found;
 always @* begin
  font_base=0;font_found=0;
  case({{font_size,ch}})
{chr(10).join(entries)}
   default:begin end
  endcase
 end
 wire [16:0] font_addr=font_base+17'(row)*17'(font_size)+17'(col);
 wire font_visible=font_found && row<font_size && col<font_size;
'''
s=s.replace(' wire [3527:0] bits=glyph({font_size,ch});',rom)
start=s.index(' always @* begin\n  coverage=0;if(row<42')
end=s.index(' wire unused_labels',start)
s=s[:start]+''' always @(posedge clk)begin
  coverage<=font_visible?font_rom[font_addr]:2'd0;
  case(tone)1:color<=24'hfaf8f1;2:color<=24'hf4f4ec;3:color<=24'h4d6269;default:color<=24'he6e9e3;endcase
 end
 always @* ink=|coverage;
'''+s[end:]
p.write_text(s)
(A/'font_rom.json').write_text(json.dumps({'glyphs':len(glyphs),'pixels':len(pixels),
 'proof':'All original 42x42 coverages checked; omitted padding strictly zero',
 'asset_sha256':hashlib.sha256(font.read_bytes()).hexdigest()},indent=2))
print('Lossless font:',len(glyphs),'glyphs',len(pixels),'2-bit pixels')
