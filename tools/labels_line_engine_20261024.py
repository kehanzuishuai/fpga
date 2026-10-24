"""Replace the 90 per-pixel label region decoders by a per-line region engine.

Before: every pixel evaluated 90 rectangles (4 compares each), 90 dx/dy
subtractions, 90 divisions and remainders by constant glyph widths, 90 40-bit
attribute muxes and a 90-input OR tree (region_q -> attributes_comb).
After: the regions crossing the current line come from a small ROM (lists in
x order, one list per band of lines); the engine follows only the current and
the next region of the line, counts the glyph column and position instead of
dividing, and registers the same 40-bit attribute word where region_q was.
Exact for the raster scan the labels see (x advances by one per clock along a
line, y changes only when x restarts): no regions overlap on a line, the first
region starts at x>=32 and every region is at least 8 pixels wide. Display
conditions (guide_mode, !env_valid) are still evaluated per pixel.
The constants are parsed from the existing region decoders. Idempotent.
"""
from pathlib import Path
import re
import sys

HIT = re.compile(r"^ wire hit_(\d+)=\((?:(.*?) && )?\((.*?)\) && x>=(\d+) && x<(\d+) && y>=(\d+) && y<(\d+)\);$", re.M)
REG = re.compile(r"^ wire \[39:0\] region_(\d+)=hit_\1\?\{(\w+),8'd(\d+),8'd(\d+),6'\(label_dx_\d+/\d+'d(\d+)\),2'd(\d),"
                 r"6'\(label_dx_\d+%\d+'d\d+\+\d+'d(\d+)\),6'\(label_dy_\d+\)\}:40'd0;$", re.M)
COND = {"1'b1": 0, 'guide_mode': 1, '!env_valid': 2}


def parse(s):
    regions = {}
    for k, pre, cond, x0, x1, y0, y1 in HIT.findall(s):
        c = ((pre + ' && ') if pre else '') + cond
        c = c.replace(" && 1'b1", '').strip()
        regions[int(k)] = dict(cond=COND[c], x0=int(x0), x1=int(x1), y0=int(y0), y1=int(y1))
    for k, kind, arg, size, w, tone, off in REG.findall(s):
        regions[int(k)].update(kind=kind, arg=int(arg), size=int(size), w=int(w), tone=int(tone), off=int(off))
    assert len(regions) == 90 and all('kind' in r for r in regions.values()), len(regions)
    return regions


def plan(regions):
    bounds = sorted({r['y0'] for r in regions.values()} | {r['y1'] for r in regions.values()} | {0})
    entries = [None]  # index 0: empty list terminator
    band_start = []   # (y_lo, start index)
    lists = {}
    for lo, hi in zip(bounds, bounds[1:] + [4096]):
        act = sorted((r['x0'], k) for k, r in regions.items() if r['y0'] <= lo < r['y1'])
        for (a, ka), (b, kb) in zip(act, act[1:]):
            assert b >= regions[ka]['x1'], ('overlap', ka, kb)
        assert all(regions[k]['x1'] - regions[k]['x0'] >= 8 and regions[k]['x0'] >= 32 for _, k in act)
        key = tuple(k for _, k in act)
        if not key:
            band_start.append((lo, 0))
            continue
        if key not in lists:
            lists[key] = len(entries)
            entries.extend(regions[k] for k in key)
            entries.append(None)
        band_start.append((lo, lists[key]))
    return band_start, entries


def tree(bands, width):
    if len(bands) == 1:
        return f"{width}'d{bands[0][1]}"
    m = len(bands) // 2
    # Spaces around ?: matter: GowinSynthesis lexes "12'd73?" as a decimal
    # literal with a z digit (EX3132); Icarus does not.
    return f"(y<12'd{bands[m][0]} ? {tree(bands[:m], width)} : {tree(bands[m:], width)})"


