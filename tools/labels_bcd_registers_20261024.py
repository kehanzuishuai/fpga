"""Keep the two double-dabble pipelines of visual_labels in flip-flops.

Under the module-wide syn_srlstyle="distributed_ram", GowinSynthesis turned the
pure-shift bits of peak_bcd_pipe/completed_bcd_pipe into distributed-RAM shift
chains; their first write-data pin (DI) was fed straight from status registers
and failed hold in every routed run (V8, glyph, aux, replicate). A per-array
syn_srlstyle="registers" keeps them as ordinary flip-flops. Mapping only: the
RTL behaviour is unchanged. Idempotent.
"""
from pathlib import Path
import sys
OLD = ' reg [35:0] peak_bcd_pipe[0:15],completed_bcd_pipe[0:15];\n'
NEW = ''' // Double-dabble stages stay in flip-flops: as distributed-RAM shift chains
 // their first write-data pin failed hold against the status registers.
 (* syn_srlstyle="registers" *) reg [35:0] peak_bcd_pipe[0:15];
 (* syn_srlstyle="registers" *) reg [35:0] completed_bcd_pipe[0:15];
'''
def convert(s):
    if '(* syn_srlstyle="registers" *) reg [35:0] completed_bcd_pipe' in s:return s
    assert s.count(OLD)==1;return s.replace(OLD,NEW)
if __name__=='__main__':
    root=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
    p=root/'src/display/visual_labels.sv';raw=p.read_bytes();crlf=b'\r\n' in raw
    s=raw.decode('utf-8').replace('\r\n','\n');t=convert(s)
    if t!=s:p.write_bytes((t.replace('\n','\r\n') if crlf else t).encode('utf-8'));print('updated',p)
    else:print('unchanged',p)
