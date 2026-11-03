`timescale 1ns/1ps
module tb_canon_stream;
 reg clk=0;always #1 clk=~clk;reg rst=0,begin_s=0,push=0,seal=0,start=0;
 reg [47:0] data;wire push_ready,loaded,playing,fault,valid,on;
 wire [31:0] status;wire [6:0] note,velocity;
 reg [47:0] expected[0:4285];
 integer got=0,cycles=0,i,ons=0,offs=0,delay_max=0,delay_now;
 reg [127:0] sounding=0;
 wire ready=cycles%13>2;
 wifi_stream_player dut(.clk(clk),.rst_n(rst),.sample_tick(1'b1),.tempo(16'd87),
 .begin_session(begin_s),.unload(1'b0),.push(push),.push_data(data),.seal(seal),.start(start),.stop(1'b0),.abort_play(1'b0),
 .push_ready(push_ready),.loaded(loaded),.playing(playing),.fault(fault),.status(status),
 .event_valid(valid),.event_ready(ready),.event_on(on),.event_note(note),.event_velocity(velocity));
 always @(posedge clk)begin
  cycles=cycles+1;
  if(valid&&ready)begin
   if(got>=4286)$fatal(1,"extra event");
   if(note!==expected[got][6:0] || velocity!==expected[got][14:8] || on!==(expected[got][15:8]!=0))$fatal(1,"timeline mismatch %d",got);
   delay_now=dut.elapsed-expected[got][47:16];if(delay_now<0||delay_now>2)$fatal(1,"event deadline %d",delay_now);
   if(delay_now>delay_max)delay_max=delay_now;
   if(on)begin if(sounding[note])$fatal(1,"duplicate On");sounding[note]=1;ons=ons+1;end
   else begin if(!sounding[note])$fatal(1,"unmatched Off");sounding[note]=0;offs=offs+1;end
   got=got+1;
  end
  if(fault)$fatal(1,"stream fault %h at event %d",status,got);
 end
 task put(input integer n);begin
  while(!push_ready)@(negedge clk);data=expected[n];push=1;@(negedge clk);push=0;@(negedge clk);
 end endtask
 initial begin
  $readmemh("tests/current/canon_events.hex",expected);repeat(5)@(negedge clk);rst=1;
  @(negedge clk);begin_s=1;@(negedge clk);begin_s=0;repeat(3)@(negedge clk);
  for(i=0;i<240;i=i+1)put(i);
  start=1;@(negedge clk);start=0;wait(playing);
  // Approximate 3ms stop-and-wait UART feed at this accelerated sample clock.
  for(i=240;i<4286;i=i+1)begin
   repeat(144)@(negedge clk);while(status[15:0]>240)@(negedge clk);put(i);
  end
  seal=1;@(negedge clk);seal=0;
  wait(!playing);if(got!=4286||sounding||ons!=offs)$fatal(1,"incomplete Canon %d %d %d",got,ons,offs);
  $display("PASS FULL CANON: 4286 exact scheduled events, %0d On/%0d Off, FIFO refill/wrap/backpressure, no underrun/hung notes; max scheduling lateness=%0d base-ms",ons,offs,delay_max);$finish;
 end
 initial begin #60000000;$fatal(1,"Canon timeout got=%d",got);end
endmodule
