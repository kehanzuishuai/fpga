`timescale 1ns/1ps
module tb_bridge;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0,rx=1;wire tx,mv,tv,linked;wire [1:0] mr;wire [2:0] tr;
 reg [1:0] actual_mode=0,target_mode=0;reg [2:0] actual_timbre=0,target_timbre=0;
 reg switching=0;integer countdown=0,applies=0;
 wire [31:0] ce,fe,de;
 wifi_instrument_control #(.CLK_HZ(1000000),.BAUD(100000)) dut(
  .clk(clk),.rst_n(rst_n),.key_index(5'd0),.key_note(),.keymap_safe(1'b1),.keymap_committed(),.keymap_revision(),.wifi_uart_rx(rx),.wifi_uart_tx(tx),
  .sample_tick(1'b1),.pcm_valid(1'b0),.pcm_in(24'sd0),.pcm_out_valid(),.pcm_out(),
  .score_event_valid(),.score_event_ready(1'b1),.score_start_safe(1'b1),.score_event_on(),.score_note(),.score_velocity(),.score_playing(),.loaded_score_count(),
  .mode_request_valid(mv),.mode_request_ready(1'b1),.mode_request(mr),
  .timbre_request_valid(tv),.timbre_request_ready(1'b1),.timbre_request(tr),
  .actual_mode(actual_mode),.actual_timbre(actual_timbre),.switching(switching),.system_fault(1'b0),
  .linked(linked),.crc_errors(ce),.format_errors(fe),.dropped_packets(de));
 // External instrument model. ACK is deliberately earlier than actual application.
 // The first query still sees switching; then the simulated held keys are released.
 always @(posedge clk)if(rst_n)begin
  if(mv)begin target_mode<=mr;switching<=1;applies<=applies+1;end
  if(tv)begin target_timbre<=tr;switching<=1;applies<=applies+1;end
  if(switching && dut.core.pkt_valid && dut.core.pkt_ready && dut.core.cmd==2)countdown<=100;
  else if(countdown>0)begin
   countdown<=countdown-1;
   if(countdown==1)begin actual_mode<=target_mode;actual_timbre<=target_timbre;switching<=0;end
  end
 end
 reg [7:0] requests[0:4095],expected[0:4095];reg [7:0] data;
 integer packets=10,n,i,k,j,reply_bytes=0,fd;
 task send_byte(input [7:0] b);
 begin
  @(negedge clk);rx=0;repeat(10)@(negedge clk);
  for(k=0;k<8;k=k+1)begin rx=b[k];repeat(10)@(negedge clk);end
  rx=1;repeat(10)@(negedge clk);
 end endtask
 initial begin
  wait(rst_n);forever begin
   @(negedge tx);repeat(15)@(posedge clk);#1;
   for(j=0;j<8;j=j+1)begin data[j]=tx;repeat(10)@(posedge clk);#1;end
   if(tx!==1)$fatal(1,"TX stop");
   if(data!==expected[reply_bytes])$fatal(1,"bridge reply byte %d got %h expected %h",reply_bytes,data,expected[reply_bytes]);
   $fdisplay(fd,"%02x",data);reply_bytes=reply_bytes+1;
  end
 end
 initial begin
  if($value$plusargs("TRACE_COUNT=%d",packets))begin end
  $readmemh("sim/out/bridge_requests.hex",requests);
  $readmemh("sim/out/bridge_expected.hex",expected);
  fd=$fopen("sim/out/bridge_rtl_responses.hex","w");
  repeat(5)@(negedge clk);rst_n=1;
  for(n=0;n<packets;n=n+1)begin
   for(i=0;i<16;i=i+1)send_byte(requests[n*16+i]);
   wait(reply_bytes>=(n+1)*16);repeat(30)@(negedge clk);
  end
  if(applies!=2||actual_mode!=2||actual_timbre!=3||switching||ce||fe||de||dut.applied_volume!=32768||dut.applied_tempo!=180||dut.loaded_score_count!=2||dut.score_playing)$fatal(1,"actual state or errors");
  $fclose(fd);
  $display("PASS shared ESP32 firmware packets -> physical UART -> FPGA adapter -> delayed actual state -> CRC UART replies");$finish;
 end
 initial begin #10000000;$fatal(1,"bridge watchdog");end
endmodule
