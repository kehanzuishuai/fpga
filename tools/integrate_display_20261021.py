"""One-time, backed-up import. Leaves source delivery and phone UI untouched."""
from pathlib import Path
import hashlib,json,shutil,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1]
S=Path('E:/xianshi(shengjiban)')
A=R/'audit/display_integration_20261021'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def edit(name,old,new):
    p=R/name;s=p.read_text(encoding='utf-8');assert s.count(old)==1,(name,old,s.count(old))
    p.write_text(s.replace(old,new),encoding='utf-8')
assert not (A/'BEFORE.json').exists(),'One-time integration already started'
A.mkdir(parents=True,exist_ok=True)
paths=[p for p in (R/'src').rglob('*') if p.is_file()]
paths += [R/'yinyue_fashengqi.gprj',R/'impl/yinyue_fashengqi_process_config.json',R/'README.md']
for name in ['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/gwsynthesis/yinyue_fashengqi.vg']:
    if (R/name).is_file():paths.append(R/name)
before={p.relative_to(R).as_posix():sha(p) for p in paths}
for p in paths:
    q=A/'backup'/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
phone={p.relative_to(R).as_posix():sha(p) for p in (R/'firmware').rglob('*') if p.is_file()}
(A/'BEFORE.json').write_text(json.dumps({'files':before,'phone_unchanged':phone},indent=2),encoding='utf-8')
selected=['visual_audio_core.sv','visual_status_cdc.sv','visual_scene.sv','visual_background.sv',
 'visual_raster.v','visual_labels.sv','visual_renderer.sv','visual_xy_plot.sv','visual_xy_source.sv',
 'visual_fft.sv','visual_frame_store.v','visual_twiddle_rom.v','visual_tmds.sv']
for name in selected:shutil.copy2(S/'src'/name,R/'src/display'/name)
(R/'assets').mkdir(exist_ok=True)
for p in (S/'assets').glob('bg_*.hex'):shutil.copy2(p,R/'assets'/p.name)
for name in ['README.md','DISPLAY_STATUS.md','INTEGRATION.md','GUIDE_INTEGRATION.md','MATERIAL_V2.md','SPECTRUM_DISPLAY.md','MANIFEST.json']:
    q=A/'delivery'/name;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(S/name,q)

# Observation-only ports; no new dependencies from audio control onto display.
edit('src/voice_bank.v','output wire [47:0]                 diagnostic_counts',
 'output wire [47:0]                 diagnostic_counts,\n    output wire [VOICES*7-1:0] display_voice_notes')
edit('src/voice_bank.v','wire [VOICES*7-1:0] notes;',
 'wire [VOICES*7-1:0] notes;\nassign display_voice_notes=notes;')
edit('src/instruments/gongyong/yinse_aux_bank.sv','output wire [VOICES-1:0] clipped_mask,output reg rejected',
 'output wire [VOICES-1:0] clipped_mask,output reg rejected,\n output wire [VOICES*7-1:0] display_voice_notes')
edit('src/instruments/gongyong/yinse_aux_bank.sv','wire [VOICES*7-1:0] notes;',
 'wire [VOICES*7-1:0] notes;\n assign display_voice_notes=notes;')
edit('src/synth_core.v','output wire [95:0]                diagnostic_audio',
 'output wire [95:0]                diagnostic_audio,\n    output wire [VOICES*7-1:0] display_voice_notes')
edit('src/synth_core.v','wire [VOICES-1:0] piano_active;',
 'wire [VOICES-1:0] piano_active;\nwire [VOICES*7-1:0] piano_notes,aux_notes;\nassign display_voice_notes=auxiliary?aux_notes:piano_notes;')
edit('src/synth_core.v','.rejected(rejected));','.rejected(rejected),.display_voice_notes(aux_notes));')
edit('src/synth_core.v','assign aux_ready=0;assign aux_pcm=0;assign aux_active=0;',
 'assign aux_ready=0;assign aux_pcm=0;assign aux_active=0;assign aux_notes=0;')
