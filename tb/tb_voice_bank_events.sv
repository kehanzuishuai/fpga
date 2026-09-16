`timescale 1ns/1ps
module tb_voice_bank_events;
  logic clk=0,rst_n=0,sample_tick=1,note_on=0,note_off=0;
  logic [6:0] midi_note=0; logic [7:0] velocity=127;
  logic [1:0] waveform=0; logic [9:0] morph=0;
  logic [95:0] samples; logic [3:0] active;
  integer i;
  always #5 clk=~clk;
  voice_bank #(.VOICES(4),.SAMPLE_W(24),.AGE_W(8)) dut(.clk,.rst_n,.sample_tick,.note_on,.note_off,.midi_note,
    .velocity,.waveform,.morph,.voice_samples(samples),.voice_active(active));
  task press(input [6:0] n);
    begin @(negedge clk);midi_note=n;note_on=1;@(negedge clk);note_on=0; end
  endtask
  task reset_dut;
    begin @(negedge clk);rst_n=0;note_on=0;note_off=0;repeat(2)@(negedge clk);rst_n=1; end
  endtask
  initial begin
    repeat(3)@(posedge clk);rst_n=1;
    press(60);press(61); #1;
    if(active!==4'b0011 || dut.notes[6:0]!==7'd60 || dut.notes[13:7]!==7'd61)
      $fatal(1,"free Voice priority/mapping failed");
    press(62);press(63);press(70); #1;
    if(active!==4'b1111 || dut.notes[6:0]!==7'd70)
      $fatal(1,"full-bank oldest Voice steal failed");
    reset_dut();
    press(64);press(64); #1;
    if(active!==4'b0011 || dut.notes[6:0]!==7'd64 || dut.notes[13:7]!==7'd64)
      $fatal(1,"same-note retrigger did not allocate independent Voices");
    @(negedge clk);midi_note=64;note_off=1;#1;
    if(dut.stops!==4'b0011) $fatal(1,"note_off did not map to every repeated same-note Voice");
    @(negedge clk);note_off=0;
    reset_dut(); #1;
    if(active!==0 || dut.age_counter!==0) $fatal(1,"Voice bank reset failed");
    $display("TB_VOICE_BANK_EVENTS PASS: free-first, oldest steal, repeated-note and note_off mapping");
    $finish;
  end
endmodule
