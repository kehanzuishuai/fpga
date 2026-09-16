`timescale 1ns/1ps
module tb_fifo_stress;
  localparam integer TOTAL=40;
  logic clk=0,rst_n=0;
  logic in_valid=0,in_ready,in_note_on=0;
  logic [6:0] in_note=0; logic [7:0] in_velocity=0;
  logic [1:0] in_waveform=0; logic [9:0] in_morph=0;
  logic out_valid,out_ready=0,out_note_on;
  logic [6:0] out_note; logic [7:0] out_velocity;
  logic [1:0] out_waveform; logic [9:0] out_morph;
  logic [3:0] level;
  integer sent=0,received=0,cycles=0;
  always #5 clk=~clk;
  note_event_fifo #(.DEPTH(8)) dut(.clk,.rst_n,.in_valid,.in_ready,.in_note_on,.in_note,.in_velocity,
    .in_waveform,.in_morph,.out_valid,.out_ready,.out_note_on,.out_note,.out_velocity,.out_waveform,.out_morph,.level);
  always @(negedge clk) begin
    if(rst_n) begin
      out_ready <= ((cycles%4)!=0);
      if(sent<TOTAL) begin
        in_valid<=1; in_note_on<=sent[0]; in_note<=7'd30+sent[6:0];
        in_velocity<=8'd200-sent[7:0]; in_waveform<=sent[1:0]; in_morph<=sent*10'd23;
      end else in_valid<=0;
      cycles<=cycles+1;
    end
  end
  always @(posedge clk) if(rst_n) begin
    if(in_valid&&in_ready) sent<=sent+1;
    if(out_valid&&out_ready) begin
      if(out_note_on!==received[0] || out_note!==(7'd30+received[6:0]) ||
         out_velocity!==(8'd200-received[7:0]) || out_waveform!==received[1:0] ||
         out_morph!==(received*10'd23))
        $fatal(1,"FIFO payload/order mismatch at event %0d",received);
      received<=received+1;
    end
  end
  initial begin
    repeat(4) @(posedge clk); rst_n=1;
    while(received<TOTAL) begin @(posedge clk); if(cycles>300)$fatal(1,"FIFO stress timeout/lost event"); end
    @(posedge clk); #1;
    if(level!=0 || out_valid) $fatal(1,"FIFO did not drain cleanly");
    $display("TB_FIFO_STRESS PASS: %0d rapid events preserved under backpressure",TOTAL);
    $finish;
  end
endmodule
