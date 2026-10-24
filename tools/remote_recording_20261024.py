"""Physical-key recording for the phone app (extension 4 "演奏录音回传", user 2026-10-24).

The remote controller records every physical-key note event at the moment the
synth accepts it (key_valid && key_ready): key down/up, the mapped note, the
velocity and a 16-bit millisecond time, into a 64-entry buffer. Two new UART
commands (BLE_PROTOCOL.md):
  0x17 p0=0/1  recording off/on; on clears the buffer and the overflow flag and
               restarts the millisecond counter at 0. Reply {31'b0,on}.
  0x07         read one event: {1,on,note[6:0],velocity[6:0],ms[15:0]}, or when
               empty {0,overflow,14'b0,current ms}.
A retried request with the same sequence gets the cached reply (existing rule),
so a retry never consumes a second event. All other commands are unchanged; the
old controller answered 0x07/0x17 with status 2 (unknown command).
Apply to src/remote/{control/wifi_control.sv,wifi_core.sv,remote_control.sv}. Idempotent.
"""
from pathlib import Path
import sys

CTRL_PORT_OLD = ' output wire [223:0] key_map\n);\n reg [7:0] current_seq,current_cmd;\n'
CTRL_PORT_NEW = (' output wire [223:0] key_map,\n'
                 ' // Physical-key recording for the phone (commands 0x07/0x17).\n'
                 ' input wire rec_event,rec_on,input wire [6:0] rec_note,rec_velocity\n'
                 ');\n reg [7:0] current_seq,current_cmd;\n')
CTRL_DECL_OLD = ' integer i;\n'
CTRL_DECL_NEW = ''' integer i;
 // Recorder: 64 x {on,note,velocity,ms} in distributed RAM. The millisecond
 // counter restarts at 0 when recording is switched on.
 localparam integer MS_TICKS=CLK_HZ/1000;
 reg rec_enabled,rec_overflow;reg [15:0] rec_ms;reg [31:0] rec_tick;
 reg [30:0] rec_mem[0:63];reg [6:0] rec_wp,rec_rp;
 wire rec_empty=rec_wp==rec_rp;
 wire rec_full=rec_wp=={~rec_rp[6],rec_rp[5:0]};
 wire rec_write=rec_event && rec_enabled && !rec_full;
 wire [30:0] rec_head=rec_mem[rec_rp[5:0]];
 always @(posedge clk)if(rec_write)rec_mem[rec_wp[5:0]]<={rec_on,rec_note,rec_velocity,rec_ms};
'''
CTRL_RESET_OLD = '  checking_keys<=0;key_commit_safe<=0;key_scan_index<=0;key_seen<=0;\n'
CTRL_RESET_NEW = ('  checking_keys<=0;key_commit_safe<=0;key_scan_index<=0;key_seen<=0;\n'
                  '  rec_enabled<=0;rec_overflow<=0;rec_ms<=0;rec_tick<=0;rec_wp<=0;rec_rp<=0;\n')
CTRL_RUN_OLD = '  keymap_committed<=0;score_committed<=0;\n  if(response_valid && response_ready)response_valid<=0;\n'
CTRL_RUN_NEW = ('  keymap_committed<=0;score_committed<=0;\n'
                '  if(rec_tick>=32\'(MS_TICKS-1))begin rec_tick<=0;rec_ms<=rec_ms+1\'b1;end else rec_tick<=rec_tick+1\'b1;\n'
                '  if(rec_event && rec_enabled)begin if(rec_full)rec_overflow<=1;else rec_wp<=rec_wp+1\'b1;end\n'
                '  if(response_valid && response_ready)response_valid<=0;\n')
CTRL_CMD_OLD = "    8'h05:if(packet_len==0)reply(0,{keymap_revision,8'd0,8'd32});else reply(1,0);\n"
CTRL_CMD_NEW = CTRL_CMD_OLD + '''    8'h07:if(packet_len==0)begin
     if(!rec_empty)begin reply(0,{1'b1,rec_head});rec_rp<=rec_rp+1'b1;end
     else reply(0,{1'b0,rec_overflow,14'd0,rec_ms});
    end else reply(1,0);
    8'h17:if(packet_len==1 && p0<=1)begin
     rec_enabled<=p0[0];rec_rp<=rec_wp;rec_overflow<=0;
     if(p0[0])begin rec_ms<=0;rec_tick<=0;end
     reply(0,{31'd0,p0[0]});
    end else reply(1,0);
'''

CORE_PORT_OLD = ' output wire [223:0] key_map\n);\n wire rx_valid,rx_error;'
CORE_PORT_NEW = (' output wire [223:0] key_map,\n input wire rec_event,rec_on,input wire [6:0] rec_note,rec_velocity\n'
                 ');\n wire rx_valid,rx_error;')
CORE_INST_OLD = '  .score_committed(score_committed),.linked(linked),.key_map(key_map));\n'
CORE_INST_NEW = ('  .score_committed(score_committed),.linked(linked),.key_map(key_map),\n'
                 '  .rec_event(rec_event),.rec_on(rec_on),.rec_note(rec_note),.rec_velocity(rec_velocity));\n')

TOP_INST_OLD = '  .crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped_packets));\n wifi_score_player player('
TOP_INST_NEW = ('  .crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped_packets),\n'
                '  // Recorded: physical-key note events as the synth accepts them.\n'
                '  .rec_event(key_valid && key_ready),.rec_on(key_on),.rec_note(mapped_key_note),.rec_velocity(key_velocity[6:0]));\n'
                ' wifi_score_player player(')


def apply(s, pairs, marker):
    if marker in s:
        return s
    for old, new in pairs:
        assert s.count(old) == 1, old[:60]
        s = s.replace(old, new)
    return s


def rewrite(path, pairs, marker):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    s = raw.decode('utf-8').replace('\r\n', '\n')
    t = apply(s, pairs, marker)
    if t != s:
        path.write_bytes((t.replace('\n', '\r\n') if crlf else t).encode('utf-8'))
        print('updated', path)
    else:
        print('unchanged', path)


if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    rewrite(root / 'src/remote/control/wifi_control.sv',
            [(CTRL_PORT_OLD, CTRL_PORT_NEW), (CTRL_DECL_OLD, CTRL_DECL_NEW), (CTRL_RESET_OLD, CTRL_RESET_NEW),
             (CTRL_RUN_OLD, CTRL_RUN_NEW), (CTRL_CMD_OLD, CTRL_CMD_NEW)], 'Physical-key recording for the phone')
    rewrite(root / 'src/remote/wifi_core.sv', [(CORE_PORT_OLD, CORE_PORT_NEW), (CORE_INST_OLD, CORE_INST_NEW)], '.rec_event(rec_event)')
    rewrite(root / 'src/remote/remote_control.sv', [(TOP_INST_OLD, TOP_INST_NEW)], 'Recorded: physical-key note events')
