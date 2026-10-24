"""Two latency-neutral display fixes from the aux_ctx_glyph_p3_r0 routed STA.

1. Background bilinear sampling: each ROM parity bank now feeds the same
   multiplier every pixel and the bilinear weight is permuted by the corner
   instead of the texel (bank k carries role k^corner). The 4:1 texel
   multiplexer between BSRAM outputs and DSP inputs disappears; the same four
   integer products are summed, so every RGB value is unchanged.
2. Labels: the 90 region comparators had draw_x/draw_y (fanout 362) as source.
   The labels now take stage_x/stage_y and register them once inside, a
   preserved private copy of draw_x/draw_y with identical timing.
Idempotent.
"""
from pathlib import Path
import sys

BG_WIRES_OLD = ''' wire [23:0] a=select_q(corner_addr2,q0,q1,q2,q3),b=select_q(corner_addr2^2'd1,q0,q1,q2,q3),
             c=select_q(corner_addr2^2'd2,q0,q1,q2,q3),d=select_q(corner_addr2^2'd3,q0,q1,q2,q3);
'''
BG_WIRES_NEW = ''' // Bank k always feeds the same multiplier; the weight follows the corner
 // (bank k holds bilinear role k^corner). Same four products, same sum, but
 // no texel multiplexer between the ROM outputs and the multipliers.
 function automatic [WEIGHT_W-1:0] select_w(input [1:0] role,input [WEIGHT_W-1:0] w0,w1,w2,w3);
  begin case(role)0:select_w=w0;1:select_w=w1;2:select_w=w2;default:select_w=w3;endcase end
 endfunction
'''
BG_REGS_OLD = '''  sample_a<=a;sample_b<=b;sample_c<=c;sample_d<=d;
  weight_a<=wa_addr2;weight_b<=wb_addr2;weight_c<=wc_addr2;weight_d<=wd_addr2;
'''
BG_REGS_NEW = '''  sample_a<=q0;sample_b<=q1;sample_c<=q2;sample_d<=q3;
  weight_a<=select_w(corner_addr2,wa_addr2,wb_addr2,wc_addr2,wd_addr2);
  weight_b<=select_w(corner_addr2^2'd1,wa_addr2,wb_addr2,wc_addr2,wd_addr2);
  weight_c<=select_w(corner_addr2^2'd2,wa_addr2,wb_addr2,wc_addr2,wd_addr2);
  weight_d<=select_w(corner_addr2^2'd3,wa_addr2,wb_addr2,wc_addr2,wd_addr2);
'''
LABEL_PORT_OLD = ''' input wire [11:0] x,y,input wire peak_valid,'''
LABEL_PORT_NEW = ''' input wire [11:0] x_early,y_early,input wire peak_valid,'''
LABEL_BODY_ANCHOR = ''');
 wire note_valid='''
LABEL_BODY_NEW = ''');
 // Private, preserved copy of the renderer's draw_x/draw_y register: the
 // inputs are one stage earlier, so x/y here equal draw_x/draw_y every clock.
 (* syn_preserve=1 *) reg [11:0] x,y;
 always @(posedge clk)begin x<=x_early;y<=y_early;end
 wire note_valid='''
RENDER_OLD = '''.clk(clk),.x(draw_x),.y(draw_y),.peak_valid(peak_valid)'''
RENDER_NEW = '''.clk(clk),.x_early(stage_x),.y_early(stage_y),.peak_valid(peak_valid)'''


def fix_background(s):
    if 'function automatic [WEIGHT_W-1:0] select_w' in s:
        return s
    for old, new in [(BG_WIRES_OLD, BG_WIRES_NEW), (BG_REGS_OLD, BG_REGS_NEW)]:
        assert s.count(old) == 1, old[:60]
        s = s.replace(old, new)
    return s


def fix_labels(s):
    if 'input wire [11:0] x_early,y_early' in s:
        return s
    for old, new in [(LABEL_PORT_OLD, LABEL_PORT_NEW), (LABEL_BODY_ANCHOR, LABEL_BODY_NEW)]:
        assert s.count(old) == 1, old[:60]
        s = s.replace(old, new)
    return s


def fix_renderer(s):
    if RENDER_NEW in s:
        return s
    assert s.count(RENDER_OLD) == 1
    return s.replace(RENDER_OLD, RENDER_NEW)


def rewrite(path, fn):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    s = raw.decode('utf-8').replace('\r\n', '\n')
    t = fn(s)
    if t != s:
        path.write_bytes((t.replace('\n', '\r\n') if crlf else t).encode('utf-8'))
        print('updated', path)
    else:
        print('unchanged', path)


if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    rewrite(root / 'src/display/visual_background.sv', fix_background)
    rewrite(root / 'src/display/visual_labels.sv', fix_labels)
    rewrite(root / 'src/display/visual_renderer.sv', fix_renderer)