edit('src/synth_core.v','.diagnostic_counts(diagnostic_counts)',
 '.diagnostic_counts(diagnostic_counts),.display_voice_notes(piano_notes)')
for name in ['src/synth_event_frontend.v','src/synth_top.v']:
    p=R/name;s=p.read_text();key='diagnostic_chain\n);';assert s.count(key)==1
    s=s.replace(key,'diagnostic_chain,\n    output wire [VOICES*7-1:0] display_voice_notes'+
        (',\n    output wire signed [23:0] display_left,display_right' if name.endswith('synth_top.v') else '')+'\n);')
    if name.endswith('synth_event_frontend.v'):
        s=s.replace('.diagnostic_audio    (diagnostic_audio)', '.diagnostic_audio    (diagnostic_audio),\n    .display_voice_notes(display_voice_notes)')
    else:
        s=s.replace('.diagnostic_chain    (diagnostic_chain)', '.diagnostic_chain    (diagnostic_chain),\n    .display_voice_notes(display_voice_notes)')
        s=s.replace('wire master_clipped,engine_clipped;',
         'assign display_left=final_left;assign display_right=final_right;\nwire master_clipped,engine_clipped;')
    p.write_text(s,encoding='utf-8')

# Player outputs describe accepted NoteOn/Off and naturally completed events.
edit('src/remote/control/wifi_score_player.sv','output wire [6:0] event_note,event_velocity',
 'output wire [6:0] event_note,event_velocity,\n output wire display_sounding,display_rest,output reg [15:0] display_completed')
edit('src/remote/control/wifi_score_player.sv','assign playing=state!=IDLE;',
 'assign playing=state!=IDLE;\n assign display_sounding=sounding;\n assign display_rest=state==RUN && !sounding;')
edit('src/remote/control/wifi_score_player.sv','task automatic advance_note;\n begin',
 'task automatic advance_note;\n begin\n  if(display_completed!=16\'hffff)display_completed<=display_completed+16\'d1;')
edit('src/remote/control/wifi_score_player.sv','phase<=0;sounding<=0;stopping<=0;end',
 'phase<=0;sounding<=0;stopping<=0;display_completed<=0;end')
edit('src/remote/control/wifi_score_player.sv','begin score_index<=0;state<=LOAD;end',
 'begin score_index<=0;state<=LOAD;display_completed<=0;end')
edit('src/remote/remote_control.sv','output wire [223:0] key_map,output reg [15:0] synth_gain',
 'output wire [223:0] key_map,output reg [15:0] synth_gain,\n output wire display_score_sounding,display_score_rest,\n output wire [6:0] display_score_note,output wire [15:0] display_score_completed')
edit('src/remote/remote_control.sv','wire player_valid,player_on,player_ready;wire [6:0] player_note,player_velocity;',
 'wire player_valid,player_on,player_ready;wire [6:0] player_note,player_velocity;\n assign display_score_note=player_note;')
edit('src/remote/remote_control.sv','.event_ready(player_ready),.event_on(player_on),.event_note(player_note),.event_velocity(player_velocity));',
 '.event_ready(player_ready),.event_on(player_on),.event_note(player_note),.event_velocity(player_velocity),\n  .display_sounding(display_score_sounding),.display_rest(display_score_rest),.display_completed(display_score_completed));')

p=R/'src/tang_mega_138k_pro_top.v.v';s=p.read_text()
s=s.replace('wire signed [23:0] wav_left,wav_right;',
 'wire signed [23:0] wav_left,wav_right;\nwire display_score_sounding,display_score_rest;\nwire [6:0] display_score_note;wire [15:0] display_score_completed;')
s=s.replace('.key_map(remote_key_map),.synth_gain(synth_gain));',
 '.key_map(remote_key_map),.synth_gain(synth_gain),\n .display_score_sounding(display_score_sounding),.display_score_rest(display_score_rest),\n .display_score_note(display_score_note),.display_score_completed(display_score_completed));')
