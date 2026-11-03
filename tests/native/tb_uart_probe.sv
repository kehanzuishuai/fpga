`timescale 1ns/1ps
module tb_uart_probe;
 // Real independent 12.288 MHz FPGA clock and 115200 baud external UART.
 localparam real BIT_NS=1000000000.0/115200.0;
 reg clk=0;always #40.690104167 clk=~clk;
 reg rst_n=0,rx=1;wire tx,linked;
 wire [31:0] crc_errors,format_errors,dropped;
 wifi_core #(.STREAM_ENABLE(1),.PERFORMANCE_ENABLE(1)) dut(
  .clk(clk),.rst_n(rst_n),.wifi_uart_rx(rx),.wifi_uart_tx(tx),
  .cfg_valid(),.cfg_ready(1'b1),.cfg_cmd(),.cfg_value(),
  .actual_mode(2'd0),.actual_timbre(3'd0),.actual_performance(2'd0),.performance_state(3'd0),
  .switching(1'b0),.system_fault(1'b0),.tables_safe(1'b1),.keymap_safe(1'b1),
  .actual_volume(16'hffff),.actual_tempo(16'd120),.score_playing(1'b0),
  .score_revision(),.keymap_revision(),.key_index(5'd0),.key_note(),
  .score_index(5'd0),.score_event(),.score_count(),.keymap_committed(),.score_committed(),
  .linked(linked),.crc_errors(crc_errors),.format_errors(format_errors),.dropped_packets(dropped),
  .key_map(),.rec_event(1'b0),.rec_on(1'b0),.rec_note(7'd0),.rec_velocity(7'd0),
  .recording_enabled(),.recording_restarted(),.sample_tick(1'b0),.stream_start(1'b0),.stream_stop(1'b0),.stream_abort(1'b0),.stream_ready(1'b1),
  .stream_valid(),.stream_on(),.stream_loaded(),.stream_playing(),.stream_fault(),.stream_note(),.stream_velocity());
 reg [7:0] requests[0:191],b;integer i,j,k,got=0,outfile;
 // Decode the FPGA output with an external UART model, not its own RX RTL.
 initial begin
  outfile=$fopen("replies.hex","w");if(!outfile)$fatal(1,"reply file");
  forever begin
   @(negedge tx);#(BIT_NS*1.5);
   for(k=0;k<8;k=k+1)begin b[k]=tx;#(BIT_NS);end
   if(tx!==1'b1)$fatal(1,"reply stop bit");
   $fdisplay(outfile,"%02x",b);got=got+1;
  end
 end
 initial begin
  $readmemh("requests.hex",requests);
  repeat(5)@(negedge clk);rst_n=1;#(BIT_NS*2);
  for(i=0;i<12;i=i+1)begin
   for(j=0;j<16;j=j+1)begin
    rx=0;#(BIT_NS);
    for(integer bit_index=0;bit_index<8;bit_index=bit_index+1)begin
     rx=requests[i*16+j][bit_index];#(BIT_NS);
    end
    rx=1;#(BIT_NS);
   end
   wait(got==(i+1)*16);#(BIT_NS*2);
  end
  if(!linked||crc_errors||format_errors||dropped)$fatal(1,"protocol diagnostics");
  $fclose(outfile);
  $display("PASS production wifi_core real UART: 12 requests, 12 replies, zero CRC/format/drop errors");
  $finish;
 end
 initial begin #100000000;$fatal(1,"UART reply timeout");end
endmodule
