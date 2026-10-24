`timescale 1ns/1ps
// Old (pre_piano_note_loader) and pipelined loader, each driven by the same
// request stream at its own pace (next request once busy drops, as the note
// FIFO does). Each harness models what a voice keeps from a load: the 16 x 25
// RAM words, rel_slope at ld_done and the future_audible record the voice
// builds from the write order (cleared by the write to address 0).
// At every ld_done the harness logs voice, rel_slope, record and all words.
module loader_harness #(parameter NEW=0,parameter integer NREQ=600,parameter LOG="x.txt")(input wire clk,rst_n);
 reg req_valid;reg [4:0] req_voice;reg [6:0] req_note;reg [7:0] req_vel;reg [31:0] req_inc;
 reg [31:0] voice_ready;
 wire busy;wire [31:0] ld_we,ld_done;wire [8:0] ld_addr;wire [31:0] ld_data;wire [21:0] ld_rel_slope;
 generate if(NEW)begin:g
  piano_note_loader #(.VOICES(32),.IDX_W(5)) u(clk,rst_n,req_valid,req_voice,req_note,req_vel,req_inc,busy,voice_ready,ld_we,ld_addr,ld_data,ld_done,ld_rel_slope);
 end else begin:g
  pre_piano_note_loader #(.VOICES(32),.IDX_W(5)) u(clk,rst_n,req_valid,req_voice,req_note,req_vel,req_inc,busy,voice_ready,ld_we,ld_addr,ld_data,ld_done,ld_rel_slope);
 end endgenerate
 localparam [11:0] LAST_AUDIBLE_BP=12'd3301;
 reg [31:0] ram[0:32*512-1];reg [20:0] fa[0:31];
 integer seed,issued,done_count,f,i,a,gap,wait_left,wait_voice,start_cycle,cycle,bp_before_clear,max_cycles,sum_cycles;
 reg cleared;
 reg [6:0] notes[0:6];reg [7:0] vels[0:10];
 initial begin
  notes[0]=0;notes[1]=23;notes[2]=24;notes[3]=25;notes[4]=104;notes[5]=105;notes[6]=127;
  vels[0]=0;vels[1]=39;vels[2]=40;vels[3]=41;vels[4]=79;vels[5]=80;vels[6]=81;vels[7]=119;vels[8]=120;vels[9]=121;vels[10]=127;
  seed=20261024;issued=0;done_count=0;gap=0;wait_left=0;wait_voice=0;cycle=0;bp_before_clear=0;max_cycles=0;sum_cycles=0;cleared=1;
  req_valid=0;voice_ready=32'hffffffff;f=$fopen(LOG,"w");
 end
 always @(posedge clk)begin
  cycle<=cycle+1;req_valid<=0;
  if(wait_left>0)begin wait_left<=wait_left-1;if(wait_left==1)voice_ready[wait_voice]<=1;end
  // Writes and done of the running load first: busy drops on the clock
  // ld_done is seen, and a new request for the same voice clears its RAM image.
  for(i=0;i<32;i=i+1)if(ld_we[i])begin
   ram[i*512+ld_addr]=ld_data;
   if(ld_addr==9'd0)begin fa[i]=21'd0;cleared=1;end
   else if(ld_addr[4:0]>=5'd4 && ld_addr[4:0]<=5'd24)begin
    if(!cleared)bp_before_clear=bp_before_clear+1;
    if(ld_data[11:0]<=LAST_AUDIBLE_BP)fa[i][ld_addr[4:0]-5'd4]=1'b1;
   end
  end
  for(i=0;i<32;i=i+1)if(ld_done[i])begin
   done_count=done_count+1;
   if(cycle-start_cycle>max_cycles)max_cycles=cycle-start_cycle;sum_cycles=sum_cycles+cycle-start_cycle;
   $fwrite(f,"done %0d voice %0d rel %h fa %h\n",done_count,i,ld_rel_slope,fa[i]);
   for(a=0;a<512;a=a+1)if(a[4:0]<25)$fwrite(f,"%0d %h\n",a,ram[i*512+a]);
  end
  if(rst_n && !busy && !req_valid && issued<NREQ)begin
   if(gap>0)gap<=gap-1;
   else begin
    req_voice=$random(seed);
    if(issued<77)begin req_note=notes[issued%7];req_vel=vels[issued/7];end
    else begin req_note=$random(seed);req_vel=$random(seed);end
    req_inc=$random(seed);
    req_valid<=1;issued<=issued+1;gap<=$unsigned($random(seed))%4;
    // Voice still fading: hold ready low for 0..63 clocks.
    a=$unsigned($random(seed))%64;
    if(a>0)begin voice_ready[req_voice]<=0;wait_left<=a;wait_voice<=req_voice;end
    for(i=0;i<512;i=i+1)ram[req_voice*512+i]=32'bx;
    fa[req_voice]=21'h1fffff;cleared=0;start_cycle=cycle;
   end
  end
 end
endmodule

module tb_loader_pipeline #(parameter integer NREQ=600);
 reg clk=0;always #1 clk=~clk;
 reg rst_n=0;initial #10 rst_n=1;
 loader_harness #(.NEW(0),.NREQ(NREQ),.LOG("old.txt")) o(clk,rst_n);
 loader_harness #(.NEW(1),.NREQ(NREQ),.LOG("new.txt")) n(clk,rst_n);
 initial begin
  wait(o.done_count==NREQ && n.done_count==NREQ);
  $display("old: loads %0d max %0d mean %0d clocks request->done, bp_before_clear %0d",o.done_count,o.max_cycles,o.sum_cycles/NREQ,o.bp_before_clear);
  $display("new: loads %0d max %0d mean %0d clocks request->done, bp_before_clear %0d",n.done_count,n.max_cycles,n.sum_cycles/NREQ,n.bp_before_clear);
  $fclose(o.f);$fclose(n.f);$finish;
 end
 initial begin #20000000;$display("TIMEOUT old %0d new %0d",o.done_count,n.done_count);$finish;end
endmodule
