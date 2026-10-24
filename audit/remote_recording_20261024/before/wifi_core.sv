`default_nettype none
module wifi_core #(parameter integer PERFORMANCE_ENABLE=0,CLK_HZ=12288000,BAUD=115200,
 APPLY_TIMEOUT=CLK_HZ/5,SESSION_TIMEOUT=CLK_HZ*5,
 parameter [223:0] DEFAULT_KEYS=224'hb76acd8af5aad4a74a8d09f3a6cc972a4c88f1a2c4870a0c07ef9ebc)(
 input wire clk,rst_n,wifi_uart_rx,output wire wifi_uart_tx,
 output wire cfg_valid,input wire cfg_ready,
 output wire [7:0] cfg_cmd,output wire [15:0] cfg_value,
 input wire [1:0] actual_mode,input wire [2:0] actual_timbre,
 input wire [1:0] actual_performance,input wire [2:0] performance_state,
 input wire switching,system_fault,tables_safe,keymap_safe,
 input wire [15:0] actual_volume,actual_tempo,input wire score_playing,
 output wire [15:0] score_revision,keymap_revision,
 input wire [4:0] key_index,output wire [6:0] key_note,
 input wire [4:0] score_index,output wire [31:0] score_event,
 output wire [5:0] score_count,output wire keymap_committed,score_committed,linked,
 output wire [31:0] crc_errors,format_errors,dropped_packets,
 output wire [223:0] key_map
);
 wire rx_valid,rx_error;wire [7:0] rx_data;
 wire pkt_valid,pkt_ready;wire [7:0] seq,cmd,len;wire [47:0] payload;
 wire rsp_valid,rsp_ready;wire [7:0] rsp_seq;wire [47:0] rsp_payload;
 wire tx_valid,tx_ready;wire [7:0] tx_data;
 wifi_uart_rx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) u_rx(
  .clk(clk),.rst_n(rst_n),.rx(wifi_uart_rx),.data(rx_data),.valid(rx_valid),.framing_error(rx_error));
 wifi_packet_rx #(.CLK_HZ(CLK_HZ)) parser(
  .clk(clk),.rst_n(rst_n),.byte_valid(rx_valid),.byte_error(rx_error),.byte_data(rx_data),
  .packet_valid(pkt_valid),.packet_ready(pkt_ready),.packet_seq(seq),.packet_cmd(cmd),
  .packet_len(len),.packet_payload(payload),.crc_errors(crc_errors),
  .format_errors(format_errors),.dropped_packets(dropped_packets));
 wifi_control #(.PERFORMANCE_ENABLE(PERFORMANCE_ENABLE),.DEFAULT_KEYS(DEFAULT_KEYS),.CLK_HZ(CLK_HZ),.APPLY_TIMEOUT(APPLY_TIMEOUT),.SESSION_TIMEOUT(SESSION_TIMEOUT)) control(
  .clk(clk),.rst_n(rst_n),.packet_valid(pkt_valid),.packet_ready(pkt_ready),
  .packet_seq(seq),.packet_cmd(cmd),.packet_len(len),.packet_payload(payload),
  .response_valid(rsp_valid),.response_ready(rsp_ready),.response_seq(rsp_seq),.response_payload(rsp_payload),
  .cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_cmd(cfg_cmd),.cfg_value(cfg_value),
  .actual_mode(actual_mode),.actual_timbre(actual_timbre),
  .actual_performance(actual_performance),.performance_state(performance_state),.switching(switching),.system_fault(system_fault),
  .actual_volume(actual_volume),.actual_tempo(actual_tempo),.score_playing(score_playing),.score_revision(score_revision),
  .tables_safe(tables_safe),.keymap_safe(keymap_safe),.keymap_revision(keymap_revision),.key_index(key_index),.key_note(key_note),.score_index(score_index),
  .score_event(score_event),.score_count(score_count),.keymap_committed(keymap_committed),
  .score_committed(score_committed),.linked(linked),.key_map(key_map));
 wifi_packet_tx serializer(.clk(clk),.rst_n(rst_n),.response_valid(rsp_valid),.response_ready(rsp_ready),
  .response_seq(rsp_seq),.response_payload(rsp_payload),.byte_valid(tx_valid),.byte_ready(tx_ready),.byte_data(tx_data));
 wifi_uart_tx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) u_tx(
  .clk(clk),.rst_n(rst_n),.valid(tx_valid),.data(tx_data),.ready(tx_ready),.tx(wifi_uart_tx));
endmodule
`default_nettype wire
