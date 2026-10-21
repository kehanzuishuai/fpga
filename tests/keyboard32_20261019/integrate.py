"""Apply the reviewed two-bank boundary changes; never alters the piano DSP."""
from pathlib import Path
import xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[2]
p=R/'src/tang_mega_138k_pro_top.v.v';s=p.read_text()
assert 'ttp229_keyboard_pair' not in s
s=s.replace('parameter KEYBOARD_PROFILE = 0,','parameter KEYBOARD_PROFILE = 1,\n    parameter KEY2_BOARD_PROFILE = 1,')
s=s.replace('// Reader policy only: 0 conservative mirror guard, 1 TTP16 diagnostic.',
'''// Two physical modules must both be configured for 16-key/multi-key mode.
    // Profile 1 admits all 16 bits even for the first symmetric chord;
    // profile 0 retains the optional legacy 8-key mirror diagnostic.''')
old='''        (KEY_BASE_NOTE+7'd1),  KEY_BASE_NOTE
    }
'''
new='''        (KEY_BASE_NOTE+7'd1),  KEY_BASE_NOTE
    },
    parameter KEY2_RAW_MAP_ENABLE = 0,
    parameter [63:0] KEY2_RAW_INDEX_TABLE = 64'hfedcba9876543210,
    parameter [6:0] KEY2_BASE_NOTE = KEY_BASE_NOTE+7'd16,
    parameter [111:0] KEY2_NOTE_TABLE = {
        (KEY2_BASE_NOTE+7'd15), (KEY2_BASE_NOTE+7'd14),
        (KEY2_BASE_NOTE+7'd13), (KEY2_BASE_NOTE+7'd12),
        (KEY2_BASE_NOTE+7'd11), (KEY2_BASE_NOTE+7'd10),
        (KEY2_BASE_NOTE+7'd9),  (KEY2_BASE_NOTE+7'd8),
        (KEY2_BASE_NOTE+7'd7),  (KEY2_BASE_NOTE+7'd6),
        (KEY2_BASE_NOTE+7'd5),  (KEY2_BASE_NOTE+7'd4),
        (KEY2_BASE_NOTE+7'd3),  (KEY2_BASE_NOTE+7'd2),
        (KEY2_BASE_NOTE+7'd1),  KEY2_BASE_NOTE
    }
'''
assert s.count(old)==1;s=s.replace(old,new)
s=s.replace('input  wire ttp229_sdo,','input  wire ttp229_sdo,\n    output wire ttp229_2_scl,\n    input  wire ttp229_2_sdo,')
start=s.index('wire [15:0] key_state,key_reader_state,key_accepted_raw;')
end=s.index('/* ============================================================\n * TTP229 -> synth Note Event',start)
s=s[:start]+'''// Legacy 16-key aliases belong only to module 1 / the existing display.
// Audio and the event scheduler use the complete 32-bit bundle.
wire [31:0] key_state32,key_accepted_raw32,key_raw_frame32,key_reader_state32;
wire [15:0] key_state=key_state32[15:0];
wire [15:0] key2_state=key_state32[31:16];
wire [15:0] key_raw_frame=key_raw_frame32[15:0];
wire [15:0] key_reader_state=key_reader_state32[15:0];
wire [15:0] key_accepted_raw=key_accepted_raw32[15:0];
wire [1:0] key_bank_frame_valid,key_bank_frame_error,key_bank_busy;
wire [1:0] key_bank_mode16,key_bank_mode8;
wire [63:0] key_bank_rejected;
wire key_mapping_error;
wire key_frame_valid=|key_bank_frame_valid;
wire key_frame_error=|key_bank_frame_error;
wire key_reader_busy=|key_bank_busy;
wire key_mode16_seen=&key_bank_mode16;
wire key_mode8_suspect=|key_bank_mode8;
wire [31:0] key_rejected_frames=key_bank_rejected[31:0];

ttp229_keyboard_pair #(
 .PROFILE0(KEYBOARD_PROFILE),.PROFILE1(KEY2_BOARD_PROFILE),
 .RAW_MAP0(KEY_RAW_MAP_ENABLE),.RAW_INDEX0(KEY_RAW_INDEX_TABLE),
 .RAW_MAP1(KEY2_RAW_MAP_ENABLE),.RAW_INDEX1(KEY2_RAW_INDEX_TABLE),
 .NOTES({KEY2_NOTE_TABLE,KEY_NOTE_TABLE})
) u_keyboards(
 .clk(clk_12m288),.rst_n(synth_rst_n),
 .scl0(ttp229_scl),.sdo0(ttp229_sdo),
 .scl1(ttp229_2_scl),.sdo1(ttp229_2_sdo),
 .key_state(key_state32),.accepted_raw(key_accepted_raw32),
 .raw_frame(key_raw_frame32),.reader_state(key_reader_state32),
 .accepted_frame(key_bank_frame_valid),.frame_error(key_bank_frame_error),
 .reader_busy(key_bank_busy),.mode16_seen(key_bank_mode16),
 .mode8_suspect(key_bank_mode8),.mapping_error(key_mapping_error),
 .rejected_frames(key_bank_rejected));

'''+s[end:]
s=s.replace('wire [3:0]  event_key_index;','wire [4:0]  event_key_index;')
s=s.replace('wire [15:0] key_reported_state;','wire [31:0] key_reported_state32;\nwire [15:0] key_reported_state=key_reported_state32[15:0];')
s=s.replace('ttp229_event_bridge #(\n','ttp229_event_bridge #(\n    .KEY_COUNT(32),\n')
s=s.replace('.NOTE_TABLE(KEY_NOTE_TABLE),','.NOTE_TABLE({KEY2_NOTE_TABLE,KEY_NOTE_TABLE}),')
s=s.replace('.key_state\n        (key_state),','.key_state\n        (key_state32),')
s=s.replace('(key_reported_state)\n','(key_reported_state32)\n')
s=s.replace('reg [15:0] key_fifo_accepted_state;','reg [31:0] key_fifo_accepted_state;')
p.write_text(s,encoding='utf8')
assert '.key_state\n        (key_state32)' in s and 'output wire ttp229_2_scl' in s
p=R/'src/integrated.cst';s=p.read_text()
s+='''
// Second TTP229: Pro Dock4071f rev1.2 page16, J26/PMOD2.
// SCL: J26 pin7 / PMOD2_IO2 / B19 / bank5, SDO: pin5 / IO3 / A17 / bank5.
// Module VCC -> J26 pin1 or2 (+3V3), GND -> pin3 or4. Independent buses.
IO_LOC "ttp229_2_scl" B19;
IO_PORT "ttp229_2_scl" IO_TYPE=LVCMOS33;
IO_LOC "ttp229_2_sdo" A17;
IO_PORT "ttp229_2_sdo" IO_TYPE=LVCMOS33 PULL_MODE=UP;
'''
p.write_text(s,encoding='utf8')
# The asynchronous input crosses exactly the same two-flop boundary as bank0.
# No clock groups, output timing or reset exceptions are loosened.
p=R/'yinyue_fashengqi.gprj';s=p.read_text();line='        <File path="src/keyboard/ttp229_keyboard_pair.sv" type="file.verilog" enable="1"/>\n'
s=s.replace('    </FileList>',line+'    </FileList>');p.write_text(s,encoding='utf8')
# Preserve the analyzer, widen its existing keyboard probes to include bank1.
p=R/'src/keyboard_debug.rao';tree=ET.parse(p);root=tree.getroot()
signals=root.find('./AoCore/SignalList');assert signals is not None
for old,new,width in [('key_raw_frame','key_raw_frame32',32),('key_state','key_state32',32),
 ('key_reported_state','key_reported_state32',32),('key_reader_state','key_reader_state32',32),
 ('key_fifo_accepted_state','key_fifo_accepted_state',32),('event_key_index','event_key_index',5)]:
 found=[e for e in signals.findall('Bus') if e.get('name','').split('[')[0]==old]
 assert len(found)==1,(old,found)
 bus=found[0];bus.set('name',f'{new}[{width-1}:0]')
 for e in list(bus):bus.remove(e)
 for n in reversed(range(width)): ET.SubElement(bus,'Signal').text=f'{new}[{n}]'
for name in ['ttp229_2_scl','ttp229_2_sdo','key_mapping_error']:
 ET.SubElement(signals,'Signal',{'capture_enable':'true'}).text=name
for name in ['key_bank_frame_valid','key_bank_frame_error','key_bank_mode16','key_bank_mode8']:
 bus=ET.SubElement(signals,'Bus',{'capture_enable':'true','name':f'{name}[1:0]'})
 for n in [1,0]:ET.SubElement(bus,'Signal').text=f'{name}[{n}]'
ET.indent(tree,space='    ');tree.write(p,encoding='unicode')
print('Integrated 32-key transport/bridge; added second bus pins and enabled RTL in GPRJ')
