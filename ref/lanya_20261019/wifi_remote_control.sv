`default_nettype none
// Preferred main-engine entry: UART + request handshake + legacy NEXT adapter.
// Connect *_requested and actual_* to the original controllers, in this clock domain.
module wifi_remote_control #(parameter integer CLK_HZ=12288000,BAUD=115200,SAMPLE_RATE=48000)(
 input wire [4:0] key_index,output wire [6:0] key_note,
 input wire keymap_safe,output wire keymap_committed,output wire [15:0] keymap_revision,
 input wire clk,rst_n,wifi_uart_rx,output wire wifi_uart_tx,
 input wire sample_tick,pcm_valid,input wire signed [23:0] pcm_in,
 output wire pcm_out_valid,output wire signed [23:0] pcm_out,
 output wire score_event_valid,input wire score_event_ready,score_start_safe,output wire score_event_on,
 output wire [6:0] score_note,score_velocity,output wire score_playing,output wire [5:0] loaded_score_count,
 input wire [1:0] mode_requested,actual_mode,
 input wire [2:0] timbre_requested,actual_timbre,
 input wire mode_switching,timbre_switching,system_fault,
 input wire local_mode_event,local_timbre_event,
 output wire remote_mode_next,remote_timbre_next,adapter_fault,linked,
 output wire [31:0] crc_errors,format_errors,dropped_packets
);
 wire mv,mr,tv,tr;wire [1:0] mvalue;wire [2:0] tvalue;
 wire switching=mode_switching || timbre_switching;
 wifi_instrument_control #(.CLK_HZ(CLK_HZ),.BAUD(BAUD),.SAMPLE_RATE(SAMPLE_RATE)) endpoint(
  .key_index(key_index),.key_note(key_note),.keymap_safe(keymap_safe),.keymap_committed(keymap_committed),.keymap_revision(keymap_revision),
  .clk(clk),.rst_n(rst_n),.wifi_uart_rx(wifi_uart_rx),.wifi_uart_tx(wifi_uart_tx),
  .sample_tick(sample_tick),.pcm_valid(pcm_valid),.pcm_in(pcm_in),.pcm_out_valid(pcm_out_valid),.pcm_out(pcm_out),
  .score_event_valid(score_event_valid),.score_event_ready(score_event_ready),.score_start_safe(score_start_safe),.score_event_on(score_event_on),
  .score_note(score_note),.score_velocity(score_velocity),.score_playing(score_playing),.loaded_score_count(loaded_score_count),
  .mode_request_valid(mv),.mode_request_ready(mr),.mode_request(mvalue),
  .timbre_request_valid(tv),.timbre_request_ready(tr),.timbre_request(tvalue),
  .actual_mode(actual_mode),.actual_timbre(actual_timbre),.switching(switching),
  .system_fault(system_fault || adapter_fault),.linked(linked),
  .crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped_packets));
 wifi_request_steps #(.CLK_HZ(CLK_HZ)) steps(
  .clk(clk),.rst_n(rst_n),.switching(switching),.system_fault(system_fault),
  .local_mode_event(local_mode_event),.local_timbre_event(local_timbre_event),
  .mode_valid(mv),.mode_ready(mr),.mode_value(mvalue),.mode_requested(mode_requested),
  .timbre_valid(tv),.timbre_ready(tr),.timbre_value(tvalue),.timbre_requested(timbre_requested),
  .remote_mode_next(remote_mode_next),.remote_timbre_next(remote_timbre_next),.adapter_fault(adapter_fault));
endmodule
`default_nettype wire
