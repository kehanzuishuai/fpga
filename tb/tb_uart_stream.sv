`timescale 1ns/1ps
module tb_uart_stream;
  localparam integer DIV=10;
  logic clk=0,rst_n=0;
  logic raw_valid=0,raw_ready,raw_tx; logic [7:0] raw_data=0;
  logic report_strobe=0,tel_tx,tel_busy;
  logic [5:0] active_count=6'd32;
  logic [23:0] peak=24'h12_34_56;
  logic signed [23:0] pcm=-24'sd2;
  integer i;
  reg [7:0] got;
  reg [7:0] expected_frame [0:19];
  always #5 clk=~clk;
  uart_tx #(.CLK_HZ(1000),.BAUD(100)) raw(.clk,.rst_n,.valid(raw_valid),.data(raw_data),.ready(raw_ready),.tx(raw_tx));
  telemetry_uart #(.CLK_HZ(1000),.BAUD(100)) telemetry(
    .clk,.rst_n,.report_strobe,.active_voice_count(active_count),.audio_peak(peak),.pcm_sample(pcm),.tx(tel_tx),.busy(tel_busy));
  task send_raw(input [7:0] value);
    begin
      while(!raw_ready) @(posedge clk);
      @(negedge clk); raw_data=value; raw_valid=1;
      @(negedge clk); raw_valid=0;
    end
  endtask
  task receive_raw(input integer which);
    integer b; reg [7:0] value;
    begin
      @(negedge raw_tx); repeat(DIV/2) @(posedge clk); #1;
      if(raw_tx!==0) $fatal(1,"UART %0d start bit invalid",which);
      for(b=0;b<8;b=b+1) begin repeat(DIV) @(posedge clk); #1; value[b]=raw_tx; end
      repeat(DIV) @(posedge clk); #1; if(raw_tx!==1) $fatal(1,"UART %0d stop bit invalid/short",which);
      case(which) 0:if(value!==8'h00)$fatal(1,"raw byte0");1:if(value!==8'hFF)$fatal(1,"raw byte1");2:if(value!==8'hA5)$fatal(1,"raw byte2");default:if(value!==8'h3C)$fatal(1,"raw byte3");endcase
    end
  endtask
  task receive_tel(input integer which);
    integer b; reg [7:0] value;
    begin
      @(negedge tel_tx); repeat(DIV/2) @(posedge clk); #1;
      if(tel_tx!==0) $fatal(1,"telemetry %0d start bit invalid",which);
      for(b=0;b<8;b=b+1) begin repeat(DIV) @(posedge clk); #1; value[b]=tel_tx; end
      repeat(DIV) @(posedge clk); #1; if(tel_tx!==1) $fatal(1,"telemetry %0d stop invalid",which);
      if(value!==expected_frame[which]) $fatal(1,"telemetry byte %0d mismatch got=%02x expected=%02x",which,value,expected_frame[which]);
    end
  endtask
  initial begin
    repeat(4) @(posedge clk); rst_n=1;
    fork
      begin send_raw(8'h00); send_raw(8'hFF); send_raw(8'hA5); send_raw(8'h3C); end
      begin receive_raw(0);receive_raw(1);receive_raw(2);receive_raw(3);end
    join
    expected_frame[0]=8'hA5; expected_frame[1]=8'h01; expected_frame[2]=8'h20;
    expected_frame[3]=8'h12; expected_frame[4]=8'h34; expected_frame[5]=8'h56;
    expected_frame[6]=8'hFF; expected_frame[7]=8'hFF; expected_frame[8]=8'hFE; expected_frame[9]=8'h0A;
    expected_frame[10]=8'hA5; expected_frame[11]=8'h01; expected_frame[12]=8'h03;
    expected_frame[13]=8'hAB; expected_frame[14]=8'hCD; expected_frame[15]=8'hEF;
    expected_frame[16]=8'h01; expected_frame[17]=8'h23; expected_frame[18]=8'h45; expected_frame[19]=8'h49;
    fork
      begin
        @(negedge clk); report_strobe=1; @(negedge clk); report_strobe=0;
        wait(!tel_busy); active_count=3; peak=24'hAB_CD_EF; pcm=24'h01_23_45;
        @(negedge clk); report_strobe=1; @(negedge clk); report_strobe=0;
      end
      begin for(i=0;i<20;i=i+1) receive_tel(i); end
    join
    wait(!tel_busy);
    $display("TB_UART_STREAM PASS: four continuous bytes, two telemetry frames, full stop bits and no skipped byte");
    $finish;
  end
endmodule
