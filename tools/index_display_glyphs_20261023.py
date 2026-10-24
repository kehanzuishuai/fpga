"""Replace the measured glyph CAM path by an exact collision-checked ROM."""
from pathlib import Path
import re,json,random,hashlib,shutil,sys
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/glyph_index';A.mkdir(exist_ok=True)
p=R/'src/display/visual_labels.sv';s=p.read_text();assert 'module visual_glyph_index' not in s
rows=[(int(k,16),int(v)) for k,v in re.findall(r"24'h([0-9a-f]+):begin font_base=17'd(\d+);font_found=1'b1;end",s)]
assert len(rows)==233 and len({k for k,v in rows})==233
rng=random.Random(20261023);masks=None;attempts=0
for bits in [10,11,12]:
    for trial in range(30000):
        candidate=[rng.getrandbits(24) or 1 for _ in range(bits)]
        used=set();okay=True
        for key,value in rows:
            h=sum(((key&mask).bit_count()&1)<<i for i,mask in enumerate(candidate))
            if h in used:okay=False;break
            used.add(h)
        attempts+=1
        if okay:masks=candidate;break
    if masks is not None:break
assert masks is not None,'No exact hash found'
def address(key):return sum(((key&m).bit_count()&1)<<i for i,m in enumerate(masks))
entries=[0]*(1<<bits)
for key,value in rows:
    a=address(key);assert entries[a]==0
    entries[a]=(1<<41)|(key<<17)|value
asset=R/'assets/display_glyph_index.hex';assert not asset.exists()
asset.write_text(''.join(f'{x:011x}\n' for x in entries))
backup=A/'visual_labels.before.sv';assert not backup.exists();shutil.copy2(p,backup)
module=f'''
`default_nettype none
// One registered exact key/base lookup. Stored24-bit identity rejects every
// unsupported key, including collisions with valid glyph hash addresses.
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
module+=''' (* syn_romstyle="block_rom" *) reg[41:0] lookup[0:WORDS-1];
 reg[41:0] lookup_q;reg[23:0] key_q;
 initial $readmemh("assets/display_glyph_index.hex",lookup);
 always @(posedge clk)begin lookup_q<=lookup[address];key_q<=key;end
 assign base=lookup_q[16:0];
 assign found=lookup_q[41] && lookup_q[40:17]==key_q;
endmodule
`default_nettype wire
'''
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
s+=module;p.write_text(s)
rec=dict(status='APPLIED_PENDING_EQUIVALENCE_AND_SYNTHESIS',hash_bits=bits,rom_words=1<<bits,attempts=attempts,masks=masks,entries=rows,
    source_before_sha256=hashlib.sha256(backup.read_bytes()).hexdigest(),source_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),asset_sha256=hashlib.sha256(asset.read_bytes()).hexdigest(),
    scope='Original233 glyph key/base entries and coverage bitmap unchanged. Lookup registered at original base_q edge; identity check moved to existing visible_addr edge; total21 clocks unchanged. Address carry-save sum exact modulo17 bits.',programming=False)
(A/'CHANGE.json').write_text(json.dumps(rec,indent=2))
(A/'glyph_module.sv.txt').write_text(module)
print(json.dumps({k:rec[k] for k in ['status','hash_bits','rom_words','attempts','scope']},indent=2),flush=True)
