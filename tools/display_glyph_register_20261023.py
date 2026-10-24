"""Register the glyph descriptor before the font-ROM address adder.

V8 routed STA: glyph sparse-index BSRAM DO (fanout 577) -> descriptor LUT ROM
-> 3-input address adder -> bank decode -> font ROM CE/AD, 18.5 ns against a
13.468 ns pixel period.  This adds one register after the descriptor lookup
(base/found), pre-adds the row/column offset in the same clock, and carries
visibility and colour one clock further.  LABEL_LATENCY becomes 22 and the
renderer's label alignment pipe shrinks from 20 to 19 stages, so every
rendered pixel and the overall 40-clock scene latency are unchanged.
Idempotent: already converted sources are returned unchanged.
"""
from pathlib import Path
import sys

GLYPH_OLD = ''' always @(posedge clk)begin index_q<=sparse_index[address];key_q<=key;end
 assign base=descriptor[16:0];
 assign found=index_q!=0 && descriptor[40:17]==key_q;'''
GLYPH_NEW = ''' reg[16:0] base_q;reg found_q;
 always @(posedge clk)begin
  index_q<=sparse_index[address];key_q<=key;
  // One extra clock between the descriptor lookup and the font-ROM adder.
  base_q<=descriptor[16:0];found_q<=index_q!=0 && descriptor[40:17]==key_q;
 end
 assign base=base_q;
 assign found=found_q;'''
COMMENT_OLD = '''// The sparse ROM registers an8-bit index at the original base_q edge.
// A small dense descriptor supplies the exact key/base; key comparison at
// the existing visible_addr edge rejects all unsupported characters.'''
COMMENT_NEW = '''// The sparse ROM registers an8-bit index; a small dense descriptor supplies
// the exact key/base, registered once more together with the full 24-bit key
// comparison that rejects all unsupported characters.'''
DECL_OLD = ''' reg [16:0] font_addr_q;reg [11:0] row_product_q;reg [5:0] col_q;
 reg visible_q,visible_addr;reg [23:0] color_q,color_addr;
 wire[16:0] row_term={5'd0,row_product_q},column_term={11'd0,col_q};
 wire[16:0] address_xor=base_q ^ row_term ^ column_term;
 wire[16:0] address_carry=((base_q & row_term) | (base_q & column_term) | (row_term & column_term))<<1;
'''
DECL_NEW = ''' reg [16:0] font_addr_q;reg [11:0] row_product_q;reg [5:0] col_q;reg [12:0] glyph_offset_q;
 reg visible_q,visible_glyph,visible_addr;reg [23:0] color_q,color_glyph,color_addr;
'''
ADDR_OLD = '''  font_addr_q<=address_xor+address_carry;visible_addr<=visible_q && font_found;color_addr<=color_q;'''
# row_product_q<=4095 and col_q<=63, so the 13-bit offset never wraps and
# base+offset equals the former base+row+column modulo 2^17.
ADDR_NEW = '''  glyph_offset_q<=13'(row_product_q)+13'(col_q);visible_glyph<=visible_q;color_glyph<=color_q;
  font_addr_q<=base_q+17'(glyph_offset_q);visible_addr<=visible_glyph && font_found;color_addr<=color_glyph;'''


def register_glyph(s):
    if 'reg[16:0] base_q;reg found_q;' in s:
        return s
    for old, new in [(GLYPH_OLD, GLYPH_NEW), (COMMENT_OLD, COMMENT_NEW), (DECL_OLD, DECL_NEW),
                     (ADDR_OLD, ADDR_NEW), ('localparam LABEL_LATENCY=21;', 'localparam LABEL_LATENCY=22;')]:
        assert s.count(old) == 1, old[:60]
        s = s.replace(old, new)
    return s


def realign_renderer(s, label_latency=22, scene_latency=40):
    delay = scene_latency + 1 - label_latency
    old_delay = delay + 1
    if f'reg [26:0] label_pipe[0:{delay-1}];' in s:
        return s
    for old, new in [
        (f'align their exact {label_latency-1}-clock result', f'align their exact {label_latency}-clock result'),
        (f'reg [26:0] label_pipe[0:{old_delay-1}];', f'reg [26:0] label_pipe[0:{delay-1}];'),
        (f'delay_label<{old_delay};', f'delay_label<{delay};'),
        (f'=label_pipe[{old_delay-1}];', f'=label_pipe[{delay-1}];'),
        (f'early_label_color=label_pipe[{old_delay-2}]', f'early_label_color=label_pipe[{delay-2}]'),
        (f'early_label_coverage=label_pipe[{old_delay-2}]', f'early_label_coverage=label_pipe[{delay-2}]'),
    ]:
        assert s.count(old) == 1, old
        s = s.replace(old, new)
    return s


def rewrite(path, fn):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    s = raw.decode('utf-8').replace('\r\n', '\n')
    t = fn(s)
    if t != s:
        if crlf:
            t = t.replace('\n', '\r\n')
        path.write_bytes(t.encode('utf-8'))
        print('updated', path)
    else:
        print('unchanged', path)


if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    rewrite(root / 'src/display/visual_labels.sv', register_glyph)
    rewrite(root / 'src/display/visual_renderer.sv', realign_renderer)
