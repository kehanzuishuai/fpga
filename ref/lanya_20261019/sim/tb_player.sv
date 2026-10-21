`timescale 1ns/1ps
module tb_player;
 reg clk=0;always #5 clk=~clk;reg rst_n=0,start=0,stop=0,abort_play=0,ready=1;
 reg [15:0] tempo=120;wire [4:0] index;reg [31:0] data;wire playing,safe,valid,on;wire [6:0] note,velocity;
 reg [5:0] count=3;integer clocks=0,on_time=0,off_time=0,ons=0,offs=0;
 wifi_score_player #(.SAMPLE_RATE(2400)) dut(clk,rst_n,1'b1,start,stop,abort_play,tempo,count,index,data,playing,safe,valid,ready,on,note,velocity);
 always @(*)case(index)
  0:data={16'd100,8'd100,8'd60};
  1:data={16'd50,8'd0,8'd0};
  default:data={16'd100,8'd90,8'd64};
 endcase
 always @(posedge clk)begin
  clocks=clocks+1;
  if(valid&&ready)begin
   if(on)begin ons=ons+1;on_time=clocks;end
   else begin offs=offs+1;off_time=clocks;end
  end
 end
 task reset;begin @(negedge clk);rst_n=0;start=0;stop=0;abort_play=0;ready=1;repeat(3)@(negedge clk);rst_n=1;ons=0;offs=0;end endtask
 task play;begin @(negedge clk);start=1;@(negedge clk);start=0;end endtask
 initial begin
  reset();play();wait(offs==1);@(negedge clk);
  if(off_time-on_time<240||off_time-on_time>242)$fatal(1,"120 BPM timing %d",off_time-on_time);
  wait(!playing);if(ons!=2||offs!=2||!safe)$fatal(1,"notes/rest/end");
  reset();tempo=240;play();wait(offs==1);@(negedge clk);
  if(off_time-on_time<120||off_time-on_time>122)$fatal(1,"240 BPM timing");
  // Hold NoteOff under backpressure, even when stop remains asserted.
  reset();play();wait(ons==1);repeat(10)@(negedge clk);ready=0;stop=1;repeat(5)@(negedge clk);if(!valid||on||!playing||safe)$fatal(1,"lost NoteOff");
  ready=1;repeat(3)@(negedge clk);if(playing)$fatal(1,"stop held never completed");stop=0;
  reset();tempo=120;count=1;play();wait(ons==1);repeat(60)@(negedge clk);tempo=240;
  wait(!playing);if(ons!=1||offs!=1||off_time-on_time<150||off_time-on_time>152)$fatal(1,"live tempo change or pitch/event retrigger");
  reset();ready=0;play();repeat(10)@(negedge clk);stop=1;repeat(3)@(negedge clk);
  if(playing||ons||offs)$fatal(1,"unaccepted NoteOn generated a hanging note");
  $display("PASS player BPM ratio, live speed without pitch/retrigger, rest, sequence end, stop/backpressure and cancel");$finish;
 end
 initial begin #100000;$fatal(1,"player watchdog");end
endmodule
