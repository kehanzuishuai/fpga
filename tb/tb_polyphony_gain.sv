`timescale 1ns/1ps
module tb_polyphony_gain;
  logic signed [28:0] mixed;
  logic [5:0] count;
  logic signed [28:0] scaled,scaled_master;
  logic [5:0] shift,shift_master;
  polyphony_gain #(.VOICES(32),.SAMPLE_W(24)) dut(
    .mixed_in(mixed),.active_voice_count(count),.scaled_out(scaled),.applied_shift(shift));
  polyphony_gain #(.VOICES(32),.SAMPLE_W(24),.MASTER_ATTEN_SHIFT(1)) dut_master(
    .mixed_in(mixed),.active_voice_count(count),.scaled_out(scaled_master),.applied_shift(shift_master));
  initial begin
    count=1;mixed=29'sd1000000;#1;
    if(shift!=0||scaled!=1000000)$fatal(1,"single Voice was attenuated");
    if(shift_master!=1||scaled_master!=500000)$fatal(1,"master attenuation parameter failed");
    count=2;mixed=29'sd2000000;#1;if(shift!=1||scaled!=1000000)$fatal(1,"2-Voice gain failed");
    count=3;mixed=29'sd3000000;#1;if(shift!=2||scaled!=750000)$fatal(1,"3-Voice headroom failed");
    count=4;mixed=29'sd4000000;#1;if(shift!=2||scaled!=1000000)$fatal(1,"4-Voice gain failed");
    count=17;mixed=29'sd17000000;#1;if(shift!=5||scaled!=531250)$fatal(1,"17-Voice headroom failed");
    count=32;mixed=29'sd32000000;#1;if(shift!=5||scaled!=1000000)$fatal(1,"32-Voice headroom failed");
    $display("TB_POLYPHONY_GAIN PASS: single Voice unity, active-count headroom and master attenuation");
    $finish;
  end
endmodule
