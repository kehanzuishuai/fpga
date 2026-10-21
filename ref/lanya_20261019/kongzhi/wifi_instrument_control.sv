`default_nettype none
module wifi_instrument_control #(parameter integer CLK_HZ=12288000,BAUD=115200,SAMPLE_RATE=48000)(
 input wire [4:0] key_index,output wire [6:0] key_note,
 input wire keymap_safe,output wire keymap_committed,output wire [15:0] keymap_revision,
 input wire clk,rst_n,wifi_uart_rx,output wire wifi_uart_tx,
 input wire sample_tick,pcm_valid,input wire signed [23:0] pcm_in,
 output wire pcm_out_valid,output wire signed [23:0] pcm_out,
 output wire mode_request_valid,input wire mode_request_ready,output wire [1:0] mode_request,
 output wire timbre_request_valid,input wire timbre_request_ready,output wire [2:0] timbre_request,
 input wire [1:0] actual_mode,input wire [2:0] actual_timbre,
 input wire switching,system_fault,
 output wire score_event_valid,input wire score_event_ready,score_start_safe,output wire score_event_on,
 output wire [6:0] score_note,score_velocity,output wire score_playing,output wire [5:0] loaded_score_count,
 output wire linked,output wire [31:0] crc_errors,format_errors,dropped_packets
);
 wire cfg_valid,cfg_ready;wire [7:0] cfg_cmd;wire [15:0] cfg_value;
 wire unused_score_commit;wire [15:0] unused_revision;
 wire [31:0] event_data;wire [4:0] event_index;wire [15:0] applied_volume;
 reg [15:0] applied_tempo;
 wire available=!switching && !system_fault;
 wire player_safe,volume_ready;
 wire volume_cfg=cfg_valid && cfg_cmd==8'h12;
 wire tempo_ready=cfg_cmd==8'h14 && sample_tick;
 wire play_ready=cfg_cmd==8'h15 && (cfg_value==0 || (available && actual_mode!=1 && !score_playing && loaded_score_count!=0 && score_event_ready && score_start_safe));
 assign mode_request_valid=cfg_valid && cfg_cmd==8'h10 && available;
 assign timbre_request_valid=cfg_valid && cfg_cmd==8'h11 && available;
 assign mode_request=cfg_value[1:0];assign timbre_request=cfg_value[2:0];
 assign cfg_ready=(mode_request_valid && mode_request_ready) ||
                  (timbre_request_valid && timbre_request_ready) ||
                  (cfg_cmd==8'h12 && volume_ready) || tempo_ready || play_ready;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)applied_tempo<=120;
 else if(cfg_valid && tempo_ready)applied_tempo<=cfg_value;
 wifi_volume volume(.clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),.cfg_valid(volume_cfg),.cfg_value(cfg_value),
 .cfg_ready(volume_ready),.actual_volume(applied_volume),.pcm_valid(pcm_valid),.pcm_in(pcm_in),.out_valid(pcm_out_valid),.pcm_out(pcm_out));
 wifi_score_player #(.SAMPLE_RATE(SAMPLE_RATE)) player(.clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),
 .start(cfg_valid && play_ready && cfg_value==1),.stop(cfg_valid && play_ready && cfg_value==0),.abort_play(!available),
 .tempo(applied_tempo),.score_count(loaded_score_count),.score_index(event_index),.score_event(event_data),
 .playing(score_playing),.tables_safe(player_safe),.event_valid(score_event_valid),.event_ready(score_event_ready),
 .event_on(score_event_on),.event_note(score_note),.event_velocity(score_velocity));
 wifi_core #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) core(
  .clk(clk),.rst_n(rst_n),.wifi_uart_rx(wifi_uart_rx),.wifi_uart_tx(wifi_uart_tx),
  .cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_cmd(cfg_cmd),.cfg_value(cfg_value),
  .actual_mode(actual_mode),.actual_timbre(actual_timbre),.switching(switching),.system_fault(system_fault),
  .actual_volume(applied_volume),.actual_tempo(applied_tempo),.score_playing(score_playing),.score_revision(unused_revision),
  .tables_safe(player_safe && available),.keymap_safe(keymap_safe),.keymap_revision(keymap_revision),.key_index(key_index),.key_note(key_note),.score_index(event_index),.score_event(event_data),
  .score_count(loaded_score_count),.keymap_committed(keymap_committed),.score_committed(unused_score_commit),
  .linked(linked),.crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped_packets));
endmodule
`default_nettype wire
