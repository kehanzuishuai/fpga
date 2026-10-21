"""Keep 4096-cycle event/Loader coverage; capture modulo-256 counters."""
from pathlib import Path
import xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];p=R/'src/keyboard_debug.rao'
t=ET.parse(p);s=t.find('./AoCore/SignalList')
names=['diagnostic_chain','key_note_on_count','key_note_off_count','key_frame_count','key_stall_count']
for b in list(s):
    if any(b.attrib.get('name','').startswith(n+'[') for n in names):s.remove(b)
def bus(name,hi,lo):
    b=ET.SubElement(s,'Bus',{'capture_enable':'true','name':f'{name}[{hi}:{lo}]'})
    for bit in range(hi,lo-1,-1):ET.SubElement(b,'Signal').text=f'{name}[{bit}]'
for hi,lo in [(7,0),(23,16),(39,32),(71,48),(95,72),(103,96),(119,112)]:bus('diagnostic_chain',hi,lo)
for n in names[1:]:bus(n,7,0)
assert t.find('./AoCore').attrib['storage_depth']=='4096'
ET.indent(t,space='    ');t.write(p,encoding='unicode')
print('GAO keeps all functional observations, full 24-bit peaks, 8-bit counter deltas and 4096-cycle capture')
