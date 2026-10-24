"""Keep guide_state (status_data[490+:3]) in flip-flops through the scene and labels.

In every routed run the remaining hold failure was a status bit 490 register
driving the write-data (DI) pin of a distributed-RAM shift chain, reported with
a 0.000 ns falling-edge route (V8 color_q, aux completed_bcd_pipe, replicate
completed_bcd_pipe, norep labels status_pipe, v10 scene key_trails chain).
The router repairs flip-flop D-pin hold but not these DI pins. Following the
scene's existing protected_voice_bitmap pattern, each of the 40 scene stages
gets a 3-bit protected_guide_state register spliced into q, and the labels
carry the same three bits in a 15-stage flip-flop pipe next to status_pipe.
Values and latency are unchanged. Idempotent.
"""
from pathlib import Path
import sys

SCENE = [
    ('''  (* syn_srlstyle="registers" *) reg [31:0] protected_voice_bitmap;
  always_comb begin q=q_raw;q.status_data={q_raw.status_data[511:82],protected_voice_bitmap,q_raw.status_data[49:0]};end
''', '''  (* syn_srlstyle="registers" *) reg [31:0] protected_voice_bitmap;
  // guide_state stays in FFs too: as shift-chain write data it failed DI hold.
  (* syn_srlstyle="registers" *) reg [2:0] protected_guide_state;
  always_comb begin q=q_raw;q.status_data={q_raw.status_data[511:493],protected_guide_state,q_raw.status_data[489:82],protected_voice_bitmap,q_raw.status_data[49:0]};end
'''),
    ('q_raw<=d;protected_voice_bitmap<=d.status_data[50+:32];',
     'q_raw<=d;protected_voice_bitmap<=d.status_data[50+:32];protected_guide_state<=d.status_data[490+:3];'),
]
LABELS = [
    (' (* syn_preserve=1,syn_srlstyle="registers" *) reg [511:0] status_first;\n',
     ' (* syn_preserve=1,syn_srlstyle="registers" *) reg [511:0] status_first;\n'
     ' // guide_state (status bits 490..492) follows status_pipe in flip-flops.\n'
     ' (* syn_srlstyle="registers" *) reg [2:0] guide_pipe[1:15];\n'
     ' wire [511:0] status_tail={status_pipe[15][511:493],guide_pipe[15],status_pipe[15][489:0]};\n'),
    (' wire [511:0] count_status=status_pipe[15];', ' wire [511:0] count_status=status_tail;'),
    ('  char_status<=status_pipe[15];', '  char_status<=status_tail;'),
    # Before the if/else that builds status_pipe, so the else keeps its if.
    ('   if(meta_i<2)status_pipe[meta_i]<=status_first;\n',
     '   guide_pipe[meta_i]<=meta_i<2?status_first[490+:3]:guide_pipe[meta_i-1];\n'
     '   if(meta_i<2)status_pipe[meta_i]<=status_first;\n'),
]


def apply(s, edits, marker, counts):
    if marker in s:
        return s
    for (old, new), n in zip(edits, counts):
        assert s.count(old) == n, (old[:70], s.count(old))
        s = s.replace(old, new)
    return s


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
    rewrite(root / 'src/display/visual_scene.sv',
            lambda s: apply(s, SCENE, 'reg [2:0] protected_guide_state;', [40, 40]))
    rewrite(root / 'src/display/visual_labels.sv',
            lambda s: apply(s, LABELS, 'reg [2:0] guide_pipe[1:15];', [1, 1, 1, 1]))
