`timescale 1ns/1ps
module tb_current_piano_zero;
 reg clk=0,rst_n=0,tick=0,on=0,off=0;reg [7:0] vel=100;
 always #5 clk=~clk;
 integer cycle=0;
 always @(negedge clk)begin cycle=cycle+1;tick=cycle%256==0;end
 wire ready;wire [31:0] active;
 synth_core dut(.clk(clk),.rst_n(rst_n),.sample_tick(tick),.note_on(on),.note_off(off),
 .midi_note(7'd69),.velocity(vel),.waveform(2'b00),.morph_enable(1'b0),.morph(10'd0),
 .test_enable(1'b0),.hammer_enable(1'b1),.fx_ctrl(5'b10011),.event_ready(ready),.active_debug(active));
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
  on=1;@(negedge clk);on=0;repeat(4000)@(negedge clk);
  if(!ready || active==0)$fatal(1,"precondition: loaded piano note missing");
  vel=0;on=1;#1;
  if(dut.u_bank.starts!=0 || dut.u_bank.stops==0)
   $fatal(1,"current src treats velocity-zero NoteOn as START, not NoteOff; stuck/retrigger risk");
  $display("PASS current piano velocity-zero NoteOn becomes NoteOff");$finish;
 end
 initial begin #100000;$fatal(1,"watchdog");end
endmodule
