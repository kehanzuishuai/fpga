`timescale 1ns/1ps
module tb_live_control;
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
  // Every live timbre is the true applied engine, including query feedback.
  for(i=0;i<5;i=i+1)begin
   packet(8'h11,1,48'(i));settled();packet(8'h02,0,0);
   if(instrument!==i || reply[4:2]!==i || reply[5])$fatal(1,"actual timbre feedback");
   prior=on_count;keys=32'h80000001;repeat(8)@(negedge clk);
   if(on_count!=prior+2)$fatal(1,"both banks did not reach selected engine");
   keys=0;repeat(8)@(negedge clk);
  end
  // A held key must not retrigger after tone changes; recorder gets its Off.
  packet(8'h17,1,1);keys=1;repeat(8)@(negedge clk);prior=on_count;
  pulse_timbre();settled();if(on_count!=prior || playable!=0)$fatal(1,"held key retriggered");
  keys=0;repeat(8)@(negedge clk);keys=1;repeat(8)@(negedge clk);
  if(on_count!=prior+1)$fatal(1,"released key did not rearm");keys=0;repeat(8)@(negedge clk);
  record_count=0;
  for(i=0;i<5;i=i+1)begin packet(8'h07,0,0);if(reply[31])begin
   if(reply[29:23]!=60)$fatal(1,"recorded pitch");
   if(reply[30]!==((record_count%2)==0))$fatal(1,"recorded On/Off lost during clear");record_count=record_count+1;
  end end
  if(record_count!=4)$fatal(1,"record count=%0d",record_count);packet(8'h17,1,0);
  // A key pressed during a guidance timbre change cannot score until released
  // and pressed again through the selected live engine.
  packet(8'h30,1,1);packet(8'h31,5,48'h000001643c00);packet(8'h32,0,0);packet(8'h16,1,2);
  for(i=0;i<5;i=i+1)begin
   tone=(i+1)%5;packet(8'h15,1,1);wait(guide_state==2);
   packet(8'h11,1,48'(tone));repeat(5)@(negedge clk);keys=1;settled();
   if(completed!=0 || instrument!=tone)$fatal(1,"held stale key advanced guidance during a timbre switch");
   keys=0;repeat(6)@(negedge clk);prior=on_count;keys=1;repeat(6)@(negedge clk);
   if(completed!=1 || on_count!=prior+1)$fatal(1,"guidance/live timbre did not rearm");
   keys=0;repeat(10)@(negedge clk);wait(!dut.guide_running);
  end
  packet(8'h16,1,1);packet(8'h15,1,1);wait(dut.player_playing);pulse_source();settled();
  if(mode!=1 || performance!=0 || score_playing || dut.player_playing)$fatal(1,"source change failed to stop automatic playback");
  packet(8'h10,1,0);settled();
  // All six source transitions and live key suppression in theremin solo.
  for(i=0;i<3;i=i+1)for(j=0;j<3;j=j+1)if(i!=j)begin
   packet(8'h10,1,48'(i));settled();keys=0;repeat(4)@(negedge clk);
   keys=1;repeat(6)@(negedge clk);prior=on_count;
   packet(8'h10,1,48'(j));settled();if(mode!==j || on_count!=prior)$fatal(1,"source commit or held-key rearm");
   keys=0;repeat(6)@(negedge clk);keys=1;repeat(6)@(negedge clk);
   if(on_count!=prior+(j==1?0:1))$fatal(1,"source event routing");keys=0;repeat(6)@(negedge clk);
   packet(8'h02,0,0);if(reply[1:0]!==j || reply[5])$fatal(1,"phone source feedback");
  end
  // Timbre changes in duet leave global/theremin gain and phase clear alone.
  packet(8'h10,1,2);settled();prior=tl_count;pulse_timbre();
  repeat(3)@(negedge clk);while(switching)begin if(mg!=65535)$fatal(1,"timbre change muted theremin");@(negedge clk);end
  if(tl_count!=prior)$fatal(1,"timbre change reset theremin");
  // Rapid requests during a transition converge to the last accepted target.
  packet(8'h10,1,0);repeat(8)@(negedge clk);pulse_source();pulse_source();settled();
  if(mode!==2)$fatal(1,"queued source target lost");
  // Clear failure is explicit and remains muted until reset.
  stall_clear=1;pulse_timbre();wait(fault);if(mg!=0 || kg!=0 || bridge_reset)$fatal(1,"fault was not fail-silent");
  @(negedge clk);rst_n=0;repeat(3)@(negedge clk);stall_clear=0;rst_n=1;repeat(5)@(negedge clk);
  if(fault || mode!=0 || instrument!=0)$fatal(1,"reset recovery");
  $display("PASS live control: five live timbres and guidance switches, actual feedback, both banks, held-key rearm/recording, six source transitions, automatic cancellation, independent duet fade, latest target and clear timeout");$finish;
 end
 initial begin #2000000;$fatal(1,"control timeout");end
endmodule