s=s.replace('wire signed [23:0] visual_pcm;',
 'wire signed [23:0] visual_pcm;\nwire [223:0] display_voice_notes;wire signed [23:0] display_left,display_right;')
s=s.replace('.visual_pcm(visual_pcm),.visual_pcm_valid(visual_pcm_valid),',
 '.visual_pcm(visual_pcm),.visual_pcm_valid(visual_pcm_valid),\n .display_voice_notes(display_voice_notes),.display_left(display_left),.display_right(display_right),')
a=s.index('reg [6:0] status_note;');b=s.index('wire [9:0] video_blue',a)
s=s[:a]+'''wire display_status_ready,display_status_update;
wire [511:0] display_status_data;
reg [1:0] display_banks_seen;
always @(posedge clk_12m288 or negedge synth_rst_n)
if(!synth_rst_n)display_banks_seen<=0;
else display_banks_seen<=display_banks_seen | key_bank_frame_valid;
display_status_adapter u_display_status(
 .clk(clk_12m288),.rst_n(synth_rst_n),.pcm_valid(visual_pcm_valid),
 .pcm_left(display_left),.pcm_right(display_right),
 .keys_valid(&display_banks_seen),.keys(key_state32),.key_map(remote_key_map),
 .instrument(actual_instrument),.voices(active_debug),.voice_notes(display_voice_notes),
 .score_owned(score_playing),.switching(switching),.score_sounding(display_score_sounding),
 .score_rest(display_score_rest),.score_note(display_score_note),.score_completed(display_score_completed),
 .status_ready(display_status_ready),.status_update(display_status_update),.status_data(display_status_data));
''' +s[b:]
s=s.replace('audio_visualizer #(.LOGN(11),.SAMPLE_RATE(48000),.STATUS_ENABLE(1),.REMOTE_STATUS(1),.MAPPING_CONFIRMED(KEY_MAPPING_CONFIRMED)) u_visual(',
 'visual_audio_core #(.LOGN(11),.SAMPLE_RATE(48000)) u_visual(')
s=s.replace('.status_audio(status_audio));',
 '.status_update(display_status_update),.status_data(display_status_data),.status_ready(display_status_ready));')
s=s.replace('assign fft_dropped=0;assign wave_dropped=0;assign spectrum_dropped=0;',
 'assign fft_dropped=0;assign wave_dropped=0;assign spectrum_dropped=0;assign display_status_ready=0;')
p.write_text(s,encoding='utf-8')

# Keep legacy adapter/HUD sources on disk, but don't compile incompatible old renderer caller.
p=R/'yinyue_fashengqi.gprj';s=p.read_text()
s=s.replace('path="src/display/audio_visualizer.sv" type="file.verilog" enable="1"',
 'path="src/display/audio_visualizer.sv" type="file.verilog" enable="0"')
added=['visual_audio_core.sv','visual_status_cdc.sv','visual_scene.sv','visual_background.sv','display_status_adapter.sv']
s=s.replace('    </FileList>',''.join(f'        <File path="src/display/{n}" type="file.verilog" enable="1"/>\n' for n in added)+'    </FileList>')
p.write_text(s,encoding='utf-8')
assert all(sha(R/n)==h for n,h in phone.items())
(A/'IMPORT.json').write_text(json.dumps({'imported_rtl':{n:sha(S/'src'/n) for n in selected},
 'assets':{p.name:sha(p) for p in (R/'assets').glob('bg_*.hex')},'phone_unchanged':True,
 'preserved_clock_and_io':['src/display/visual_video_clock.v','src/display/visual_dvi_io.v','src/integrated.cst','src/integrated.sdc']},indent=2),encoding='utf-8')
print('Imported display and observation ports; no phone or audio algorithm changes.')
