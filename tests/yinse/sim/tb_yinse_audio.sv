`timescale 1ns/1ps
module tb_yinse_audio;
 parameter integer VOICES=1;
 parameter integer FRAME_CYCLES=16;
 parameter integer TOTAL_FRAMES=24576;
 reg clk=0,rst_n=0,tick=0,clear=0,event_valid=0,event_on=1;
 reg [2:0] instrument=1;reg [6:0] event_note=69;reg [7:0] velocity=100;
 always #5 clk=~clk;
 wire ready,valid,rejected;wire signed [23:0] pcm;
 wire [VOICES-1:0] active,overruns,clips;
 yinse_aux_bank #(.VOICES(VOICES)) dut(clk,rst_n,tick,clear,event_valid,event_on,
 instrument,event_note,velocity,ready,pcm,valid,active,overruns,clips,rejected);
 integer cycles=0,frame=0,file_handle,inst_arg=1,note_arg=69;
 reg [2047:0] file_path;
 always @(negedge clk)begin cycles=cycles+1;tick=(cycles%FRAME_CYCLES)==0;end
 task automatic clocks(input integer n);repeat(n)@(negedge clk);endtask
 task automatic event_send(input bit is_on,input integer n,input integer vel);
  integer count;begin
   @(negedge clk);event_on=is_on;event_note=7'(n);velocity=8'(vel);event_valid=1;count=0;
   while(!ready && count<5000)begin @(negedge clk);count=count+1;end
   if(count==5000)$fatal(1,"event stuck");
   @(negedge clk);event_valid=0;
  end
 endtask
 integer i,released,sample_i;
 reg [VOICES-1:0] nonzero_mask=0;
 initial begin
  if(!$value$plusargs("instrument=%d",inst_arg))inst_arg=1;
  if(!$value$plusargs("note=%d",note_arg))note_arg=69;
  if(!$value$plusargs("output=%s",file_path))file_path="sim/out/audio.txt";
  file_handle=$fopen(file_path,"w");if(file_handle==0)$fatal(1,"cannot create sample file");
  #1;rst_n=1;#1;rst_n=0;clocks(4);rst_n=1;instrument=3'(inst_arg);
  for(i=0;i<VOICES;i=i+1)event_send(1,(VOICES==1)?note_arg:60+i,100);
  clocks(2000);if(active!={VOICES{1'b1}})$fatal(1,"not independently polyphonic");
  while(frame<TOTAL_FRAMES)begin
   @(posedge clk);#1;
   if(valid)begin
    if(^pcm===1'bx || |overruns || |clips)$fatal(1,"unknown/overrun/clip");
    for(sample_i=0;sample_i<VOICES;sample_i=sample_i+1)begin
     if(^dut.samples[sample_i*24 +: 24]===1'bx)$fatal(1,"unknown individual voice");
     if(dut.samples[sample_i*24 +: 24]!=0)nonzero_mask[sample_i]=1;
    end
    $fdisplay(file_handle,"%0d",pcm);frame=frame+1;
   end
  end
  if(nonzero_mask!={VOICES{1'b1}})$fatal(1,"active voice never produced audio");
  $fclose(file_handle);
  if(VOICES>1)begin
   // Full bank stealing and same-note retrigger must remain playable.
   event_send(1,84,80);clocks(1000);if(active!={VOICES{1'b1}})$fatal(1,"steal lost voices");
   event_send(1,84,80);clocks(1000);if(active!={VOICES{1'b1}})$fatal(1,"duplicate allocation");
  end
  for(i=0;i<VOICES;i=i+1)event_send(0,(VOICES==1)?note_arg:60+i,0);
  if(VOICES>1)event_send(1,84,0); // velocity-zero NOTE ON is NOTE OFF
  released=0;
  while(|active && released<43000*FRAME_CYCLES)begin clocks(1);released=released+1;end
  if(|active)$fatal(1,"stuck release");clocks(2*FRAME_CYCLES);if(pcm!=0)$fatal(1,"nonzero after release");
  event_send(1,12,100);if(!rejected || |active)$fatal(1,"out-of-range note accepted");
  instrument=0;event_send(1,69,100);if(|active)$fatal(1,"aux engine swallowed piano");
  instrument=3;event_send(1,60,100);clocks(6);clear=1;clocks(2);clear=0;clocks(512);
  if(|active || pcm!=0 || |overruns)$fatal(1,"clear during KS fill");
  rst_n=0;clocks(2);rst_n=1;clocks(512);if(pcm!=0 || rejected)$fatal(1,"reset");
  $display("PASS audio instrument=%0d voices=%0d note=%0d samples=%0d polyphony/release/range/reset",inst_arg,VOICES,note_arg,frame);$finish;
 end
 initial begin #300000000;$fatal(1,"audio watchdog");end
endmodule
