"""Losslessly pack RGB24 into native 18-bit dual-port ROM words."""
from pathlib import Path
import re,json,hashlib
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_background.sv';s=p.read_text()
A=R/'audit/display_integration_20261021/optimization';b=A/'visual_background.original.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes());records=[]
for original in sorted((R/'assets').glob('bg_*.hex')):
 if 'packed18' in original.stem:continue
 pixels=[int(x,16) for x in original.read_text().split()]
 stream=sum(pixel<<(24*i) for i,pixel in enumerate(pixels))
 count=(len(pixels)*24+17)//18+1
 words=[(stream>>(18*i))&0x3ffff for i in range(count)]
 for i,pixel in enumerate(pixels):
  a=i*4//3;shift=(i%3)*6
  assert ((words[a]|(words[a+1]<<18))>>shift)&0xffffff==pixel
 out=original.with_stem(original.stem+'_packed18');out.write_text(''.join(f'{v:05x}\n' for v in words))
 s=s.replace(original.name,out.name)
 records.append({'original':original.name,'packed':out.name,'pixels':len(pixels),'words18':count,
  'sha256':hashlib.sha256(out.read_bytes()).hexdigest()})
assert len(records)==8
s=s.replace(' reg [23:0] bank0[0:WORDS-1],bank1[0:WORDS-1],bank2[0:WORDS-1],bank3[0:WORDS-1];\n reg [23:0] q0,q1,q2,q3;',
 ' wire [23:0] q0,q1,q2,q3;')
start=s.index(' initial begin\n  if(FILE0!="")$readmemh')
end=s.index(' function automatic [23:0] select_q',start)
roms=''
for i,(xx,yy) in enumerate([('even_x','even_y'),('odd_x','even_y'),('even_x','odd_y'),('odd_x','odd_y')]):
 roms+=f' visual_texture_rom24_packed #(.WORDS(WORDS),.FILE(FILE{i})) rom{i}(clk,{yy}*BW+{xx},q{i});\n'
s=s[:start]+roms+s[end:]
s=s.replace('  q0<=bank0[even_y*BW+even_x];q1<=bank1[even_y*BW+odd_x];\n  q2<=bank2[odd_y*BW+even_x];q3<=bank3[odd_y*BW+odd_x];\n','')
helper='''// Two reads from one native 18-bit ROM reconstruct each exact 24-bit texel.
// No quantization, decompression state, extra sampling delay or image change.
module visual_texture_rom24_packed #(parameter WORDS=1,FILE="")(
 input wire clk,input wire [31:0] addr,output wire [23:0] rgb);
 localparam AW=$clog2(WORDS)>0?$clog2(WORDS):1;
 localparam PW=(WORDS*24+17)/18+1;
 reg [17:0] data[0:PW-1];
 reg [17:0] low_q,high_q;reg [3:0] shift_q;
 wire [AW-1:0] local_addr=addr[AW-1:0];
 wire [AW+1:0] scaled={local_addr,2'b00};
 wire [AW+1:0] word_addr=scaled/(AW+2)'d3;
 wire [1:0] residue=local_addr%AW'(3);
 initial if(FILE!="")$readmemh(FILE,data);
 always @(posedge clk)begin
  low_q<=data[word_addr];high_q<=data[word_addr+1'b1];
  shift_q<=4'(residue)*4'd6;
 end
 wire [35:0] selected={high_q,low_q}>>shift_q;
 assign rgb=selected[23:0];
endmodule
'''
# Use an SV size cast for parameter-dependent constants (not a literal size).
helper=helper.replace("scaled/(AW+2)'d3","scaled/(AW+2)'(3)")
s=s.replace('/* verilator lint_on DECLFILENAME */',helper+'/* verilator lint_on DECLFILENAME */')
p.write_text(s);(A/'background_packing.json').write_text(json.dumps({'proof':'All original texels decoded bit-for-bit from packed words','planes':records},indent=2))
print('PASS lossless packing of all eight RGB24 source banks into native 18-bit words')
