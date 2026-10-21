`timescale 1ns/1ps
module tb_yinse_controls;
 reg clk=0,rst_n=0,tick=0,bnext=1,bprev=1,loader=0;reg [15:0] keys=0;
 always #5 clk=~clk;
 integer counter=0,commits=0,flushes=0;
 always @(negedge clk)begin counter=counter+1;tick=(counter%16)==0;end
 wire [2:0] current,requested;wire [15:0] gain;wire blocked,flush,clear,commit,busy;
 yinse_controls #(.DEBOUNCE_CYCLES(4),.FADE_SAMPLES(4)) dut(
 clk,rst_n,tick,bnext,bprev,loader,keys,current,requested,gain,blocked,flush,clear,commit,busy);
 wire [127:0] name_ascii;wire [2:0] display_id;wire display_busy;
 yinse_display_info display(current,busy,name_ascii,display_id,display_busy);
 reg signed [23:0] piano=0,aux=12345;wire signed [23:0] audio;
 yinse_audio_mux mux(current,gain,piano,aux,audio);
 always @(posedge clk)begin
  #1;
  if(commit)begin commits=commits+1;if(gain!=0 || loader || keys!=0 || !clear || !flush)$fatal(1,"unsafe commit");end
  if(flush)flushes=flushes+1;
  if(gain==0 && audio!==0)$fatal(1,"nonzero muted output");
  if(display_id!==current || display_busy!==busy)$fatal(1,"display reports pending instead of current");
 end
 task automatic clocks(input integer n);repeat(n)@(negedge clk);endtask
 task automatic press(input bit forward);
  if(forward)bnext=0;else bprev=0;
  clocks(12);if(forward)bnext=1;else bprev=1;clocks(12);
 endtask
 task automatic settled(input integer id);
  integer n;begin n=0;
   while((busy || blocked || current!=id || gain!=65535) && n<1000)begin clocks(1);n=n+1;end
   if(n==1000)$fatal(1,"switch timeout expected %0d current %0d request %0d",id,current,requested);
  end
 endtask
 integer i,before_commits;
 initial begin
  #1;rst_n=1;#1;rst_n=0;clocks(5);rst_n=1;clocks(8);
  for(i=0;i<1000;i=i+1)begin piano=24'(i*123457)^24'h800001;#1;if(audio!==piano)$fatal(1,"piano transparency");end
  // Electrical bounce cannot select a preset.
  repeat(3)begin bnext=0;clocks(1);bnext=1;clocks(1);end clocks(12);
  if(requested!=0)$fatal(1,"bounce accepted");
  bnext=0;bprev=0;clocks(20);bnext=1;bprev=1;clocks(20);
  if(requested!=0)$fatal(1,"simultaneous buttons changed selection");
  keys=16'h0001;loader=1;press(1);clocks(120);
  if(current!=0 || requested!=1 || gain!=0 || !blocked)$fatal(1,"key/loader barrier");
  // Extra clicks while waiting coalesce to the latest target.
  press(1);if(requested!=2)$fatal(1,"pending target not retained");
  keys=0;clocks(48);if(current!=0)$fatal(1,"loader barrier bypassed");
  loader=0;settled(2);if(name_ascii!="FLUTE           ")$fatal(1,"flute label");
  before_commits=commits;
  bnext=0;clocks(400);bnext=1;clocks(12);settled(3);
  if(commits!=before_commits+1)$fatal(1,"held button repeats");
  press(1);settled(4);press(1);settled(0);press(0);settled(4);
  // Reset during a blocked transition restores piano and full gain.
  keys=1;press(0);clocks(40);rst_n=0;clocks(3);keys=0;rst_n=1;settled(0);
  if(name_ascii!="PIANO           " || flushes<commits)$fatal(1,"reset/status");
  $display("PASS controls: bounce, hold, simultaneous buttons, forward/back wrap, latest request, loader/key barrier, unity piano and reset");$finish;
 end
 initial begin #2000000;$fatal(1,"controls watchdog");end
endmodule
