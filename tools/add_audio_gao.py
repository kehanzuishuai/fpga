"""Extend existing GAO with reset-scoped real handshake/PCM diagnostics."""
from pathlib import Path
import xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1]
p=R/'src/keyboard_debug.rao';t=ET.parse(p);s=t.find('./AoCore/SignalList')
for name,width in [('diagnostic_chain',128),('key_last_accepted_midi',7),('key_frame_count',16),('key_stall_count',16),('key_rejected_frames',32),('key_note_on_count',16),('key_note_off_count',16)]:
    if any(n.attrib.get('name','').startswith(name+'[') for n in s):continue
    bus=ET.SubElement(s,'Bus',{'capture_enable':'true','name':f'{name}[{width-1}:0]'})
    for bit in reversed(range(width)):ET.SubElement(bus,'Signal').text=f'{name}[{bit}]'
t.find('./AoCore/Triggers/Trigger/SignalList/Signal').text='key_event_accepted'
ET.indent(t,space='    ');t.write(p,encoding='unicode')