def emit(regions):
    bands, entries = plan(regions)
    aw = max(1, (len(entries) - 1).bit_length())
    rom = []
    for i, r in enumerate(entries):
        if r is None:
            continue
        rom.append(f"   {aw}'d{i}:ln_region_rom<={{1'b1,11'd{r['x0']},11'd{r['x1']},12'd{r['y0']},{r['kind']},8'd{r['arg']},8'd{r['size']},"
                   f"6'd{r['w'] - 1 + r['off']},2'd{r['tone']},6'd{r['off']},2'd{r['cond']}}};")
    return f''' // Per-line label region engine (tools/labels_line_engine_20261024.py).
 // Regions crossing a line come from ln_region_rom in x order; only the current
 // and the next region are followed, and the glyph column/position are counted
 // instead of divided. ln_line_list gives the first entry of the line's list.
 localparam integer ln_RAW={aw};
 wire [ln_RAW-1:0] ln_line_list={tree(bands, aw)};
 // Entry: valid, x0, x1, y0, kind, argument, size, ln_wrap column, tone, column offset, condition.
 reg [70:0] ln_region_rom;reg [ln_RAW-1:0] ln_fetch_addr;
 always @(posedge clk)case(ln_fetch_addr)
{chr(10).join(rom)}
   default:ln_region_rom<=71'd0;
  endcase
 wire ln_nxt_in=ln_region_rom[70];wire [10:0] ln_rom_x0=ln_region_rom[69:59],ln_rom_x1=ln_region_rom[58:48];wire [11:0] ln_rom_y0=ln_region_rom[47:36];
 reg ln_nxt_valid,ln_inside;reg [1:0] ln_load_wait;reg [11:0] ln_y_prev;
 reg [10:0] ln_nxt_x0,ln_nxt_x1,ln_cur_x1;reg [11:0] ln_nxt_y0,ln_cur_y0;reg [3:0] ln_nxt_kind,ln_cur_kind;reg [7:0] ln_nxt_arg,ln_cur_arg,ln_nxt_size,ln_cur_size;
 reg [5:0] ln_nxt_wrap,ln_cur_wrap,ln_nxt_off,ln_cur_off,ln_pos,ln_col;reg [1:0] ln_nxt_tone,ln_cur_tone,ln_nxt_cond,ln_cur_cond;
 initial begin ln_nxt_valid=0;ln_inside=0;ln_load_wait=0;ln_y_prev=12'hfff;ln_fetch_addr=0;ln_pos=0;ln_col=0;end
 wire ln_new_line=y!=ln_y_prev;
 wire ln_start=!ln_new_line && ln_nxt_valid && x=={{1'b0,ln_nxt_x0}};
 wire ln_stop=ln_inside && x=={{1'b0,ln_cur_x1}};
 wire ln_wrap=ln_col==ln_cur_wrap;
 wire ln_inside_next=!ln_new_line && (ln_start || (ln_inside && !ln_stop));
 wire [5:0] ln_pos_next=ln_start?6'd0:(ln_wrap?ln_pos+6'd1:ln_pos);
 wire [5:0] ln_col_next=ln_start?ln_nxt_off:(ln_wrap?ln_cur_off:ln_col+6'd1);
 wire [1:0] ln_cond_now=ln_start?ln_nxt_cond:ln_cur_cond;
 wire ln_cond_ok=ln_cond_now==2'd0 || (ln_cond_now==2'd1 && guide_mode) || (ln_cond_now==2'd2 && !env_valid);
 wire [11:0] ln_dy_now=y-(ln_start?ln_nxt_y0:ln_cur_y0);
 wire [39:0] ln_line_attributes=ln_inside_next && ln_cond_ok?{{ln_start?ln_nxt_kind:ln_cur_kind,ln_start?ln_nxt_arg:ln_cur_arg,ln_start?ln_nxt_size:ln_cur_size,
  ln_pos_next,ln_start?ln_nxt_tone:ln_cur_tone,ln_col_next,ln_dy_now[5:0]}}:40'd0;
 reg [39:0] ln_attributes_q;
 always @(posedge clk)begin
  ln_y_prev<=y;ln_attributes_q<=ln_line_attributes;
  ln_inside<=ln_inside_next;ln_pos<=ln_pos_next;ln_col<=ln_col_next;
  if(ln_start)begin
   ln_cur_x1<=ln_nxt_x1;ln_cur_y0<=ln_nxt_y0;ln_cur_kind<=ln_nxt_kind;ln_cur_arg<=ln_nxt_arg;ln_cur_size<=ln_nxt_size;
   ln_cur_wrap<=ln_nxt_wrap;ln_cur_tone<=ln_nxt_tone;ln_cur_off<=ln_nxt_off;ln_cur_cond<=ln_nxt_cond;
  end
  if(ln_new_line)begin ln_fetch_addr<=ln_line_list;ln_nxt_valid<=0;ln_load_wait<=2'd2;end
  else if(ln_start)begin ln_fetch_addr<=ln_fetch_addr+1'b1;ln_nxt_valid<=0;ln_load_wait<=2'd2;end
  else if(ln_load_wait!=0)begin
   ln_load_wait<=ln_load_wait-1'b1;
   if(ln_load_wait==2'd1)begin
    ln_nxt_valid<=ln_nxt_in;ln_nxt_x0<=ln_rom_x0;ln_nxt_x1<=ln_rom_x1;ln_nxt_y0<=ln_rom_y0;{{ln_nxt_kind,ln_nxt_arg,ln_nxt_size,ln_nxt_wrap,ln_nxt_tone,ln_nxt_off,ln_nxt_cond}}<=ln_region_rom[35:0];
   end
  end
 end
 wire [39:0] attributes_comb=ln_attributes_q;
'''


def convert(s):
    if 'Per-line label region engine' in s:
        return s
    regions = parse(s)
    first = s.index(' wire hit_0=')
    comb = s.index(' wire [39:0] attributes_comb=')
    comb_end = s.index('\n', comb) + 1
    allowed = re.compile(r"^ (wire hit_\d+=|wire \[\d+:0\] label_d[xy]_\d+=|wire \[39:0\] region_\d+=|// Only selected inside)")
    for line in s[first:comb].splitlines():
        assert not line.strip() or allowed.match(line), line[:80]
    s = s[:first] + emit(regions) + s[comb_end:]
    old_decl = ' reg [39:0] region_q[0:89],attr_pipe[0:14];'
    assert s.count(old_decl) == 1
    s = s.replace(old_decl, ' reg [39:0] attr_pipe[0:14];')
    assigns = ''.join(f'  region_q[{k}]<=region_{k};\n' for k in range(90))
    assert s.count(assigns) == 1
    s = s.replace(assigns, '')
    assert not re.search(r'\b(region_q|hit_\d+|label_dx_\d+|label_dy_\d+|region_\d+)\b', s)
    return s


def rewrite(path):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    s = raw.decode('utf-8').replace('\r\n', '\n')
    t = convert(s)
    if t != s:
        path.write_bytes((t.replace('\n', '\r\n') if crlf else t).encode('utf-8'))
        print('updated', path)
    else:
        print('unchanged', path)


if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    rewrite(root / 'src/display/visual_labels.sv')
