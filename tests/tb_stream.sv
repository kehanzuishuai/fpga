`timescale 1ns/1ps
module tb_stream;
 reg clk=0;always #1 clk=~clk;
 reg rst=0,begin_s=0,push=0,seal=0,start=0,stop=0,abort_p=0,ready=1;
 reg [47:0] data;wire push_ready,loaded,playing,fault,valid,on;
 wire [31:0] status;wire [6:0] note,velocity;
 integer ons=0,offs=0,cyc=0,first_c=-1,last_c=0;
 reg [127:0] sounding=0;
 wifi_stream_player dut(.clk(clk),.rst_n(rst),.sample_tick(1'b1),.tempo(16'd120),
 .begin_session(begin_s),.unload(1'b0),.push(push),.push_data(data),.seal(seal),.start(start),.stop(stop),.abort_play(abort_p),
 .push_ready(push_ready),.loaded(loaded),.playing(playing),.fault(fault),.status(status),
 .event_valid(valid),.event_ready(ready),.event_on(on),.event_note(note),.event_velocity(velocity));
 always @(posedge clk)begin
  cyc=cyc+1;
  if(valid&&ready)begin
   if(on)begin
    if(sounding[note])$fatal(1,"duplicate on");sounding[note]=1;ons=ons+1;
    if(first_c<0)first_c=cyc;last_c=cyc;
   end else begin if(!sounding[note])$fatal(1,"off without on");sounding[note]=0;offs=offs+1;end
  end
 end
 task fresh;begin @(negedge clk);begin_s=1;@(negedge clk);begin_s=0;repeat(3)@(negedge clk);end endtask
 task put(input [31:0] t,input [7:0] n,v);begin
  @(negedge clk);if(!push_ready)$fatal(1,"push backpressure unexpected");data={t,v,n};push=1;
  @(negedge clk);push=0;
 end endtask
 task go;begin @(negedge clk);start=1;@(negedge clk);start=0;wait(playing);end endtask
 task finish;begin @(negedge clk);seal=1;@(negedge clk);seal=0;end endtask
 integer i,k,prev_on,prev_off;
 initial begin
  repeat(4)@(negedge clk);rst=1;
  fresh();put(0,60,100);put(0,64,90);put(0,67,80);put(10,64,0);put(20,60,0);put(30,67,0);finish();go();
  wait(ons==3);if(last_c-first_c>8)$fatal(1,"chord serialized by durations");
  wait(offs==1);if(sounding!==((128'd1<<60)|(128'd1<<67)))$fatal(1,"independent note-off killed chord");
  wait(!playing);if(fault||ons!=3||offs!=3||sounding)$fatal(1,"chord finish");
  // More than 256 events, crossing queue pointers several times, with live refills.
  fresh();prev_on=ons;prev_off=offs;
  for(i=0;i<120;i=i+1)begin put(i*4,60,100);put(i*4+2,60,0);end
  go();
  for(i=120;i<500;i=i+1)begin
   while(status[15:0]>240)@(negedge clk);
   put(i*4,60,100);put(i*4+2,60,0);
  end
  finish();wait(!playing);if(fault||ons-prev_on!=500||offs-prev_off!=500)$fatal(1,"streaming wrap lost events %d %d",ons-prev_on,offs-prev_off);
  // Stop under backpressure must retain all note-offs until accepted.
  fresh();put(0,60,100);put(0,64,100);put(1000,60,0);put(1000,64,0);finish();prev_on=ons;go();wait(ons==prev_on+2);
  @(negedge clk);ready=0;stop=1;@(negedge clk);stop=0;repeat(100)@(negedge clk);
  if(!valid||!playing||on)$fatal(1,"stop lost blocked off");ready=1;wait(!playing);if(sounding)$fatal(1,"stop hung notes");
  // Unsealed starvation reports a fault and cleans up held notes.
  fresh();put(0,60,100);go();wait(!playing);if(!fault||status[31:24]!=1||sounding)$fatal(1,"underrun not fail-safe");
  // Aborting a source/timbre transition is paired with engine clear.
  fresh();put(0,60,100);put(1000,60,0);finish();prev_on=ons;go();wait(ons==prev_on+1);
  @(negedge clk);abort_p=1;sounding=0;@(negedge clk);abort_p=0;repeat(4)@(negedge clk);if(playing)$fatal(1,"abort hung");
  $display("PASS chord same timestamp, independent offs, 1000 streamed events with wrap/refills, blocked stop cleanup, underrun fault and mode abort");$finish;
 end
 initial begin #2000000;$fatal(1,"timeout");end
endmodule
