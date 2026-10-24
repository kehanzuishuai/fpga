"""Bind packed texels to true dual-port DPX9B, avoiding inferred ROM copies."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_background.sv';s=p.read_text()
A=R/'audit/display_integration_20261021/optimization';b=A/'visual_background.inferred_packed.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes())
files=sorted((R/'assets').glob('bg_*_packed18.hex'));cases=[];selects=[]
for bank,file in enumerate(files):
 selects.append(f'FILE=="assets/{file.name}"?{bank}:')
 words=[int(x,16) for x in file.read_text().split()]
 for block in range((len(words)+1023)//1024):
  bits=sum(v<<(i*18) for i,v in enumerate(words[block*1024:(block+1)*1024]))
  cases.append(f"   16'h{bank:02x}{block:02x}:packed_init=18432'h{bits:04608x};")
start=s.index(' reg [17:0] data[0:PW-1];')
end=s.index(' wire [35:0] selected=',start)
code=''' localparam BLOCKS=(PW+1023)/1024;
 localparam SW=$clog2(BLOCKS)>0?$clog2(BLOCKS):1;
 localparam PLANE='''+''.join(selects)+'''-1;
 function automatic [18431:0] packed_init(input integer plane,block);
  begin case({8'(plane),8'(block)})
'''+ '\n'.join(cases)+'''
   default:packed_init=0;
  endcase end
 endfunction
 wire [AW-1:0] local_addr=addr[AW-1:0];
 wire [AW+1:0] scaled={local_addr,2'b00};
 wire [AW+1:0] word_addr=scaled/(AW+2)'(3);
 wire [AW+1:0] next_addr=word_addr+1'b1;
 wire [1:0] residue=local_addr%AW'(3);
 wire [17:0] block_low[0:BLOCKS-1],block_high[0:BLOCKS-1];
 reg [SW-1:0] low_sel,high_sel;reg [3:0] shift_q;
 always @(posedge clk)begin
  low_sel<=SW'(32'(word_addr)>>10);high_sel<=SW'(32'(next_addr)>>10);
  shift_q<=4'(residue)*4'd6;
 end
 genvar g;
 generate for(g=0;g<BLOCKS;g=g+1)begin:PACKED
  localparam [18431:0] INIT=packed_init(PLANE,g);
  DPX9B #(.READ_MODE0(1'b0),.READ_MODE1(1'b0),.BIT_WIDTH_0(18),.BIT_WIDTH_1(18),
'''+',\n'.join(f'   .INIT_RAM_{i:02X}(INIT[{i*288}+:288])' for i in range(64))+''') rom(
   .DOA(block_low[g]),.DOB(block_high[g]),.DIA(18'd0),.DIB(18'd0),
   .BLKSELA(3'd0),.BLKSELB(3'd0),
   .ADA({10'(word_addr),4'd0}),.ADB({10'(next_addr),4'd0}),
   .WREA(1'b0),.WREB(1'b0),.CLKA(clk),.CLKB(clk),
   .CEA((32'(word_addr)>>10)==g),.CEB((32'(next_addr)>>10)==g),
   .OCEA(1'b1),.OCEB(1'b1),.RESETA(1'b0),.RESETB(1'b0));
 end endgenerate
 wire [17:0] low_q=block_low[low_sel],high_q=block_high[high_sel];
'''
s=s[:start]+code+s[end:];p.write_text(s)
print('Bound',len(cases),'exact DPX9B ROM blocks; no inferred read-port replication')
