"""BRANCH ONLY (branches/frame_status_20261024): read frame-constant display
inputs directly instead of carrying them pixel by pixel.

The status word, status_live, key_trails, drift, peak/spectrum range and XY
mode all change only at blank_start (raster y=1080, x=0) or during the
following vertical blanking (the spectrum scan), more than 90,000 clocks before
the next visible pixel. The scene carried status/trails/live through 40
stages (as distributed-RAM shift chains, plus Codex's protected_voice_bitmap and
my protected_guide_state flip-flops), the labels through 16-stage status and
control pipes, the renderer status_live/status_data[5] through info_pipe. Every
stage now reads the frame value; the bit masks the original pipelines applied
(scene STAGE_1 drops bits 50..81, labels stages >= 2 drop bits 82..305) are
kept. Visible pixels and sync are unchanged; only blanking-time RGB within ~40
clocks after blank_start may differ, which HDMI does not transmit.
Apply on top of display_guide_state_ffs_20261024. Idempotent.
"""
from pathlib import Path
import re
import sys

CODEX_COMMENT = '''  // Actual routed hold paths originate at status_data[50+:32]. Keep this
  // voice bitmap in FFs; other unused/long metadata may use compact shifts.
'''
OLD_SPLICE = '''  (* syn_srlstyle="registers" *) reg [31:0] protected_voice_bitmap;
  // guide_state stays in FFs too: as shift-chain write data it failed DI hold.
  (* syn_srlstyle="registers" *) reg [2:0] protected_guide_state;
  always_comb begin q=q_raw;q.status_data={q_raw.status_data[511:493],protected_guide_state,q_raw.status_data[489:82],protected_voice_bitmap,q_raw.status_data[49:0]};end
'''
OLD_UPDATE = 'q_raw<=d;protected_voice_bitmap<=d.status_data[50+:32];protected_guide_state<=d.status_data[490+:3];'
SCENE_ANCHOR = ' pixel_state input_state;\n'
SCENE_FRAME = ''' // Branch frame_status: status, key trails and status_live change only at
 // blank_start, long before the next visible pixel; every stage reads them
 // directly. STAGE_1 onwards keep the original bits 50..81 drop.
 wire [511:0] frame_status_full=status_data;
 wire [511:0] frame_status_masked={status_data[511:82],32'd0,status_data[49:0]};
 pixel_state input_state;
'''


def scene(s):
    if 'wire [511:0] frame_status_masked' in s:
        return s
    assert s.count(CODEX_COMMENT) == 40 and s.count(OLD_SPLICE) == 40 and s.count(OLD_UPDATE) == 40
    assert s.count(SCENE_ANCHOR) == 1
    s = s.replace(CODEX_COMMENT, '').replace(OLD_UPDATE, 'q_raw<=d;')
    parts = s.split(OLD_SPLICE)
    out = parts[0]
    for k, rest in enumerate(parts[1:]):
        status = 'frame_status_full' if k == 0 else 'frame_status_masked'
        out += f'  always_comb begin q=q_raw;q.status_data={status};q.key_trails=key_trails;q.status_live=status_live;end\n' + rest
    return out.replace(SCENE_ANCHOR, SCENE_FRAME)


LABELS = [
    ('  key_note_pipe[0]<=pick_key_note(status_pipe[1],attr_pipe[0][32:28]);',
     '  key_note_pipe[0]<=pick_key_note(status_data,attr_pipe[0][32:28]);'),
    (' reg [511:0] status_pipe[0:15],char_status;\n', ' reg [511:0] char_status;\n'),
    (''' // First status stage in preserved flip-flops of its own: merged with the
 // scene's identical pipeline registers, the distributed-RAM delay chain
 // took its write data from high-fanout scene registers and failed DI hold.
 (* syn_preserve=1,syn_srlstyle="registers" *) reg [511:0] status_first;
 // guide_state (status bits 490..492) follows status_pipe in flip-flops.
 (* syn_srlstyle="registers" *) reg [2:0] guide_pipe[1:15];
 wire [511:0] status_tail={status_pipe[15][511:493],guide_pipe[15],status_pipe[15][489:0]};
''', ''' // Branch frame_status: status and control inputs change only at blank_start;
 // read them directly (with the original bits 82..305 drop) instead of
 // through 16-stage delay pipes.
 wire [511:0] status_tail={status_data[511:306],224'b0,status_data[81:0]};
 wire [28:0] control_now={status_live,peak_valid,peak_hz,xy_direct,xy_signal,xy_mixed,xy_shift,spectrum_range};
'''),
    (' reg [28:0] control_pipe[0:15],char_control;\n', ' reg [28:0] char_control;\n'),
    ('wire [28:0] count_control=control_pipe[15];', 'wire [28:0] count_control=control_now;'),
    ('  status_first<=status_data;\n', ''),
    ('  control_pipe[0]<={status_live,peak_valid,peak_hz,xy_direct,xy_signal,xy_mixed,xy_shift,spectrum_range};\n', ''),
    ('''   guide_pipe[meta_i]<=meta_i<2?status_first[490+:3]:guide_pipe[meta_i-1];
   if(meta_i<2)status_pipe[meta_i]<=status_first;
   else status_pipe[meta_i]<={status_pipe[meta_i-1][511:306],224'b0,status_pipe[meta_i-1][81:0]};
   control_pipe[meta_i]<=control_pipe[meta_i-1];
''', ''),
    ('char_status<=status_tail;char_control<=control_pipe[15];', 'char_status<=status_tail;char_control<=control_now;'),
    ('always @(posedge clk)axis_bcd_q<=axis_bcd(control_pipe[15][1:0],attr_pipe[14][35:28]);',
     'always @(posedge clk)axis_bcd_q<=axis_bcd(spectrum_range,attr_pipe[14][35:28]);'),
]


def labels(s):
    if 'wire [28:0] control_now=' in s:
        return s
    for old, new in LABELS:
        assert s.count(old) == 1, old[:70]
        s = s.replace(old, new)
    assert s.count('status_pipe[15][493+:16]') == 4
    s = s.replace('status_pipe[15][493+:16]', 'status_data[493+:16]')
    assert not re.search(r'\b(status_pipe|control_pipe|status_first|guide_pipe)\b', s)
    return s


RENDER_OLD = '   if(aligned.status_live && aligned.status_data[5] && aligned.x>=836'
RENDER_NEW = '   // Branch frame_status: frame-constant status read directly.\n   if(status_live && status_data[5] && aligned.x>=836'


def renderer(s):
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
    root = Path(sys.argv[1])
    assert 'branches' in root.parts, 'branch-only change: pass the branch directory'
    rewrite(root / 'src/display/visual_scene.sv', scene)
    rewrite(root / 'src/display/visual_labels.sv', labels)
    rewrite(root / 'src/display/visual_renderer.sv', renderer)
