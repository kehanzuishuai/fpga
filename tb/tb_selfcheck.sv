`timescale 1ns/1ps
module tb_selfcheck;
  logic clk=0,rst_n=0,tick=0,phase_reset=0,gate_on=0,gate_off=0,event_stb=0;
  logic [31:0] phase; logic [23:0] env; logic active; logic [1:0] stage;
  logic [1:0] wave=0; logic [9:0] morph=0; logic signed [23:0] wave_out,morph_out;
  logic signed [23:0] sine=24'sd100, square=-24'sd100, saw=24'sd300, tri_v=-24'sd300;
  logic uart_ready,uart_tx; logic [7:0] uart_data=8'h55; logic uart_valid=0;
  logic [11:0] leds; logic hit; logic lv,de,da; logic [23:0] latency;
  logic signed [4*24-1:0] latency_voice_samples='0;logic [1:0] latency_voice_index=1;
  always #5 clk=~clk;
  dds_phase_accum dds(.clk,.rst_n,.sample_tick(tick),.phase_reset,.phase_inc(32'd3),.phase);
  waveform_gen wavegen(.phase,.waveform(wave),.sample(wave_out));
  adsr_env #(.ATTACK_STEP(24'd8388607),.DECAY_STEP(24'd1),.SUSTAIN(24'd8388606),.RELEASE_STEP(24'd8388607)) envgen(.clk,.rst_n,.sample_tick(tick),.gate_on,.gate_off,.level(env),.active,.stage);
  timbre_morph u_morph(.sine,.square,.saw,.triangle(tri_v),.morph,.sample(morph_out));
  uart_tx #(.CLK_HZ(1000),.BAUD(100)) uart(.clk,.rst_n,.valid(uart_valid),.data(uart_data),.ready(uart_ready),.tx(uart_tx));
  led_guide guide(.enable(1'b0),.target_valid(1'b1),.target_note(7'd60),.note_played(1'b0),.played_note(7'd0),.leds,.hit);
  latency_monitor #(.VOICES(4)) mon(.clk,.rst_n,.sample_tick(tick),.event_strobe(event_stb),.event_voice_index(latency_voice_index),.voice_samples(latency_voice_samples),.dbg_event(de),.dbg_audio(da),.latency_valid(lv),.latency_samples(latency));
  task do_tick; begin @(negedge clk); tick=1; @(negedge clk); tick=0; end endtask
  initial begin
    repeat(2) @(posedge clk); rst_n=1;
    do_tick; do_tick; do_tick; if(phase!=9) $fatal(1,"DDS increment failed");
    @(negedge clk); phase_reset=1; @(negedge clk); phase_reset=0; if(phase!=0) $fatal(1,"DDS reset failed");
    if(wave_out!==0) $fatal(1,"sine zero crossing failed"); wave=1; #1; if(wave_out<=0) $fatal(1,"square polarity failed");
    morph=0; #1; if(morph_out!=sine) $fatal(1,"morph sine endpoint failed");
    morph=341; #1; if(morph_out!=square) $fatal(1,"morph square boundary failed");
    morph=682; #1; if(morph_out!=saw) $fatal(1,"morph saw boundary failed");
    morph=1023; #1; if(morph_out!=tri_v) $fatal(1,"morph triangle endpoint failed");
    @(negedge clk); gate_on=1; @(negedge clk); gate_on=0; do_tick; if(!active || env==0) $fatal(1,"ADSR attack failed");
    @(negedge clk); gate_off=1; @(negedge clk); gate_off=0; do_tick; do_tick; if(active) $fatal(1,"ADSR release failed");
    latency_voice_samples[23:0]=24'sd2048; // unrelated Voice already sounding
    @(negedge clk); event_stb=1; @(negedge clk); event_stb=0;
    do_tick;if(lv||latency!=1)$fatal(1,"latency falsely triggered from existing Voice");
    latency_voice_samples[47:24]=24'sd2048;do_tick;
    if(!lv||!da||latency!=1)$fatal(1,"target-Voice latency/debug pulses failed");
    if(leds!==0 || hit!==0) $fatal(1,"LED/reset check failed");
    @(negedge clk); uart_valid=1; @(negedge clk); uart_valid=0; repeat(120) @(posedge clk); if(!uart_ready || uart_tx!==1) $fatal(1,"UART frame/reset timing failed");
    $display("TB_SELFCHECK PASS: reset DDS waveform ADSR morph UART LED latency"); $finish;
  end
endmodule
