`default_nettype none
// Physical keys always use the original 32-voice piano. The phone's selected
// timbre belongs to score playback only and cannot retimbre held physical keys.
// Score ownership transitions fade/clear both allocators, FIFO and FX before
// changing the engine; held physical keys rearm only after returning to piano.
// Score playback temporarily owns note events, so a key NoteOff cannot cut a
// same-pitch automatic note. WAV is a separate stereo source.
module remote_control #(
 parameter [223:0] DEFAULT_KEYS=224'hb76acd8af5aad4a74a8d09f3a6cc972a4c88f1a2c4870a0c07ef9ebc
)(
 input wire clk,rst_n,sample_tick,uart_rx,output wire uart_tx,
 input wire [31:0] keys,input wire keys_valid,input wire key_valid,key_on,input wire [4:0] key_index,
 input wire [7:0] key_velocity,input wire [1:0] key_waveform,
 output wire key_ready,bridge_reset_n,
 output wire event_valid,event_on,output wire [6:0] event_note,
 output wire [7:0] event_velocity,output wire [1:0] event_waveform,
 input wire event_ready,engine_idle,input wire [4:0] fifo_level,
 output reg [2:0] instrument,output wire switching,output reg engine_clear,
 output reg [15:0] volume,output reg [4:0] effects,
 output wire score_playing,output wire [6:0] mapped_key_note,
 output wire [223:0] key_map,output reg [15:0] synth_gain,
 output wire display_score_sounding,display_score_rest,
 output wire [6:0] display_score_note,output wire [15:0] display_score_completed,
 output reg [1:0] performance_mode,output wire [31:0] guide_targets,
 output wire [2:0] guide_state,output wire [15:0] guide_completed
);
 wire cfg_valid,cfg_ready;wire [7:0] cfg_cmd;wire [15:0] cfg_value;
 wire [4:0] score_index,player_index;wire [31:0] score_event;wire [5:0] score_count;
 wire key_commit,score_commit,linked;wire [15:0] key_revision,score_revision;
 wire [31:0] crc_errors,format_errors,dropped_packets;
 reg [15:0] target_volume,tempo;reg [2:0] requested_instrument,selected_instrument;
 reg [2:0] switch_state;reg [12:0] clear_count;
 reg score_owned,pending_play,seen_player,player_start;
 wire player_playing;
 wire player_valid,player_on,player_ready;wire [6:0] player_note,player_velocity;
 assign display_score_note=player_note;
 wire tables_safe;
 reg guide_running,guide_start;
 reg [4:0] guide_index,scan_index;
 reg guide_sent,preflight_active,preflight_ok,preflight_bad;
 reg [31:0] guide_phase;
 wire guide_request;
 assign switching=switch_state!=0;
 wire play_stop=cfg_valid && cfg_ready && cfg_cmd==8'h15 && !cfg_value[0];
 wire timbre_stop=cfg_valid && cfg_ready && cfg_cmd==8'h11 &&
                  cfg_value[2:0]!=selected_instrument && score_owned;
 wire source_safe=!guide_running && !score_owned && keys==0 && !key_valid && fifo_level==0 && engine_idle;
 assign score_playing=score_owned;
 assign cfg_ready=(cfg_cmd==8'h10 && cfg_value==0) ||
  (cfg_cmd==8'h11 && !switching) ||
  ((cfg_cmd==8'h12 || cfg_cmd==8'h13 || cfg_cmd==8'h14) && sample_tick) ||
  (cfg_cmd==8'h16 && cfg_value<=2 && !switching && source_safe) ||
  (cfg_cmd==8'h15 && (!cfg_value[0] || (!switching && !score_playing && source_safe && score_count!=0 &&
   (performance_mode!=2 || (preflight_ok && keys_valid)))));
 assign bridge_reset_n=rst_n && !switching && !score_playing;
 assign key_ready=event_ready && bridge_reset_n;
 assign event_valid=!switching && (score_playing?player_valid:key_valid);
 assign event_on=score_playing?player_on:key_on;
 assign event_note=score_playing?player_note:mapped_key_note;
 assign event_velocity=score_playing?{1'b0,player_velocity}:key_velocity;
 assign event_waveform=score_playing?2'd0:key_waveform;
 assign player_ready=event_ready && !switching && score_owned;
 wifi_core #(.PERFORMANCE_ENABLE(1),.DEFAULT_KEYS(DEFAULT_KEYS)) core(
  .clk(clk),.rst_n(rst_n),.wifi_uart_rx(uart_rx),.wifi_uart_tx(uart_tx),
  .cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_cmd(cfg_cmd),.cfg_value(cfg_value),
  .actual_mode(2'd0),.actual_timbre(selected_instrument),
  .actual_performance(performance_mode),
  .performance_state(performance_mode==2?guide_state:
   score_owned?(switching?3'd1:display_score_rest?3'd6:3'd2):3'd0),
  .switching(switching),.system_fault(1'b0),
  .actual_volume(volume),.actual_tempo(tempo),.score_playing(score_playing || guide_running),
  .tables_safe(tables_safe && !switching && !score_owned && !guide_running && !guide_request),.keymap_safe(source_safe),
  .key_index(key_index),.key_note(mapped_key_note),.key_map(key_map),.score_index(score_index),.score_event(score_event),
  .score_count(score_count),.keymap_committed(key_commit),.score_committed(score_commit),
  .keymap_revision(key_revision),.score_revision(score_revision),.linked(linked),
  .crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped_packets),
  // Recorded: physical-key note events as the synth accepts them.
  .rec_event(key_valid && key_ready),.rec_on(key_on),.rec_note(mapped_key_note),.rec_velocity(key_velocity[6:0]));
 wifi_score_player player(
  .clk(clk),.rst_n(rst_n && !engine_clear),.sample_tick(sample_tick),
  .start(player_start),.stop(play_stop || timbre_stop),.abort_play(switching),.tempo(tempo),
  .score_count(score_count),.score_index(player_index),.score_event(score_event),
  .playing(player_playing),.tables_safe(tables_safe),.event_valid(player_valid),
  .event_ready(player_ready),.event_on(player_on),.event_note(player_note),.event_velocity(player_velocity),
  .display_sounding(display_score_sounding),.display_rest(display_score_rest),.display_completed(display_score_completed));
 // Guidance reads the committed score RAM, never a second unsynchronized copy.
 wire [31:0] guide_advance=guide_phase+32'(tempo)*32'd1000;
 wire guide_rest_clock=guide_state==3'd6 && keys_valid && keys==0;
 wire guide_ms=guide_rest_clock && sample_tick && guide_advance>=32'd5760000;
 assign guide_request=cfg_valid && cfg_cmd==8'h15 && cfg_value[0] && performance_mode==2;
 wire guide_launch=guide_request && cfg_ready;
 wire guide_stop=play_stop || performance_mode!=2;
 wire guide_event_ready,guide_step,guide_finished;
 reg [31:0] mapped_target;integer target_i;
 always @* begin
  mapped_target=0;
  for(target_i=0;target_i<32;target_i=target_i+1)
   if(key_map[target_i*7+:7]==score_event[6:0])mapped_target[target_i]=1;
 end
 assign score_index=performance_mode==2?(preflight_active?scan_index:guide_index):player_index;
 visual_guide_controller guide(
  .clk(clk),.rst_n(rst_n),.enable(performance_mode==2),.start(guide_start),.stop(guide_stop),
  .paused(1'b0),.tick_ms(guide_ms),.keys_valid(keys_valid),.keys(keys),
  .event_valid(guide_running && !guide_sent && !guide_start &&
   (score_event[14:8]==0 || mapped_target!=0)),.event_ready(guide_event_ready),
  .event_keys(score_event[14:8]==0?32'd0:mapped_target),.event_rest_ms(score_event[31:16]),
  .event_last({1'b0,guide_index}+6'd1>=score_count),
  .target_keys(guide_targets),.display_state(guide_state),.completed(guide_completed),
  .step_done(guide_step),.finished(guide_finished));
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  guide_running<=0;guide_start<=0;guide_index<=0;guide_sent<=0;guide_phase<=0;
  scan_index<=0;preflight_active<=0;preflight_ok<=0;preflight_bad<=0;
 end else begin
  guide_start<=0;
  if(!guide_request)begin preflight_active<=0;preflight_ok<=0;preflight_bad<=0;scan_index<=0;end
  else if(source_safe && !switching && keys_valid && score_count!=0)begin
   if(!preflight_active && !preflight_ok && !preflight_bad)begin preflight_active<=1;scan_index<=0;end
   else if(preflight_active)begin
    if(score_event[14:8]!=0 && mapped_target==0)begin preflight_active<=0;preflight_bad<=1;end
    else if({1'b0,scan_index}+6'd1>=score_count)begin preflight_active<=0;preflight_ok<=1;end
    else scan_index<=scan_index+1'b1;
   end
  end
  if(guide_launch)begin guide_running<=1;guide_start<=1;guide_index<=0;guide_sent<=0;guide_phase<=0;end
  else if((guide_stop || guide_finished) && !guide_start)begin guide_running<=0;guide_sent<=0;guide_phase<=0;end
  else if(guide_running)begin
   if(!guide_rest_clock)guide_phase<=0;
   else if(sample_tick)guide_phase<=guide_ms?guide_advance-32'd5760000:guide_advance;
   if(guide_event_ready && !guide_sent && !guide_start)guide_sent<=1;
   if(guide_step && {1'b0,guide_index}+6'd1<score_count)begin guide_index<=guide_index+1'b1;guide_sent<=0;guide_phase<=0;end
  end
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  performance_mode<=0;instrument<=0;requested_instrument<=0;selected_instrument<=0;switch_state<=0;clear_count<=0;
  score_owned<=0;pending_play<=0;seen_player<=0;player_start<=0;
  engine_clear<=0;volume<=65535;target_volume<=65535;synth_gain<=65535;tempo<=120;effects<=5'b10011;
 end else begin
  player_start<=0;
  if(score_owned && player_playing)seen_player<=1;
  // Keep score ownership through its final FIFO NoteOff and the complete
  // fade/clear. Switching the mux directly on player.playing loses that off.
  if(score_owned && seen_player && !player_playing && !switching && !pending_play)begin
   requested_instrument<=0;switch_state<=1;seen_player<=0;
  end
  if(sample_tick)begin
   if(switch_state==1)synth_gain<=synth_gain<=256?16'd0:synth_gain-16'd256;
   else if(switch_state==4)synth_gain<=synth_gain>=65279?16'd65535:synth_gain+16'd256;
   if(volume<target_volume)volume<=target_volume-volume<=256?target_volume:volume+16'd256;
   else if(volume>target_volume)volume<=volume-target_volume<=256?target_volume:volume-16'd256;
  end
  case(switch_state)
   1:if(synth_gain==0)begin engine_clear<=1;instrument<=requested_instrument;clear_count<=0;switch_state<=2;end
   2:if(clear_count==7)begin engine_clear<=0;clear_count<=0;switch_state<=3;end else clear_count<=clear_count+1'b1;
   3:if(clear_count==4095)begin switch_state<=4;clear_count<=0;end else clear_count<=clear_count+1'b1;
   4:if(synth_gain==65535)begin
    switch_state<=0;
    if(pending_play)begin player_start<=1;pending_play<=0;seen_player<=0;end
    else begin score_owned<=0;seen_player<=0;end
   end
   default:begin end
  endcase
  // Accepted commands take priority over an in-flight transition completing.
  if(cfg_valid && cfg_ready)case(cfg_cmd)
   8'h11:begin
    selected_instrument<=cfg_value[2:0];
    if(score_owned && !player_playing && cfg_value[2:0]!=selected_instrument)begin
     requested_instrument<=0;switch_state<=1;pending_play<=0;seen_player<=0;
    end
   end
   8'h12:target_volume<=cfg_value;
   8'h13:effects<=cfg_value[4:0];
   8'h14:tempo<=cfg_value;
   8'h16:performance_mode<=cfg_value[1:0];
   8'h15:if(cfg_value[0] && performance_mode!=2)begin
    performance_mode<=1;score_owned<=1;pending_play<=1;seen_player<=0;
    requested_instrument<=selected_instrument;switch_state<=1;
   end else if(score_owned)begin
    pending_play<=0;player_start<=0;
    // A running score first handshakes its final NoteOff. The normal end
    // detector then returns to piano. Preparation can be cancelled directly.
    if(switching || !player_playing)begin
     seen_player<=0;requested_instrument<=0;switch_state<=1;
    end
   end
   default:begin end
  endcase
 end
endmodule
`default_nettype wire
