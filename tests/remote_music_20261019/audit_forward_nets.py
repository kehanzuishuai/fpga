"""Check actual synthesis dependencies for two forward-declaration warnings."""
from pathlib import Path
import re,json,hashlib
R=Path(__file__).resolve().parents[2];p=R/'impl/gwsynthesis/yinyue_fashengqi.vg';net=p.read_text()
top=re.search(r'^module tang_mega_138k_pro_top [\s\S]*?^endmodule',net,re.M)[0]
drivers={}
for m in re.finditer(r'^  (\w+)\s+(\S+)\s*\(([\s\S]*?)^\);',top,re.M):
 kind,name,body=m.groups()
 if not (kind.startswith('LUT') or kind in ('ALU','MUX2','MUX4','MUX8','INV','BUF')):continue
 ports=dict(re.findall(r'\.(\w+)\(([^)]+)\)',body));outs={k:v.strip() for k,v in ports.items() if k in ('F','O','SUM','COUT')}
 ins=[v.strip() for k,v in ports.items() if k not in outs]
 for output in outs.values():drivers[output]=(name,ins)
def leaves(roots):
 seen=set();result=set()
 def visit(n):
  if n in seen:return
  seen.add(n)
  if n in ('VCC','GND') or "'" in n:return
  if n not in drivers:result.add(n);return
  for x in drivers[n][1]:visit(x)
 for n in roots:visit(n)
 return sorted(result)
remote=re.search(r'  remote_control u_remote \([\s\S]*?^\);',top,re.M)[0]
ports=dict(re.findall(r'\.(\w+)\(([^)]+)\)',remote))
note_roots=[ports[f'n{i}_4'] for i in range(765,772)]
note_leaves=leaves(note_roots)
fifo_leaves=leaves([v for k,v in ports.items() if k not in ('clk_12m288',)])
print('Physical-key lookup selector leaves:',[x for x in note_leaves if x.startswith(('event_key_index','event_note'))])
selector={'event_key_index[4]','event_key_index[3]','event_key_index[2]','event_note[1]','event_note[0]'}
assert selector<=set(note_leaves),selector-set(note_leaves)
fifo={f'fifo_level[{i}]' for i in range(5)}
assert 'wire [4:0] fifo_level;' in top and ports['fifo_level']=='fifo_level[4]'
assert 'fifo_level[4]' in fifo_leaves
assert fifo<=set(re.findall(r'\.Q\((fifo_level\[\d+\])\)',net))
result={'status':'PASS','netlist_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'key_lookup_roots':note_roots,'key_selector_dependencies':sorted(selector),'all_key_lookup_leaves':note_leaves,'FIFO_counter_register_bits':sorted(fifo),'FIFO_top_bus_width':5,'FIFO_remote_high_bit_connection':ports['fifo_level'],'scope':'Mapped structural width audit, not a whole-controller gate simulation. The key-map lookup depends on all 5 selector bits: bits1:0 alias event_note1:0 because default bridge notes start at60. The FIFO counter retains all 5 registered bits and a 5-bit top bus; bit4 directly feeds remote control (lower-bit reductions cross other hierarchy). These mapped high bits are retained, not padded zeros from a one-bit implicit connection.'}
(R/'tests/remote_music_20261019/out/FORWARD_NET_AUDIT.json').write_text(json.dumps(result,indent=2))
print('PASS actual netlist retains 5-bit physical-key lookup, 5-bit FIFO counter/bus and remote high-bit connection')
