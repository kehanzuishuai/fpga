`timescale 1ns/1ps
module tb_stream_control;
 reg clk=0;always #1 clk=~clk;reg rst_n=0;reg [1:0] divider=0;
 always @(posedge clk)divider<=divider+1'b1;wire tick=divider==0;
 reg [31:0] keys=0;reg next_timbre=0,next_source=0,stall_clear=0;
 wire [31:0] playable;wire key_valid,key_on,key_ready,bridge_reset;
 wire [4:0] key_index;wire [6:0] ignored_note,mapped_note,event_note;wire [7:0] key_velocity,event_velocity;wire [1:0] key_waveform,event_waveform;
 wire event_valid,event_on,clear,switching,score_playing,fault,tl_clear;
 wire [2:0] instrument;wire [1:0] mode,performance;wire [15:0] kg,mg,volume;wire [4:0] effects;
 wire [223:0] keymap;wire [31:0] targets;wire [2:0] guide_state;wire [15:0] completed;
 reg [9:0] clear_age=400;wire clear_done=!stall_clear && !clear && clear_age>=300;
 always @(posedge clk)if(clear)clear_age<=0;else if(clear_age<400)clear_age<=clear_age+1'b1;
 reg pkt=0;reg [7:0] seq=0,cmd=0,len=0;reg [47:0] payload=0;reg [31:0] reply;
 integer on_count=0,off_count=0,clear_count=0,tl_count=0,i,j,prior,accepted,record_count,tone;
 reg [31:0] rec_word;reg [15:0] saved_mg;
 function automatic [223:0] initial_map();integer n;begin for(n=0;n<32;n=n+1)initial_map[n*7+:7]=7'(60+n);end endfunction
 ttp229_event_bridge #(.KEY_COUNT(32)) bridge(.clk(clk),.rst_n(bridge_reset),.frame_valid(1'b1),
  .key_state(playable),.velocity_in(8'd100),.event_ready(key_ready),.event_valid(key_valid),
  .event_note_on(key_on),.event_note(ignored_note),.event_velocity(key_velocity),
  .event_waveform(key_waveform),.event_key_index(key_index),.reported_state());
 live_remote_control #(.DEFAULT_KEYS(initial_map()),.CLEAR_TIMEOUT(512)) dut(
  .clk(clk),.rst_n(rst_n),.sample_tick(tick),.uart_rx(1'b1),.uart_tx(),.timbre_next(next_timbre),.source_next(next_source),
  .keys(keys),.keys_valid(1'b1),.key_valid(key_valid),.key_on(key_on),.key_index(key_index),.key_velocity(key_velocity),.key_waveform(key_waveform),
  .playable_keys(playable),.key_ready(key_ready),.bridge_reset_n(bridge_reset),.event_valid(event_valid),.event_on(event_on),
  .event_note(event_note),.event_velocity(event_velocity),.event_waveform(event_waveform),.event_ready(1'b1),.engine_idle(1'b1),
  .engine_clear_done(clear_done),.fifo_level(5'd0),.instrument(instrument),.switching(switching),.engine_clear(clear),
  .volume(volume),.effects(effects),.score_playing(score_playing),.mapped_key_note(mapped_note),.key_map(keymap),
  .synth_gain(kg),.mode_gain(mg),.source_mode(mode),.theremin_clear(tl_clear),.switch_fault(fault),
  .display_score_sounding(),.display_score_rest(),.display_score_note(),.display_score_completed(),
  .performance_mode(performance),.guide_targets(targets),.guide_state(guide_state),.guide_completed(completed));
 always @(posedge clk)begin
  if(event_valid && event_on)on_count=on_count+1;
  if(event_valid && !event_on)off_count=off_count+1;
  if(clear)clear_count=clear_count+1;
  if(tl_clear)tl_count=tl_count+1;
  if(dut.switch_state==3 && !clear_done && !fault && (bridge_reset || kg!=0 && !dut.switch_all || mg!=0 && dut.switch_all))$fatal(1,"clear wait was bypassed");
 end
 task automatic packet(input [7:0] command,bytes,input [47:0] data);
 begin
  @(negedge clk);while(!dut.core.pkt_ready)@(negedge clk);seq=seq+1'b1;cmd=command;len=bytes;payload=data;pkt=1;
  @(negedge clk);pkt=0;while(!dut.core.rsp_valid)@(negedge clk);
  if(dut.core.rsp_payload[15:8]!==0)$fatal(1,"command rejected cmd=%h rsp=%h",command,dut.core.rsp_payload);
  reply=dut.core.rsp_payload[47:16];@(negedge clk);
 end endtask
 task automatic settled;
 begin repeat(3)@(negedge clk);wait(!switching);repeat(3)@(negedge clk);if(fault)$fatal(1,"unexpected clear fault");end endtask
 task automatic pulse_timbre;begin @(negedge clk);next_timbre=1;@(negedge clk);next_timbre=0;end endtask
 task automatic pulse_source;begin @(negedge clk);next_source=1;@(negedge clk);next_source=0;end endtask
 initial begin
  force dut.core.pkt_valid=pkt;force dut.core.seq=seq;force dut.core.cmd=cmd;force dut.core.len=len;
  force dut.core.payload=payload;force dut.core.rsp_ready=1'b1;
  repeat(4)@(negedge clk);rst_n=1;repeat(5)@(negedge clk);
  packet(8'h40,0,0);packet(8'h42,0,0);if(reply[16]!=1 || reply[15:0]!=0)$fatal(1,"stream begin status");
  packet(8'h41,6,{32'd0,8'd100,8'd60});packet(8'h41,6,{32'd0,8'd90,8'd64});packet(8'h41,6,{32'd0,8'd80,8'd67});
  // Retry an accepted append with exactly the same sequence/request.
  @(negedge clk);pkt=1;@(negedge clk);pkt=0;while(!dut.core.rsp_valid)@(negedge clk);@(negedge clk);
  packet(8'h42,0,0);if(reply[15:0]!=3)$fatal(1,"retry duplicated event");
  packet(8'h41,6,{32'd100,8'd0,8'd64});packet(8'h41,6,{32'd200,8'd0,8'd60});packet(8'h41,6,{32'd300,8'd0,8'd67});packet(8'h43,0,0);
  packet(8'h15,1,1);wait(on_count==3);if(!score_playing || !dut.stream_owned)$fatal(1,"stream not routed to event output");
  wait(off_count==1);if(!score_playing)$fatal(1,"first off ended entire chord");wait(off_count==3);wait(!score_playing && !switching);
  packet(8'h42,0,0);if(reply[19] || !reply[20])$fatal(1,"stream completion status");
  // Uploading legacy guidance deselects the streaming timeline.
  packet(8'h30,1,1);packet(8'h31,5,48'h000001643c00);packet(8'h32,0,0);repeat(5)@(negedge clk);
  if(dut.stream_loaded)$fatal(1,"legacy score did not deselect stream");
  packet(8'h16,1,2);prior=on_count;packet(8'h15,1,1);wait(guide_state==2);
  if(on_count!=prior)$fatal(1,"guidance emitted automatic on");
  keys=1;repeat(8)@(negedge clk);if(completed!=1 || on_count!=prior+1)$fatal(1,"guidance broken after streaming");
  keys=0;repeat(8)@(negedge clk);
  $display("PASS stream protocol begin/status/append/seal, exactly-once retry, live chord arbitration, complete cleanup, legacy guidance after streaming");$finish;
 end
 initial begin #10000000;$fatal(1,"control timeout");end
endmodule
