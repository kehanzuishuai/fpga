"""Apply the reviewed main-path integration once, preserving legacy defaults."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
def edit(name, changes):
 p=root/name;s=p.read_text(encoding='utf-8-sig')
 for before,after in changes:
  if before not in s:raise RuntimeError(f'{name}: missing {before[:80]}')
  s=s.replace(before,after)
 p.write_text(s,encoding='utf-8')
edit('src/synth_core.v',[
 ('parameter SAMPLE_RATE        = 48000,','parameter REMOTE_ENABLE = 0,\n    parameter SAMPLE_RATE        = 48000,'),
 ('input                              sample_tick,','input                              sample_tick,\n    input [2:0] instrument_id,'),
 ('wire [VOICES*SAMPLE_W-1:0] samples;','wire [VOICES*SAMPLE_W-1:0] samples;\nwire [VOICES-1:0] piano_active;\nwire piano_ready,aux_ready;\nwire signed [23:0] aux_pcm;\nwire [VOICES-1:0] aux_active;\nwire auxiliary=REMOTE_ENABLE!=0 && instrument_id!=0;\nassign active_debug=auxiliary?aux_active:piano_active;\nassign event_ready=auxiliary?aux_ready:piano_ready;\ngenerate if(REMOTE_ENABLE!=0)begin:G_AUX\n wire valid, rejected;wire [VOICES-1:0] overruns,clips;\n yinse_aux_bank #(.VOICES(VOICES),.MIX_SHIFT(3)) bank(\n .clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),.all_notes_off(test_disable_pulse),\n .event_valid(auxiliary && (bank_on || bank_off)),.event_note_on(bank_on),\n .instrument_id(instrument_id),.event_note(bank_note),.event_velocity(bank_velocity),\n .event_ready(aux_ready),.pcm(aux_pcm),.pcm_valid(valid),.active_mask(aux_active),\n .overrun_mask(overruns),.clipped_mask(clips),.rejected(rejected));\nend else begin:G_NO_AUX\n assign aux_ready=0;assign aux_pcm=0;assign aux_active=0;\nend endgenerate'),
 ('.note_on          (bank_on),','.note_on          (bank_on && !auxiliary),'),
 ('.note_off         (bank_off),','.note_off         (bank_off && !auxiliary),'),
 ('.event_ready      (event_ready),','.event_ready      (piano_ready),'),
 ('.voice_active     (active_debug),','.voice_active     (piano_active),'),
 ('wire signed [SAMPLE_W-1:0] sat_out;','wire signed [SAMPLE_W-1:0] sat_out;\nwire signed [MIX_W-1:0] selected_sum=auxiliary?{{(MIX_W-24){aux_pcm[23]}},aux_pcm}:normalized_sum;'),
 ('.in (normalized_sum),','.in (selected_sum),'),
 ('.in_sample         (normalized_sum),','.in_sample         (selected_sum),'),
 ('.soundboard_enable (fx_ctrl[0]),','.soundboard_enable (fx_ctrl[0] && !auxiliary),'),
])
edit('src/instruments/gongyong/yinse_aux_bank.sv',[
 ('parameter integer VOICES=16,MAX_DELAY=1024','parameter integer VOICES=16,MAX_DELAY=1024,MIX_SHIFT=$clog2(VOICES)'),
 ('localparam integer SHIFT=$clog2(VOICES);','localparam integer SHIFT=MIX_SHIFT;'),
])
edit('src/synth_event_frontend.v',[
 ('parameter VOICES      = 32,','parameter REMOTE_ENABLE = 0,\n    parameter VOICES      = 32,'),
 ('input                              sample_tick,','input                              sample_tick,\n    input [2:0] instrument_id,\n    output wire engine_idle,'),
 ('wire       core_ready;','wire       core_ready;\nassign engine_idle=core_ready && fifo_level==0;'),
 ('synth_core #(\n','synth_core #(\n    .REMOTE_ENABLE(REMOTE_ENABLE),'),
 ('.sample_tick         (sample_tick),','.sample_tick         (sample_tick),\n    .instrument_id(instrument_id),'),
])
p=root/'src/synth_top.v';s=p.read_text(encoding='utf-8-sig')
s=s.replace('parameter CLK_HZ', 'parameter REMOTE_ENABLE=0,\n    parameter CLK_HZ',1)
assert 'REMOTE_ENABLE=0' in s
anchor='    input                           test_enable,'
assert anchor in s
s=s.replace(anchor,anchor+'''\n    input [2:0] instrument_id,
    input engine_clear,
    input [15:0] remote_volume,
    input signed [23:0] wav_left,wav_right,
    output wire remote_sample_tick,engine_idle,''')
s=s.replace('assign visual_pcm = audio_out;','''wire signed [23:0] final_left,final_right;
assign remote_sample_tick=sample_tick;
wire engine_rst_n=rst_n && !(REMOTE_ENABLE!=0 && engine_clear);
generate if(REMOTE_ENABLE!=0)begin:G_MASTER
 stereo_master master(clk,rst_n,remote_volume,audio_out,wav_left,wav_right,
                      final_left,final_right,visual_pcm);
end else begin:G_ORIGINAL
 assign final_left=audio_out;assign final_right=audio_out;assign visual_pcm=audio_out;
end endgenerate''')
s=s.replace('.left_sample  (audio_out)','.left_sample  (final_left)').replace('.right_sample (audio_out)','.right_sample (final_right)')
s=s.replace('synth_event_frontend #(\n','synth_event_frontend #(\n    .REMOTE_ENABLE(REMOTE_ENABLE),')
start=s.index(') u_synth (');end=s.index('\n);',start)
part=s[start:end].replace('(rst_n)','(engine_rst_n)',1)
part=part.replace('.sample_tick         (sample_tick),','.sample_tick         (sample_tick),\n    .instrument_id(instrument_id),.engine_idle(engine_idle),')
s=s[:start]+part+s[end:];p.write_text(s,encoding='utf-8')
edit('src/remote/control/wifi_control.sv',[
 ('60+(i%16)+(i/16)*12','60+i'),
 ('packet_cmd==8\'h10 && packet_len==1 && p0<=2',"packet_cmd==8'h10 && packet_len==1 && p0==0"),
 ('end else reply(1,0);\n    end\n    8\'h20:',"end else if(packet_cmd==8'h10 && packet_len==1 && p0<=2)reply(2,0);else reply(1,0);\n    end\n    8'h20:"),
])
# Keep the same piano hierarchy and debug names; remote is an explicit opt-in.
p=root/'src/tang_mega_138k_pro_top.v.v';s=p.read_text(encoding='utf-8-sig')
s=s.replace('    input  wire rst_n,','''    input  wire rst_n,
    input wire esp_uart_rx,output wire esp_uart_tx,
    input wire esp_spi_sck,esp_spi_cs_n,esp_spi_mosi,output wire esp_spi_miso,''',1)
s=s.replace('wire       event_ready;','''wire       event_ready;
wire key_event_ready,bridge_reset_n,remote_tick,engine_idle,engine_clear,switching,score_playing;
wire [2:0] actual_instrument;wire [15:0] master_volume;wire [4:0] remote_fx;
wire remote_valid,remote_on;wire [6:0] remote_note,mapped_key_note;
wire [7:0] remote_velocity;wire [1:0] remote_waveform;
wire signed [23:0] wav_left,wav_right;
remote_control u_remote(
 .clk(clk_12m288),.rst_n(synth_rst_n),.sample_tick(remote_tick),
 .uart_rx(esp_uart_rx),.uart_tx(esp_uart_tx),.keys(key_state32),
 .key_valid(event_valid),.key_on(event_note_on),.key_index(event_key_index),
 .key_velocity(event_velocity),.key_waveform(event_waveform),.key_ready(key_event_ready),
 .bridge_reset_n(bridge_reset_n),.event_valid(remote_valid),.event_on(remote_on),
 .event_note(remote_note),.event_velocity(remote_velocity),.event_waveform(remote_waveform),
 .event_ready(event_ready),.engine_idle(engine_idle),.fifo_level(fifo_level),
 .instrument(actual_instrument),.switching(switching),.engine_clear(engine_clear),
 .volume(master_volume),.effects(remote_fx),.score_playing(score_playing),.mapped_key_note(mapped_key_note));
wav_remote u_wav(clk_50m,clk_12m288,synth_rst_n,remote_tick,
 esp_spi_sck,esp_spi_cs_n,esp_spi_mosi,esp_spi_miso,wav_left,wav_right);''')
a=s.index(') u_ttp229_event_bridge (');b=s.index('\n);',a)
part=s[a:b].replace('(synth_rst_n)','(bridge_reset_n)').replace('(event_ready)','(key_event_ready)')
s=s[:a]+part+s[b:]
s=s.replace('wire key_event_accepted=event_valid && event_ready;','wire key_event_accepted=event_valid && key_event_ready;')
s=s.replace('key_last_accepted_midi<=event_note','key_last_accepted_midi<=mapped_key_note')
s=s.replace('synth_top #(\n','synth_top #(\n    .REMOTE_ENABLE(1),')
a=s.index(') u_synth_top (');b=s.index('\n);',a);part=s[a:b]
for old,new in [('event_valid','remote_valid'),('event_note_on','remote_on'),('event_note','remote_note'),('event_velocity','remote_velocity'),('event_waveform','remote_waveform')]:
 part=part.replace('('+old+')','('+new+')')
part=part.replace("((BUILD_STAGE >= 3) ? 5'b1_00_1_1 : 5'b0_00_0_0)","((BUILD_STAGE >= 3) ? remote_fx : 5'b0_00_0_0)")
part+='''
    ,.instrument_id(actual_instrument),.engine_clear(engine_clear),.remote_volume(master_volume),
    .wav_left(wav_left),.wav_right(wav_right),.remote_sample_tick(remote_tick),.engine_idle(engine_idle)
'''
s=s[:a]+part+s[b:];p.write_text(s,encoding='utf-8')
print('Integrated main RTL with opt-in remote controls and stereo output.')
