`timescale 1ns/1ps
module tb_core;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0,rx=1,ready=1;wire tx,cv,linked,kc,sc;wire [7:0] cc;wire [15:0] value;
 wire [6:0] note;wire [31:0] event_data,ce,fe,de;wire [5:0] score_count;
 reg [7:0] requests[0:255],expected[0:255];integer n=0,i,j,k,config_count=0,reply_bytes=0;
 reg [7:0] data;reg check_replies=1;
 wifi_core #(.CLK_HZ(1000000),.BAUD(100000),.APPLY_TIMEOUT(200),.SESSION_TIMEOUT(200000)) dut(
  .clk(clk),.rst_n(rst_n),.wifi_uart_rx(rx),.wifi_uart_tx(tx),.cfg_valid(cv),.cfg_ready(ready),.cfg_cmd(cc),.cfg_value(value),
  .actual_volume(16'd65535),.actual_tempo(16'd120),.score_playing(1'b0),.score_revision(),.actual_mode(2'd0),.actual_timbre(3'd0),.switching(1'b0),.system_fault(1'b0),.keymap_revision(),.keymap_safe(1'b1),.tables_safe(1'b1),
  .key_index(5'd0),.key_note(note),.score_index(5'd0),.score_event(event_data),.score_count(score_count),
  .keymap_committed(kc),.score_committed(sc),.linked(linked),.crc_errors(ce),.format_errors(fe),.dropped_packets(de));
 always @(posedge clk)if(cv&&ready)config_count=config_count+1;
 task send_byte(input [7:0] x);
 begin @(negedge clk);rx=0;repeat(10)@(negedge clk);
 for(k=0;k<8;k=k+1)begin rx=x[k];repeat(10)@(negedge clk);end
 rx=1;repeat(10)@(negedge clk);end endtask
 // Independent UART decoder samples the physical TX waveform, not internal bytes.
 initial begin
  wait(rst_n);forever begin
   @(negedge tx);repeat(15)@(posedge clk);#1;
   for(j=0;j<8;j=j+1)begin data[j]=tx;repeat(10)@(posedge clk);#1;end
   if(tx!==1)$fatal(1,"TX stop bit");
   if(check_replies)begin
    if(data!==expected[reply_bytes])$fatal(1,"reply byte %d got %h expected %h",reply_bytes,data,expected[reply_bytes]);
    reply_bytes=reply_bytes+1;
   end
  end
 end
 initial begin
  $readmemh("sim/out/requests.hex",requests);$readmemh("sim/out/responses.hex",expected);
  repeat(5)@(negedge clk);rst_n=1;
  for(n=0;n<8;n=n+1)begin
   for(i=0;i<16;i=i+1)send_byte(requests[n*16+i]);
   wait(reply_bytes>=(n+1)*16);repeat(30)@(negedge clk);
  end
  if(config_count!=3||ce||fe||de)$fatal(1,"pipeline effects/errors %d",config_count);
  // Corrupted CRC: no reply, then valid request must recover.
  for(i=0;i<16;i=i+1)send_byte(i==15 ? requests[i]^8'h01 : requests[i]);
  repeat(2000)@(negedge clk);if(reply_bytes!=128||ce!=1)$fatal(1,"bad CRC not rejected");
  for(i=0;i<16;i=i+1)send_byte(requests[i]);wait(reply_bytes==144);
  if(config_count!=3)$fatal(1,"recovery applied config");
  repeat(200010)@(negedge clk);if(linked)$fatal(1,"link timeout");
  $display("PASS core: UART wire request -> CRC -> controller -> response CRC -> UART wire; retries once, bounds, bad CRC recovery and disconnect");$finish;
 end
 initial begin #10000000;$fatal(1,"watchdog");end
endmodule
