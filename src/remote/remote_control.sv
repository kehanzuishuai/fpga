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
 input wire [31:0] keys,input wire key_valid,key_on,input wire [4:0] key_index,
 input wire [7:0] key_velocity,input wire [1:0] key_waveform,
 output wire key_ready,bridge_reset_n,
 output wire event_valid,event_on,output wire [6:0] event_note,
 output wire [7:0] event_velocity,output wire [1:0] event_waveform,
 input wire event_ready,engine_idle,input wire [4:0] fifo_level,
 output reg [2:0] instrument,output wire switching,output reg engine_clear,
 output reg [15:0] volume,output reg [4:0] effects,
 output wire score_playing,output wire [6:0] mapped_key_note,
 output wire [223:0] key_map,output reg [15:0] synth_gain
);
 wire cfg_valid,cfg_ready;wire [7:0] cfg_cmd;wire [15:0] cfg_value;
 wire [4:0] score_index;wire [31:0] score_event;wire [5:0] score_count;
 wire key_commit,score_commit,linked;wire [15:0] key_revision,score_revision;
 wire [31:0] crc_errors,format_errors,dropped_packets;
 reg [15:0] target_volume,tempo;reg [2:0] requested_instrument,selected_instrument;
 reg [2:0] switch_state;reg [12:0] clear_count;
 reg score_owned,pending_play,seen_player,player_start;
 wire player_playing;
 wire player_valid,player_on,player_ready;wire [6:0] player_note,player_velocity;
 wire tables_safe;
 assign switching=switch_state!=0;
 wire play_stop=cfg_valid && cfg_ready && cfg_cmd==8'h15 && !cfg_value[0];
 wire timbre_stop=cfg_valid && cfg_ready && cfg_cmd==8'h11 &&
                  cfg_value[2:0]!=selected_instrument && score_owned;
 wire source_safe=!score_owned && keys==0 && !key_valid && fifo_level==0 && engine_idle;
 assign score_playing=score_owned;
 assign cfg_ready=(cfg_cmd==8'h10 && cfg_value==0) ||
  (cfg_cmd==8'h11 && !switching) ||
  ((cfg_cmd==8'h12 || cfg_cmd==8'h13 || cfg_cmd==8'h14) && sample_tick) ||
  (cfg_cmd==8'h15 && (!cfg_value[0] || (!switching && !score_playing && source_safe && score_count!=0)));
 assign bridge_reset_n=rst_n && !switching && !score_playing;
 assign key_ready=event_ready && bridge_reset_n;
 assign event_valid=!switching && (score_playing?player_valid:key_valid);
 assign event_on=score_playing?player_on:key_on;
 assign event_note=score_playing?player_note:mapped_key_note;
 assign event_velocity=score_playing?{1'b0,player_velocity}:key_velocity;
 assign event_waveform=score_playing?2'd0:key_waveform;
 assign player_ready=event_ready && !switching && score_owned;
 wifi_core #(.DEFAULT_KEYS(DEFAULT_KEYS)) core(
  .clk(clk),.rst_n(rst_n),.wifi_uart_rx(uart_rx),.wifi_uart_tx(uart_tx),
  .cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_cmd(cfg_cmd),.cfg_value(cfg_value),
  .actual_mode(2'd0),.actual_timbre(selected_instrument),.switching(switching),.system_fault(1'b0),
  .actual_volume(volume),.actual_tempo(tempo),.score_playing(score_playing),
  .tables_safe(tables_safe && !switching && !score_owned),.keymap_safe(source_safe),
  .key_index(key_index),.key_note(mapped_key_note),.key_map(key_map),.score_index(score_index),.score_event(score_event),
  .score_count(score_count),.keymap_committed(key_commit),.score_committed(score_commit),
  .keymap_revision(key_revision),.score_revision(score_revision),.linked(linked),
  .crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped_packets));
 wifi_score_player player(
  .clk(clk),.rst_n(rst_n && !engine_clear),.sample_tick(sample_tick),
  .start(player_start),.stop(play_stop || timbre_stop),.abort_play(switching),.tempo(tempo),
  .score_count(score_count),.score_index(score_index),.score_event(score_event),
  .playing(player_playing),.tables_safe(tables_safe),.event_valid(player_valid),
  .event_ready(player_ready),.event_on(player_on),.event_note(player_note),.event_velocity(player_velocity));
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  instrument<=0;requested_instrument<=0;selected_instrument<=0;switch_state<=0;clear_count<=0;
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
   8'h15:if(cfg_value[0])begin
    score_owned<=1;pending_play<=1;seen_player<=0;
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
