`default_nettype none
// Read-only import of the validated UNO control protocol, in the audio domain.
// Control packets carry continuous frequency/level, never recorded PCM.
module theremin_receiver #(parameter integer CLK_HZ=12288000,SAMPLE_RATE=48000,LINK_TIMEOUT_MS=100)(
 input wire clk,rst_n,sample_tick,uart_rx,enabled,clear,
 output wire signed [23:0] pcm,output wire pcm_valid,
 output wire linked,calibrating,sensor_fault,
 output wire [31:0] frequency_mhz,output wire [15:0] amplitude,
 output wire [31:0] crc_errors,format_errors
);
 wire [7:0] byte_data,sequence_id,flags;wire byte_valid,byte_error,packet_valid,update;
 wire [31:0] raw_frequency;wire [15:0] raw_amplitude,timestamp_ms;
 tl_uart_rx #(.CLK_HZ(CLK_HZ),.BAUD(115200)) rx(clk,rst_n,uart_rx,byte_data,byte_valid,byte_error);
 tl_packet_rx #(.CLK_HZ(CLK_HZ)) parser(clk,rst_n,byte_valid,byte_data,byte_error,
  packet_valid,sequence_id,flags,raw_frequency,raw_amplitude,timestamp_ms,crc_errors,format_errors);
 tl_link_guard #(.CLK_HZ(CLK_HZ),.TIMEOUT_MS(LINK_TIMEOUT_MS)) guard(clk,rst_n,packet_valid,
  sequence_id,flags,raw_frequency,raw_amplitude,update,linked,calibrating,sensor_fault,frequency_mhz,amplitude);
 wire [31:0] phase_increment;wire [15:0] level;
 tl_parameters #(.SAMPLE_RATE(SAMPLE_RATE)) params(clk,rst_n,sample_tick,update,linked,enabled,clear,
  frequency_mhz,amplitude,phase_increment,level);
 wire [15:0] unused_frame;
 tl_dds dds(clk,rst_n,sample_tick,clear,phase_increment,level,16'd0,pcm,pcm_valid,unused_frame);
endmodule
`default_nettype wire
