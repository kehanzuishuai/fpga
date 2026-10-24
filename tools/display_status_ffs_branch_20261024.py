"""BRANCH ONLY (branches/srl_ff_20261024): keep every status-carrying pipeline of
the scene and labels in flip-flops, so no distributed-RAM shift chain ever takes
status as its write data (the DI hold class that failed in every routed run).

Scene: in each of the 40 stages the whole status word (512 bits) and the key
trails (96 bits) are carried by preserved-style flip-flop registers spliced into
q, replacing the narrower protected_voice_bitmap / protected_guide_state pair.
Labels: status_pipe, control_pipe and key_note_pipe get syn_srlstyle="registers".
Unused bits are still pruned by synthesis. Values and latency are unchanged.
Apply on top of display_guide_state_ffs_20261024. Idempotent.
"""
from pathlib import Path
import sys

SCENE = [
    ('''  (* syn_srlstyle="registers" *) reg [31:0] protected_voice_bitmap;
  // guide_state stays in FFs too: as shift-chain write data it failed DI hold.
  (* syn_srlstyle="registers" *) reg [2:0] protected_guide_state;
  always_comb begin q=q_raw;q.status_data={q_raw.status_data[511:493],protected_guide_state,q_raw.status_data[489:82],protected_voice_bitmap,q_raw.status_data[49:0]};end
''', '''  // Branch: the whole status word and the key trails stay in flip-flops, so
  // no distributed-RAM shift chain takes status as its write data.
  (* syn_srlstyle="registers" *) reg [511:0] protected_status;
  (* syn_srlstyle="registers" *) reg [95:0] protected_trails;
  always_comb begin q=q_raw;q.status_data=protected_status;q.key_trails=protected_trails;end
''', 40),
    ('q_raw<=d;protected_voice_bitmap<=d.status_data[50+:32];protected_guide_state<=d.status_data[490+:3];',
     'q_raw<=d;protected_status<=d.status_data;protected_trails<=d.key_trails;', 40),
]
LABELS = [
    (' reg [511:0] status_pipe[0:15],char_status;\n',
     ' // Branch: status-carrying label pipelines stay in flip-flops.\n'
     ' (* syn_srlstyle="registers" *) reg [511:0] status_pipe[0:15];\n'
     ' reg [511:0] char_status;\n', 1),
    (' reg [28:0] control_pipe[0:15],char_control;\n',
     ' (* syn_srlstyle="registers" *) reg [28:0] control_pipe[0:15];\n'
     ' reg [28:0] char_control;\n', 1),
    (' reg [6:0] char_key_note,key_note_pipe[0:13];',
     ' reg [6:0] char_key_note;(* syn_srlstyle="registers" *) reg [6:0] key_note_pipe[0:13];', 1),
]


def apply(s, edits, marker):
    if marker in s:
        return s
    for old, new, n in edits:
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
    root = Path(sys.argv[1])
    assert 'branches' in root.parts, 'branch-only change: pass the branch directory'
    rewrite(root / 'src/display/visual_scene.sv', lambda s: apply(s, SCENE, 'reg [511:0] protected_status;'))
    rewrite(root / 'src/display/visual_labels.sv', lambda s: apply(s, LABELS, '(* syn_srlstyle="registers" *) reg [511:0] status_pipe'))
