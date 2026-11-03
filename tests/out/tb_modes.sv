`timescale 1ns/1ps
// UART byte transport is bypassed; packet validation, commit, arbitration,
// score player, guidance controller and display adapter are production RTL.
module tb_modes;
 reg clk=0;always #1 clk=~clk;
 reg rst_n=0;reg [31:0] keys=0;reg key_valid=0,key_on=0;reg [4:0] key_index=0;
 reg pkt=0;reg [7:0] seq=0,cmd=0,len=0;reg [47:0] payload=0;
 wire key_ready,event_valid,event_on,bridge_reset,engine_clear,score_owned,switching;
 wire [6:0] event_note,mapped_note,score_note;wire [7:0] velocity;wire [1:0] waveform,mode;
 wire [2:0] instrument,guide_state;wire [31:0] targets;wire [15:0] completed,score_completed;
 wire [223:0] keymap;wire [15:0] volume,gain;wire [4:0] effects;wire sounding,rest;
 wire [511:0] status;
 function automatic [223:0] initial_map();integer n;begin
  for(n=0;n<32;n=n+1)initial_map[n*7+:7]=7'(60+n);
 end endfunction
 live_remote_control #(.DEFAULT_KEYS(initial_map())) dut(
  .timbre_next(1'b0),.source_next(1'b0),.engine_clear_done(1'b1),
  .clk(clk),.rst_n(rst_n),.sample_tick(1'b1),.uart_rx(1'b1),.uart_tx(),.keys(keys),.keys_valid(1'b1),
  .key_valid(key_valid),.key_on(key_on),.key_index(key_index),.key_velocity(8'd100),.key_waveform(2'd3),
  .key_ready(key_ready),.bridge_reset_n(bridge_reset),.event_valid(event_valid),.event_on(event_on),
  .event_note(event_note),.event_velocity(velocity),.event_waveform(waveform),.event_ready(1'b1),
  .engine_idle(1'b1),.fifo_level(5'd0),.instrument(instrument),.switching(switching),.engine_clear(engine_clear),
  .volume(volume),.effects(effects),.score_playing(score_owned),.mapped_key_note(mapped_note),.key_map(keymap),.synth_gain(gain),
  .display_score_sounding(sounding),.display_score_rest(rest),.display_score_note(score_note),.display_score_completed(score_completed),
  .performance_mode(mode),.guide_targets(targets),.guide_state(guide_state),.guide_completed(completed));
 display_status_adapter adapter(.clk(clk),.rst_n(rst_n),.pcm_valid(1'b1),.pcm_left(24'sd0),.pcm_right(24'sd0),
  .keys_valid(1'b1),.keys(keys),.key_map(keymap),.instrument(instrument),.voices(32'd0),.voice_notes(224'd0),
  .score_owned(score_owned),.switching(switching),.score_sounding(sounding),.score_rest(rest),.score_note(score_note),
  .score_completed(score_completed),.performance_mode(mode),.guide_targets(targets),.guide_state(guide_state),
  .guide_completed(completed),.status_ready(1'b1),.status_update(),.status_data(status));
 integer pass,i,checks=0;reg [6:0] note;
 function automatic [6:0] note_for(input integer k);begin note_for=7'(pass==0?60+k:91-k);end endfunction
 task automatic packet(input [7:0] command,bytes,input [47:0] data);
 begin
  @(negedge clk);while(!dut.core.pkt_ready)@(negedge clk);
  seq=seq+1'b1;cmd=command;len=bytes;payload=data;pkt=1;
  @(negedge clk);pkt=0;
  while(!dut.core.rsp_valid)@(negedge clk);
  if(dut.core.rsp_payload[15:8]!==0)$fatal(1,"command %h rejected %h",command,dut.core.rsp_payload);
  @(negedge clk);
 end endtask
 initial begin
  force dut.core.pkt_valid=pkt;force dut.core.seq=seq;force dut.core.cmd=cmd;
  force dut.core.len=len;force dut.core.payload=payload;force dut.core.rsp_ready=1'b1;
  repeat(4)@(negedge clk);rst_n=1;
  for(pass=0;pass<2;pass=pass+1)begin
   if(pass==1)begin
    packet(8'h20,0,0);
    for(i=0;i<32;i=i+1)packet(8'h21,2,(48'(note_for(i))<<8)|48'(i));
   end
   if(pass==1)packet(8'h22,0,0);
   packet(8'h16,1,0);
   for(i=0;i<32;i=i+1)begin
    @(negedge clk);key_index=5'(i);keys=32'd1<<i;key_valid=1;key_on=1;
    #0.1;
    if(!key_ready || !event_valid || event_note!==note_for(i) || instrument!==(pass==0?3'd0:3'd3))
     $fatal(1,"physical note routing pass=%0d index=%0d note=%0d expected=%0d",pass,i,event_note,note_for(i));
    if(status[18+:32]!==keys)$fatal(1,"free mode display mask");
    @(negedge clk);key_on=0;#0.1;
    if(event_on || event_note!==note_for(i))$fatal(1,"physical release note mismatch");
    @(negedge clk);key_valid=0;keys=0;checks=checks+1;
   end
   packet(8'h30,1,32);
   for(i=0;i<32;i=i+1)begin
    payload=0;payload[7:0]=8'(i);payload[15:8]={1'b0,note_for(i)};payload[23:16]=100;payload[39:24]=1;
    packet(8'h31,5,payload);
   end
   packet(8'h32,0,0);
   packet(8'h16,1,2);packet(8'h15,1,1);
   for(i=0;i<32;i=i+1)begin
    wait(guide_state==2);@(negedge clk);
    if(targets!==(32'd1<<i) || status[458+:32]!==targets)$fatal(1,"guide target pass=%0d key=%0d targets=%h",pass,i,targets);
    keys=32'd1<<((i+1)%32);repeat(3)@(negedge clk);
    if(completed!==i || guide_state!==2)$fatal(1,"wrong physical key advanced guide");
    keys=0;repeat(2)@(negedge clk);keys=32'd1<<i;repeat(3)@(negedge clk);
    if(completed!==i+1 || guide_state!==3)$fatal(1,"correct physical key did not advance exactly once");
    keys=0;repeat(3)@(negedge clk);checks=checks+1;
   end
   wait(!dut.guide_running);packet(8'h16,1,1);packet(8'h11,1,3);packet(8'h15,1,1);
   for(i=0;i<32;i=i+1)begin
    wait(sounding && score_note==note_for(i));@(negedge clk);
    if(status[458+:32]!==(32'd1<<i) || instrument!==3 || mode!==1)
     $fatal(1,"automatic target pass=%0d key=%0d mask=%h",pass,i,status[458+:32]);
    wait(!sounding);checks=checks+1;
   end
   wait(!score_owned && !switching);packet(8'h16,1,0);
   if(instrument!==3)$fatal(1,"selected live timbre was not retained");
  end
  $display("PASS modes: %0d physical note/release, guide hit/wrong/release and automatic target checks; both banks, default/custom maps",checks);$finish;
 end
 initial begin #2000000;$fatal(1,"modes timeout pass=%0d i=%0d mode=%0d state=%0d",pass,i,mode,guide_state);end
endmodule
