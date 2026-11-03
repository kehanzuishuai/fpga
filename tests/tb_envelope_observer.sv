`timescale 1ns/1ps
module tb_envelope_observer;
 reg clk=0;always #1 clk=~clk;reg rst=0,start=0,stop=0,clear=0,bypass=0,manual=0;
 wire [15:0] envelope;wire env_active;wire [2:0] env_phase;
 yinse_envelope env(.clk(clk),.rst_n(rst),.sample_tick(1'b1),.start(start),.stop(stop),.clear(clear),
 .attack_step(16'd4096),.decay_step(16'd4096),.sustain_level(16'd32768),.release_step(16'd2048),
 .level(envelope),.active(env_active),.observe_phase(env_phase));
 reg [511:0] mg=0;reg [95:0] mp=0;reg [31:0] mv=0,md=0,ms=0,ma=0;
 wire [127:0] history;wire [4:0] voice_index;wire [2:0] phase;
 visual_envelope_history #(.SAMPLE_RATE(3200)) dut(
 .clk(clk),.rst_n(rst),.sample_tick(1'b1),.clear(clear),.bypass(bypass),.instrument(manual?3'd0:3'd1),
 .active(manual?ma:{31'd0,env_active}),.gains(manual?mg:{496'd0,envelope}),.phases(manual?mp:{93'd0,env_phase}),
 .gain_valid(manual?mv:32'd1),.gain_done(manual?md:32'd1),.starts(manual?ms:{31'd0,start}),
 .history(history),.voice_index(voice_index),.phase(phase));
 task gain(input [15:0] v);begin @(negedge clk);mg[17*16+:16]=v;mv=1<<17;@(negedge clk);mv=0;end endtask
 initial begin
  repeat(4)@(negedge clk);rst=1;repeat(2)@(negedge clk);if(phase!=7||history!=0)$fatal(1,"idle");
  start=1;@(negedge clk);start=0;if(phase!=1)$fatal(1,"A");
  wait(env_phase==2);@(negedge clk);if(phase!=2)$fatal(1,"D");
  wait(env_phase==3);repeat(800)@(negedge clk);if(phase!=3||history==0||voice_index!=0)$fatal(1,"S history");
  stop=1;@(negedge clk);stop=0;if(phase!=4)$fatal(1,"R");
  wait(!env_active);repeat(1700)@(negedge clk);if(phase!=0||history!=0)$fatal(1,"release zero");
  bypass=1;@(negedge clk);if(phase!=6||history!=0)$fatal(1,"bypass");bypass=0;manual=1;
  @(negedge clk);ma=1<<17;ms=1<<17;mp[17*3+:3]=2;@(negedge clk);ms=0;
  if(voice_index!=17||phase!=2||history!=0)$fatal(1,"observed voice selection");
  gain(100);gain(900);gain(400);md=1<<17;@(negedge clk);md=0;
  if(dut.current_gain!=900)$fatal(1,"partial max is not real gain");
  repeat(105)@(negedge clk);if(history==0)$fatal(1,"piano history");
  if(dut.normalized(16'd900,16'd1800)!=112)$fatal(1,"common normalization");
  clear=1;@(negedge clk);clear=0;if(phase!=7||history!=0)$fatal(1,"clear");
  $display("PASS actual ADSR A/D/S/R observation, per-note history, release-to-zero, bypass/clear, voice17 selection and 16-partial gain maximum; no PCM input");$finish;
 end
 initial begin #100000;$fatal(1,"observer timeout");end
endmodule
