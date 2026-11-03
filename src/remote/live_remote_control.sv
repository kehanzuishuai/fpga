`default_nettype none
// One arbiter owns phone/buttons, source routing and keyboard engine clearing.
// source_mode: 0 keyboard, 1 continuous theremin, 2 duet.
// performance_mode: 0 free, 1 automatic score, 2 keyboard guidance.
module live_remote_control #(
 parameter [223:0] DEFAULT_KEYS=224'hb76acd8af5aad4a74a8d09f3a6cc972a4c88f1a2c4870a0c07ef9ebc,
 parameter integer CLEAR_TIMEOUT=245760
)(
 input wire clk,rst_n,sample_tick,uart_rx,output wire uart_tx,
 input wire timbre_next,source_next,
 input wire [31:0] keys,input wire keys_valid,key_valid,key_on,input wire [4:0] key_index,
 input wire [7:0] key_velocity,input wire [1:0] key_waveform,
 output wire [31:0] playable_keys,output wire key_ready,bridge_reset_n,
 output wire event_valid,event_on,output wire [6:0] event_note,
 output wire [7:0] event_velocity,output wire [1:0] event_waveform,
 input wire event_ready,engine_idle,engine_clear_done,input wire [4:0] fifo_level,
 output reg [2:0] instrument,output wire switching,output reg engine_clear,
 output reg [6:0] expression_velocity,expression_glide,expression_vibrato,
 output reg [15:0] volume,output reg [4:0] effects,
 output wire score_playing,output wire [6:0] mapped_key_note,
 output wire [223:0] key_map,output reg [15:0] synth_gain,mode_gain,
 output reg [1:0] source_mode,output reg theremin_clear,output reg switch_fault,
 output wire display_score_sounding,display_score_rest,
 output wire [6:0] display_score_note,output wire [15:0] display_score_completed,
 output reg [1:0] performance_mode,output wire [31:0] guide_targets,
 output wire [2:0] guide_state,output wire [15:0] guide_completed
);
 wire cfg_valid,cfg_ready;wire [7:0] cfg_cmd;wire [15:0] cfg_value;
 wire [4:0] score_index,player_index;wire [31:0] score_event;wire [5:0] score_count;
 wire key_commit,score_commit,linked;wire [15:0] key_revision,score_revision;
 wire [31:0] crc_errors,format_errors,dropped_packets;
 reg [15:0] target_volume,tempo; reg [2:0] selected_instrument;
 reg [1:0] requested_source;reg [2:0] switch_state;
 reg switch_all;reg [31:0] clear_count;reg [31:0] held_keys;
 reg score_owned,pending_play,seen_player,player_start;
 wire player_playing,player_valid,player_on,player_ready;
 wire legacy_playing,legacy_valid,legacy_on,legacy_ready;
 wire [6:0] legacy_note,legacy_velocity;
 wire legacy_sounding,legacy_rest;
 wire [15:0] legacy_completed;
 wire stream_valid,stream_on,stream_loaded,stream_playing,stream_fault;
 wire [6:0] stream_note,stream_velocity;
 reg stream_owned;
 wire [5:0] available_count=stream_loaded?6'd1:score_count;
 assign player_playing=stream_owned?stream_playing:legacy_playing;
 assign player_valid=stream_owned?stream_valid:legacy_valid;
 assign player_on=stream_owned?stream_on:legacy_on;
 assign player_note=stream_owned?stream_note:legacy_note;
 assign player_velocity=stream_owned?stream_velocity:legacy_velocity;
 assign legacy_ready=player_ready && !stream_owned;
 assign display_score_sounding=stream_owned?(stream_valid && stream_on):legacy_sounding;
 assign display_score_rest=stream_owned?1'b0:legacy_rest;
 assign display_score_completed=stream_owned?16'd0:legacy_completed;
 wire [6:0] player_note,player_velocity;wire tables_safe;
 reg guide_running,guide_start;reg [4:0] guide_index,scan_index;
 reg guide_sent,preflight_active,preflight_ok,preflight_bad;
 reg [31:0] guide_phase;
 assign switching=switch_state!=0;
 wire keyboard_running=!switch_fault && source_mode!=1 && (switch_state==0 || switch_state==4);
 assign playable_keys=keys & ~held_keys;
 assign bridge_reset_n=rst_n && keyboard_running && !score_owned;
 assign key_ready=event_ready && bridge_reset_n;
 assign event_valid=!switch_fault && keyboard_running && (score_owned?player_valid:key_valid);
 assign event_on=score_owned?player_on:key_on;
 assign event_note=score_owned?player_note:mapped_key_note;
 assign event_velocity=score_owned?{1'b0,player_velocity}:key_velocity;
 assign event_waveform=score_owned?2'd0:key_waveform;
 assign player_ready=event_ready && keyboard_running && score_owned;
 assign score_playing=score_owned;
 assign display_score_note=player_note;
 wire play_stop=cfg_valid && cfg_ready && cfg_cmd==8'h15 && !cfg_value[0];
 wire source_safe=!switch_fault && !switching && !guide_running && !score_owned && keys==0 && !key_valid && fifo_level==0 && engine_idle;
 assign cfg_ready=!switch_fault && (
  (cfg_cmd==8'h10 && cfg_value<=2 && !source_next) ||
  (cfg_cmd==8'h11 && cfg_value<=4 && !timbre_next) ||
  ((cfg_cmd==8'h12 || cfg_cmd==8'h13 || cfg_cmd==8'h14 || cfg_cmd==8'h18 || cfg_cmd==8'h19 || cfg_cmd==8'h1a) && sample_tick) ||
  (cfg_cmd==8'h16 && cfg_value<=2 && source_safe && (cfg_value==0 || source_mode!=1)) ||
  (cfg_cmd==8'h15 && (!cfg_value[0] || (source_safe && source_mode!=1 && available_count!=0 && !source_next && !timbre_next &&
   (performance_mode!=2 || (preflight_ok && keys_valid))))));

 // Complete recorded notes when a control transition clears their voices.
 // Only notes recorded in the current session need synthetic NoteOffs.
 wire rec_enabled,rec_restarted;reg [31:0] rec_down;
 function automatic [4:0] first_key(input [31:0] value);integer n;begin
  first_key=0;for(n=31;n>=0;n=n-1)if(value[n])first_key=5'(n);
 end endfunction
 wire rec_flush=switching && rec_enabled && !rec_restarted && |rec_down;
 wire [4:0] rec_index=first_key(rec_down);
 wire physical_accepted=key_valid && key_ready;
 reg [31:0] rec_down_next;
 always @* begin
  rec_down_next=(!rec_enabled || rec_restarted)?32'd0:rec_down;
  if(rec_enabled && physical_accepted)rec_down_next[key_index]=key_on;
  else if(rec_flush)rec_down_next[rec_index]=0;
 end
 always @(posedge clk or negedge rst_n)if(!rst_n)rec_down<=0;else rec_down<=rec_down_next;
 wifi_core #(.STREAM_ENABLE(1),.PERFORMANCE_ENABLE(1),.DEFAULT_KEYS(DEFAULT_KEYS)) core(
  .clk(clk),.rst_n(rst_n),.wifi_uart_rx(uart_rx),.wifi_uart_tx(uart_tx),
  .cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_cmd(cfg_cmd),.cfg_value(cfg_value),
  .actual_mode(source_mode),.actual_timbre(instrument),.actual_performance(performance_mode),
  .performance_state(performance_mode==2?guide_state:score_owned?(switching?3'd1:display_score_rest?3'd6:3'd2):3'd0),
  .switching(switching),.system_fault(switch_fault),.actual_volume(volume),.actual_tempo(tempo),
  .score_playing(score_owned || guide_running),
  .tables_safe(tables_safe && !switching && !score_owned && !guide_running && !guide_request),.keymap_safe(source_safe),
  .key_index(key_index),.key_note(mapped_key_note),.key_map(key_map),.score_index(score_index),.score_event(score_event),
  .score_count(score_count),.keymap_committed(key_commit),.score_committed(score_commit),
  .keymap_revision(key_revision),.score_revision(score_revision),.linked(linked),
  .crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped_packets),
  .rec_event(physical_accepted || rec_flush),.rec_on(rec_flush?1'b0:key_on),
  .rec_note(rec_flush?key_map[rec_index*7+:7]:mapped_key_note),.rec_velocity(rec_flush?7'd0:key_velocity[6:0]),
  .recording_enabled(rec_enabled),.recording_restarted(rec_restarted),
  .sample_tick(sample_tick),.stream_start(player_start && stream_owned),.stream_stop(play_stop),
  .stream_abort(switching || source_mode==1 || switch_fault),.stream_ready(player_ready && stream_owned),
  .stream_valid(stream_valid),.stream_on(stream_on),.stream_loaded(stream_loaded),.stream_playing(stream_playing),.stream_fault(stream_fault),
  .stream_note(stream_note),.stream_velocity(stream_velocity));
 wifi_score_player player(
  .clk(clk),.rst_n(rst_n && !engine_clear),.sample_tick(sample_tick),.start(player_start && !stream_owned),
  .stop(play_stop),.abort_play(switching || source_mode==1 || switch_fault),.tempo(tempo),
  .score_count(score_count),.score_index(player_index),.score_event(score_event),.playing(legacy_playing),
  .tables_safe(tables_safe),.event_valid(legacy_valid),.event_ready(legacy_ready),.event_on(legacy_on),
  .event_note(legacy_note),.event_velocity(legacy_velocity),.display_sounding(legacy_sounding),
  .display_rest(legacy_rest),.display_completed(legacy_completed));

 // The committed score/map remain the single source of guidance truth.
 wire [31:0] guide_advance=guide_phase+32'(tempo)*32'd1000;
 wire guide_rest_clock=guide_state==3'd6 && keys_valid && keys==0;
 wire guide_ms=guide_rest_clock && sample_tick && guide_advance>=32'd5760000;
 wire guide_request=cfg_valid && cfg_cmd==8'h15 && cfg_value[0] && performance_mode==2;
 wire guide_launch=guide_request && cfg_ready;
 wire guide_stop=play_stop || performance_mode!=2 || source_mode==1 || switch_fault;
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
  .paused(!keyboard_running || |held_keys),.tick_ms(guide_ms),.keys_valid(keys_valid),.keys(keys),
  .event_valid(guide_running && !guide_sent && !guide_start && (score_event[14:8]==0 || mapped_target!=0)),
  .event_ready(guide_event_ready),.event_keys(score_event[14:8]==0?32'd0:mapped_target),
  .event_rest_ms(score_event[31:16]),.event_last({1'b0,guide_index}+6'd1>=score_count),
  .target_keys(guide_targets),.display_state(guide_state),.completed(guide_completed),
  .step_done(guide_step),.finished(guide_finished));
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  guide_running<=0;guide_start<=0;guide_index<=0;guide_sent<=0;guide_phase<=0;
  scan_index<=0;preflight_active<=0;preflight_ok<=0;preflight_bad<=0;
 end else begin
  guide_start<=0;
  if(!guide_request)begin preflight_active<=0;preflight_ok<=0;preflight_bad<=0;scan_index<=0;end
  else if(source_safe && keys_valid && score_count!=0)begin
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
 task automatic begin_switch(input full_switch);
 begin
  switch_all<=full_switch;switch_state<=1;clear_count<=0;held_keys<=held_keys | keys;
 end endtask
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  performance_mode<=0;source_mode<=0;requested_source<=0;instrument<=0;selected_instrument<=0;
  switch_state<=0;switch_all<=0;clear_count<=0;engine_clear<=0;theremin_clear<=0;switch_fault<=0;held_keys<=0;
  score_owned<=0;pending_play<=0;seen_player<=0;player_start<=0;stream_owned<=0;
  volume<=65535;target_volume<=65535; expression_velocity<=8'd100; expression_glide<=0; expression_vibrato<=0;synth_gain<=65535;mode_gain<=65535;tempo<=120;effects<=5'b10011;
 end else begin
  player_start<=0;theremin_clear<=0;held_keys<=held_keys & keys;
  if(score_owned && player_playing)seen_player<=1;
  if(sample_tick)begin
   if(switch_state==1)begin
    if(switch_all)mode_gain<=mode_gain<=256?16'd0:mode_gain-16'd256;
    else synth_gain<=synth_gain<=256?16'd0:synth_gain-16'd256;
   end else if(switch_state==4)begin
    if(switch_all)mode_gain<=mode_gain>=65279?16'd65535:mode_gain+16'd256;
    else synth_gain<=synth_gain>=65279?16'd65535:synth_gain+16'd256;
   end
   if(volume<target_volume)volume<=target_volume-volume<=256?target_volume:volume+16'd256;
   else if(volume>target_volume)volume<=volume-target_volume<=256?target_volume:volume-16'd256;
  end
  if(!switch_fault)case(switch_state)
   0:begin
    if(requested_source!=source_mode || selected_instrument!=instrument)begin
     begin_switch(requested_source!=source_mode);pending_play<=0;score_owned<=0;seen_player<=0;
     if(requested_source!=source_mode || performance_mode==1)performance_mode<=0;
    end else if(score_owned && seen_player && !player_playing && !pending_play)begin
     begin_switch(0);seen_player<=0;performance_mode<=0;
    end
   end
   1:if(switch_all?mode_gain==0:synth_gain==0)begin engine_clear<=1;clear_count<=0;switch_state<=2;end
   2:if(clear_count==7)begin engine_clear<=0;clear_count<=0;switch_state<=3;end else clear_count<=clear_count+1'b1;
   3:if(engine_clear_done)begin
    instrument<=selected_instrument;held_keys<=held_keys | keys;clear_count<=0;switch_state<=4;
    if(switch_all)begin source_mode<=requested_source;theremin_clear<=1;end
   end else if(clear_count==32'(CLEAR_TIMEOUT-1))begin switch_fault<=1;mode_gain<=0;synth_gain<=0;end
   else clear_count<=clear_count+1'b1;
   4:if(switch_all?mode_gain==65535:synth_gain==65535)begin
    switch_state<=0;
    if(pending_play && requested_source==source_mode && selected_instrument==instrument && source_mode!=1)begin
     player_start<=1;pending_play<=0;seen_player<=0;
    end else begin pending_play<=0;score_owned<=0;seen_player<=0;end
   end
   default:begin switch_fault<=1;mode_gain<=0;synth_gain<=0;end
  endcase
  // Last accepted target wins. Local pulses delay a same-kind phone handshake.
  if(cfg_valid && cfg_ready)case(cfg_cmd)
   8'h10:requested_source<=cfg_value[1:0];
   8'h11:selected_instrument<=cfg_value[2:0];
   8'h12:target_volume<=cfg_value;
   8'h13:effects<=cfg_value[4:0];
   8'h14:tempo<=cfg_value; 8'h18:expression_velocity<=cfg_value[7:0]; 8'h19:expression_glide<=cfg_value[7:0]; 8'h1a:expression_vibrato<=cfg_value[7:0];
   8'h16:performance_mode<=cfg_value[1:0];
   8'h15:if(cfg_value[0] && performance_mode!=2)begin
    stream_owned<=stream_loaded;performance_mode<=1;score_owned<=1;pending_play<=1;seen_player<=0;begin_switch(0);
   end else if(!cfg_value[0] && score_owned && !player_playing)begin
    pending_play<=0;seen_player<=0;performance_mode<=0;
    if(switch_state==0)begin_switch(0);
   end
   default:begin end
  endcase
  if(!switch_fault)begin
   if(timbre_next)selected_instrument<=selected_instrument==4?3'd0:selected_instrument+3'd1;
   if(source_next)requested_source<=requested_source==2?2'd0:requested_source+2'd1;
  end
 end
endmodule
`default_nettype wire

