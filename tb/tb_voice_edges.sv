`timescale 1ns/1ps
module tb_voice_edges;
  logic clk=0,rst_n=0,tick=0,start=0,stop=0;
  logic a_full,a_half,a_zero; logic [6:0] n0,n1,n2; logic [31:0] p0,p1,p2;
  logic signed [23:0] s_full,s_half,s_zero;
  integer i;
  always #5 clk=~clk;
  voice full(.clk,.rst_n,.sample_tick(tick),.start,.stop,.phase_inc_in(32'h1000_0000),.note_in(7'd60),.velocity_in(8'd127),.waveform_in(2'd1),.morph_in(10'd0),.active(a_full),.note(n0),.phase_inc(p0),.sample(s_full));
  voice half(.clk,.rst_n,.sample_tick(tick),.start,.stop,.phase_inc_in(32'h1000_0000),.note_in(7'd60),.velocity_in(8'd64),.waveform_in(2'd1),.morph_in(10'd0),.active(a_half),.note(n1),.phase_inc(p1),.sample(s_half));
  voice zero(.clk,.rst_n,.sample_tick(tick),.start,.stop,.phase_inc_in(32'h1000_0000),.note_in(7'd60),.velocity_in(8'd0),.waveform_in(2'd1),.morph_in(10'd0),.active(a_zero),.note(n2),.phase_inc(p2),.sample(s_zero));
  task one_tick; begin @(negedge clk);tick=1;@(negedge clk);tick=0;end endtask
  function [23:0] mag(input logic signed [23:0] value); begin mag=value[23]?-value:value; end endfunction
  initial begin
    repeat(3)@(posedge clk);rst_n=1;
    @(negedge clk);start=1;@(negedge clk);start=0;
    for(i=0;i<20;i=i+1)one_tick(); #1;
    if(!a_full||!a_half||!a_zero)$fatal(1,"velocity Voices inactive");
    if(s_zero!==0)$fatal(1,"velocity zero did not mute output");
    if(mag(s_full)==0 || mag(s_half)==0 || mag(s_half)>=mag(s_full))$fatal(1,"velocity scaling order failed");
    if(mag(s_full)>24'h7f_ffff || mag(s_half)>24'h7f_ffff)$fatal(1,"velocity/ADSR scaling overflow");
    stop=1;@(negedge clk);stop=0;for(i=0;i<2000;i=i+1)one_tick();
    if(a_full||a_half||a_zero)$fatal(1,"release boundary failed");
    $display("TB_VOICE_EDGES PASS: velocity 0/64/127, ADSR Q scaling, saturation and release");
    $finish;
  end
endmodule
