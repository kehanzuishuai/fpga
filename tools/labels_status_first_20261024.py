"""Give the first label status stage its own preserved flip-flops.

GowinSynthesis merged visual_labels' status_pipe stages with the scene's
identical status pipeline registers, so the labels' distributed-RAM delay chain
took its write data straight from high-fanout scene registers; those DI pins
failed hold in every routed run (one endpoint at -0.058 ns in
combined_v9b_norep_p3_r0, with the 0.150 ns pixel hold uncertainty kept).
The first stage is now `status_first`, kept in flip-flops and preserved; the
chain from stage 1 on is unchanged. Same registers, same latency. Idempotent.
"""
from pathlib import Path
import sys
EDITS = [
    (' reg [511:0] status_pipe[0:15],char_status;\n',
     ' reg [511:0] status_pipe[0:15],char_status;\n'
     ' // First status stage in preserved flip-flops of its own: merged with the\n'
     ' // scene\'s identical pipeline registers, the distributed-RAM delay chain\n'
     ' // took its write data from high-fanout scene registers and failed DI hold.\n'
     ' (* syn_preserve=1,syn_srlstyle="registers" *) reg [511:0] status_first;\n'),
    ('  status_pipe[0]<=status_data;\n', '  status_first<=status_data;\n'),
    ('   if(meta_i<2)status_pipe[meta_i]<=status_pipe[meta_i-1];\n',
     '   if(meta_i<2)status_pipe[meta_i]<=status_first;\n'),
]
def convert(s):
    if 'reg [511:0] status_first;' in s:return s
    for old,new in EDITS:
        assert s.count(old)==1,old;s=s.replace(old,new)
    return s
if __name__=='__main__':
    root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
    p=root/'src/display/visual_labels.sv';raw=p.read_bytes();crlf=b'\r\n' in raw
    s=raw.decode('utf-8').replace('\r\n','\n');t=convert(s)
    if t!=s:p.write_bytes((t.replace('\n','\r\n') if crlf else t).encode('utf-8'));print('updated',p)
    else:print('unchanged',p)
