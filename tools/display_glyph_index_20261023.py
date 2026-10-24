"""One-clock sparse glyph index plus an exact small combinational descriptor."""
from pathlib import Path
import re,json

def index_labels(s,root):
    if 'module visual_glyph_index' in s:return s
    profile=json.loads(Path(__file__).with_name('display_glyph_index_profile_20261023.json').read_text(encoding='utf-8'))
    rows=[(int(k,16),int(v)) for k,v in re.findall(r"24'h([0-9a-f]+):begin font_base=17'd(\d+);font_found=1'b1;end",s)]
    assert rows==[tuple(x) for x in profile['entries']],'Glyph set changed; regenerate collision-free profile first'
    masks=profile['masks'];bits=len(masks);entries=[0]*(1<<bits);descriptors=[0]*256
    for i,(key,value) in enumerate(rows,1):
        address=sum(((key&mask).bit_count()&1)<<b for b,mask in enumerate(masks));assert entries[address]==0
        entries[address]=i;descriptors[i]=(key<<17)|value
    root=Path(root)
    (root/'assets/display_glyph_index.hex').write_text(''.join(f'{x:02x}\n' for x in entries))
    (root/'assets/display_glyph_descriptors.hex').write_text(''.join(f'{x:011x}\n' for x in descriptors))
    start=s.index(' reg [16:0] font_base;reg font_found;');end=s.index(' reg [16:0] base_q,font_addr_q;',start)
    s=s[:start]+''' wire[16:0] base_q;wire font_found;
 visual_glyph_index glyph_index(clk,attr_glyph[27:20],ch,base_q,font_found);
'''+s[end:]
    s=s.replace(' reg [16:0] base_q,font_addr_q;',' reg [16:0] font_addr_q;',1)
    s=s.replace('  base_q<=font_base;row_product_q<=','  row_product_q<=',1)
    s=s.replace('visible_q<=font_found && attr_glyph','visible_q<=attr_glyph',1)
    s=s.replace('visible_addr<=visible_q;color_addr<=color_q;','visible_addr<=visible_q && font_found;color_addr<=color_q;',1)
    marker=' reg visible_q,visible_addr;reg [23:0] color_q,color_addr;';assert s.count(marker)==1
    s=s.replace(marker,marker+'''
 wire[16:0] row_term={5'd0,row_product_q},column_term={11'd0,col_q};
 wire[16:0] address_xor=base_q ^ row_term ^ column_term;
 wire[16:0] address_carry=((base_q & row_term) | (base_q & column_term) | (row_term & column_term))<<1;
''',1)
    s=s.replace("font_addr_q<=base_q+17'(row_product_q)+17'(col_q);",'font_addr_q<=address_xor+address_carry;',1)
    module=f'''
`default_nettype none
// The sparse ROM registers an8-bit index at the original base_q edge.
// A small dense descriptor supplies the exact key/base; key comparison at
// the existing visible_addr edge rejects all unsupported characters.
module visual_glyph_index(input wire clk,input wire[7:0] font_size,input wire[15:0] character,
 output wire[16:0] base,output wire found);
 localparam HASH_BITS={bits},WORDS={1<<bits};
 wire[23:0] key={{font_size,character}};
 wire[HASH_BITS-1:0] address;
 (* syn_keep=1 *) wire[HASH_BITS*6-1:0] parity_group;
'''
    for i,m in enumerate(masks):
        for g in range(6):module+=f" assign parity_group[{i*6+g}]=^(key[{g*4}+:4] & 4'h{(m>>(g*4))&15:x});\n"
        module+=f' assign address[{i}]=^parity_group[{i*6}+:6];\n'
    module+=''' (* syn_romstyle="block_rom" *) reg[7:0] sparse_index[0:WORDS-1];
 (* syn_romstyle="logic" *) reg[40:0] descriptors[0:255];
 reg[7:0] index_q;reg[23:0] key_q;
 wire[40:0] descriptor=descriptors[index_q];
 initial begin
  $readmemh("assets/display_glyph_index.hex",sparse_index);
  $readmemh("assets/display_glyph_descriptors.hex",descriptors);
 end
 always @(posedge clk)begin index_q<=sparse_index[address];key_q<=key;end
 assign base=descriptor[16:0];
 assign found=index_q!=0 && descriptor[40:17]==key_q;
endmodule
`default_nettype wire
'''
    # 2026-10-23: register base/found before the font-ROM adder (LABEL_LATENCY 22).
    from display_glyph_register_20261023 import register_glyph
    return register_glyph(s+module)
