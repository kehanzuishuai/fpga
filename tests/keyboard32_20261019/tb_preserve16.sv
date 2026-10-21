`timescale 1ns/1ps
module tb_preserve16;
 reg clk50=0,rst=0;always #10 clk50=~clk50;
 reg[15:0]touch=0;wire a_scl,a_sdo,b_scl,b_sdo,scl2;
 ttp229_bfm #(.KEY16(1),.MULTI(1)) ka(touch,a_scl,a_sdo),kb(touch,b_scl,b_sdo);
 wire[6:0]pins_a,pins_b;
 baseline_board #(.DISPLAY_ENABLE(0)) oldboard(.clk_50m(clk50),.rst_n(rst),.ttp229_scl(a_scl),.ttp229_sdo(a_sdo),
 .i2s_bclk(pins_a[0]),.i2s_lrck(pins_a[1]),.i2s_data(pins_a[2]),.pcm5102_bclk(pins_a[3]),.pcm5102_lrck(pins_a[4]),.pcm5102_data(pins_a[5]),.audio_pa_en(pins_a[6]));
 tang_mega_138k_pro_top #(.DISPLAY_ENABLE(0)) newboard(.clk_50m(clk50),.rst_n(rst),.ttp229_scl(b_scl),.ttp229_sdo(b_sdo),
 .ttp229_2_scl(scl2),.ttp229_2_sdo(1'b1),
 .i2s_bclk(pins_b[0]),.i2s_lrck(pins_b[1]),.i2s_data(pins_b[2]),.pcm5102_bclk(pins_b[3]),.pcm5102_lrck(pins_b[4]),.pcm5102_data(pins_b[5]),.audio_pa_en(pins_b[6]));
 integer cycles=0,samples=0,nonzero=0,events=0;
 wire clk=newboard.clk_12m288;
 always @(posedge clk)begin
  #0.001;
  if(newboard.synth_rst_n)begin
   cycles++;
   if(pins_a!==pins_b || oldboard.u_synth_top.audio_out!==newboard.u_synth_top.audio_out ||
      oldboard.key_state!==newboard.key_state || a_scl!==b_scl ||
      oldboard.active_debug!==newboard.active_debug)$fatal(1,"original16 PCM/DAC/keyboard regression");
   if(newboard.key_state32[31:16]!==0)$fatal(1,"unconnected bank2 generated keys");
   if(newboard.event_valid && newboard.event_ready)events++;
   if(newboard.u_synth_top.sample_tick)begin samples++;if(newboard.u_synth_top.audio_out!=0)nonzero++;end
  end
 end
 initial begin
  #1;rst=1;#1;rst=0;#1000;rst=1;
  // An asymmetric first key proves16 for the conservative pre-change reader.
  #200000;touch=16'h0001;#11000000;touch=16'h8001;
  #11000000;touch=16'h8000;#10000000;touch=0;#10000000;
  if(events!=4 || samples<1900 || nonzero<1000)$fatal(1,"preservation coverage");
  $display("PASS preserve16: %0d clocks, %0d PCM samples and both DAC pins bit-exact to backed-up old RTL; %0d Note events; unconnected bank2 silent",cycles,samples,events);$finish;
 end
 initial begin #60000000;$fatal(1,"preservation timeout");end
endmodule
