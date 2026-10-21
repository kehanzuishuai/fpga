`timescale 1ns/1ps
module tb_events32;
 reg clk=0,rst=0,fv=0;always #5 clk=~clk;
 reg [31:0] keys=0;wire ev,on,ready;wire [6:0] note;wire [7:0] vel;
 wire [1:0] wave;wire [4:0] key;wire [31:0] reported;
 ttp229_event_bridge #(.KEY_COUNT(32),.BASE_NOTE(60)) bridge(
 clk,rst,fv,keys,8'd100,ready,ev,on,note,vel,wave,key,reported);
 reg sink=1;wire ov,oo;wire[6:0] no;wire[7:0] vo;wire[1:0]wo;wire[4:0]level;
 note_event_fifo fifo(clk,rst,ev,ready,on,note,vel,wave,ov,sink,oo,no,vo,wo,level);
 reg [31:0] held=0;reg [7:0] queue[0:16383];
 integer accepted=0,consumed=0,stalls=0,checks=0,i,k,offs=0;
 reg was_stalled=0;reg[22:0]payload;
 always @(posedge clk)if(!rst)begin held=0;accepted=0;consumed=0;was_stalled=0;end
 else begin
  if(was_stalled && (!ev || payload!=={on,note,vel,wave,key}))$fatal(1,"unstable stalled payload");
  was_stalled=ev&&!ready;payload={on,note,vel,wave,key};
  if(was_stalled)stalls++;
  if(ev&&ready)begin
   if(note!==60+key || vel!==100)$fatal(1,"32-key boundary/MIDI mismatch");
   queue[accepted]={on,note};accepted++;
  end
  if(ov&&sink)begin
   if(queue[consumed]!=={oo,no})$fatal(1,"FIFO order/loss");consumed++;
   if(no<60 || no>91)$fatal(1,"note outside 32-key range");
   if(held[no-60]===oo)$fatal(1,"duplicate on/unmatched off");
   held[no-60]=oo;
  end
  if(level>16)$fatal(1,"FIFO overflow");
 end
 task snap(input[31:0]v);begin @(negedge clk);keys=v;fv=1;@(negedge clk);fv=0;end endtask
 task settle(input[31:0]v);begin
  sink=1;repeat(200)@(negedge clk);checks++;
  if(held!==v || reported!==v || level || ev || accepted!=consumed)$fatal(1,"32-key convergence want%h got%h",v,held);
 end endtask
 reg[31:0]rng=32'h5362e91a;
 initial begin
  #1;rst=1;#1;rst=0;repeat(4)@(negedge clk);rst=1;
  // First post-reset chord includes all upper bits; never aliases 0/16 or 15/31.
  snap(32'hffffffff);settle(32'hffffffff);snap(0);settle(0);
  for(k=0;k<32;k++)begin snap(32'b1<<k);settle(32'b1<<k);snap(0);settle(0);end
  snap(32'h80018001);settle(32'h80018001);snap(32'h40024002);settle(32'h40024002);
  snap(0);settle(0);
  // 32 keys exceed the 16-event FIFO: a queued off must survive a full FIFO.
  sink=0;snap(32'hffffffff);repeat(100)@(negedge clk);
  if(level!=16 || !ev || ready)$fatal(1,"FIFO did not backpressure 32-key burst");
  snap(0);repeat(80)@(negedge clk);settle(0);
  for(i=0;i<128;i++)begin
   rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};sink=0;snap(rng);
   repeat(13)@(negedge clk);snap(~rng);repeat(21)@(negedge clk);settle(~rng);
  end
  snap(0);settle(0);sink=0;snap(32'hffffffff);repeat(70)@(negedge clk);
  rst=0;keys=0;repeat(4)@(negedge clk);rst=1;settle(0);
  snap(32'h80010000);settle(32'h80010000);snap(0);settle(0);
  if(stalls<100)$fatal(1,"insufficient backpressure");
  $display("PASS events32: %0d convergence cases, %0d stalled cycles, all32 unique notes, 16-deep FIFO, rapid changes, reset",checks,stalls);$finish;
 end
 initial begin #3000000;$fatal(1,"events timeout");end
endmodule
