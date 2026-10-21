`timescale 1ns/1ps
module tb_keyboard_events;
reg clk=0,rst_n=0;always #5 clk=~clk;
reg fv=0,fe=0;reg[15:0]raw=0;
wire[15:0]keys,ar;wire av,me;wire[31:0]rejected;
localparam[111:0]NOTES={7'd75,7'd74,7'd73,7'd72,7'd71,7'd70,7'd69,7'd68,7'd67,7'd66,7'd65,7'd64,7'd63,7'd62,7'd61,7'd60};
keyboard_state_mapper #(.RAW_MAP_ENABLE(1),.RAW_INDEX_TABLE(64'hfedc43210ba98765),
 .NOTE_TABLE(NOTES),.CHECK_NOTE_UNIQUE(1)) map(clk,rst_n,fv,fe,raw,keys,ar,av,me,rejected);
wire ev,on,ready;wire[6:0]note;wire[7:0]vel;wire[1:0]wave;
wire[3:0]key;wire[15:0]reported;
ttp229_event_bridge #(.USE_NOTE_TABLE(1),.NOTE_TABLE(NOTES)) bridge(
 clk,rst_n,av,keys,8'd100,ready,ev,on,note,vel,wave,key,reported);
reg sink=1;wire ov,oo;wire[6:0]no;wire[7:0]vo;wire[1:0]wo;wire[4:0]level;
note_event_fifo fifo(clk,rst_n,ev,ready,on,note,vel,wave,ov,sink,oo,no,vo,wo,level);
reg[15:0]held=0;integer accepted=0,consumed=0,checks=0,stalls=0;
reg[7:0]queue[0:4095];reg was_stall=0;reg[21:0]stalled_payload;
integer index;
always @(posedge clk)begin
 if(!rst_n)begin held=0;accepted=0;consumed=0;was_stall=0;end
 else begin
  if(was_stall && (!ev || {on,note,vel,wave,key}!==stalled_payload))
    $fatal(1,"bridge payload changed under backpressure");
  was_stall=ev&&!ready;stalled_payload={on,note,vel,wave,key};
  if(was_stall)stalls=stalls+1;
  if(ev&&ready)begin
   if(vel!==100 || note!==60+key)$fatal(1,"event key/MIDI/velocity mismatch");
   queue[accepted]={on,note};accepted=accepted+1;
  end
  if(ov&&sink)begin
   if(consumed>=accepted || queue[consumed]!=={oo,no})$fatal(1,"FIFO event order/loss");
   consumed=consumed+1;index=no-60;
   if(index<0 || index>15)$fatal(1,"bad MIDI");
   if(oo && held[index])$fatal(1,"duplicate NoteOn");
   if(!oo && !held[index])$fatal(1,"unmatched NoteOff");
   held[index]=oo;
  end
  if(level>16)$fatal(1,"FIFO overflow");
 end
end
function[15:0]raw_for_keys(input[15:0]v);
integer k;reg[63:0]t;
begin t=64'hfedc43210ba98765;raw_for_keys=0;
 for(k=0;k<16;k=k+1)raw_for_keys[t[k*4+:4]]=v[k];
end endfunction
task snap(input[15:0]v,input valid,input error);
begin @(negedge clk);raw=raw_for_keys(v);fv=valid;fe=error;
 @(negedge clk);fv=0;fe=0;end endtask
task settle(input[15:0]want);
begin sink=1;repeat(180)@(negedge clk);checks=checks+1;
 if(keys!==want || held!==want || level!=0 || ev || accepted!=consumed)
 $fatal(1,"state convergence want=%h keys=%h held=%h fifo=%d",want,keys,held,level);
end endtask
reg[31:0]raw32=0;reg f32=0;wire[31:0]k32,a32,re32;wire v32,m32;
keyboard_state_mapper #(.KEYS(32),.INDEX_W(5)) mfuture(
 clk,rst_n,f32,1'b0,raw32,k32,a32,v32,m32,re32);
wire[15:0]badkeys,badraw;wire badv,badmap;wire[31:0]badcount;
keyboard_state_mapper #(.RAW_MAP_ENABLE(1),.RAW_INDEX_TABLE(64'd0)) invalid_map(
 clk,rst_n,fv,fe,raw,badkeys,badraw,badv,badmap,badcount);
wire[15:0]alias_keys,alias_raw;wire alias_v,alias_map;wire[31:0]alias_count;
keyboard_state_mapper #(.CHECK_NOTE_UNIQUE(1),.NOTE_TABLE(112'd0)) invalid_notes(
 clk,rst_n,fv,fe,raw,alias_keys,alias_raw,alias_v,alias_map,alias_count);
integer k,n;reg[15:0]chord;
initial begin
 $dumpfile("tests/results/keyboard/keyboard_events.vcd");
 $dumpvars(0,clk,rst_n,raw,keys,av,ev,ready,on,note,key,level,ov,sink,held);
 #1;rst_n=1;#1;rst_n=0;repeat(3)@(negedge clk);rst_n=1;
 for(k=0;k<16;k=k+1)begin snap(16'b1<<k,1,0);settle(16'b1<<k);snap(0,1,0);settle(0);end
 for(n=2;n<=16;n=n+1)if(n==2||n==3||n==5||n==8||n==16)begin
  chord=(17'd1<<n)-1;snap(chord,1,0);settle(chord);
  snap(chord&~16'h0002,1,0);settle(chord&~16'h0002);
  snap(0,1,0);settle(0);
 end
 snap(16'h0015,1,0);settle(16'h0015);
 snap(16'h0011,1,0);settle(16'h0011);
 snap(16'hffff,0,0);settle(16'h0011);
 snap(16'hffff,1,1);settle(16'h0011);
 if(rejected!=1)$fatal(1,"invalid-frame accounting");
 snap(0,1,0);settle(0);
 sink=0;snap(16'hffff,1,0);repeat(100)@(negedge clk);
 if(level!=16)$fatal(1,"did not fill FIFO");
 snap(0,1,0);repeat(100)@(negedge clk);
 if(!ev || ready || !was_stall)$fatal(1,"did not hold NoteOff under backpressure");
 settle(0);
 // Different keys change in one scan; accepted events remain ordered.
 snap(16'haaaa,1,0);settle(16'haaaa);snap(16'h5555,1,0);settle(16'h5555);snap(0,1,0);settle(0);
 for(n=0;n<8;n=n+1)begin snap(16'h0101,1,0);settle(16'h0101);snap(0,1,0);settle(0);end
 if(!badmap || badkeys!=0 || badv || !alias_map || alias_keys!=0 || alias_v)$fatal(1,"bad mapping not rejected");
 for(k=0;k<32;k=k+1)begin
  @(negedge clk);raw32=32'b1<<k;f32=1;
  @(negedge clk);f32=0;checks=checks+1;
  if(k32!==(32'b1<<k) || m32)$fatal(1,"32-bit mapper boundary");
 end
 sink=0;snap(16'hffff,1,0);repeat(80)@(negedge clk);
 rst_n=0;repeat(4)@(negedge clk);rst_n=1;fv=0;sink=1;
 repeat(50)@(negedge clk);
 if(held || keys || level || ev)$fatal(1,"reset left stale events");
 snap(16'h0201,1,0);settle(16'h0201);snap(0,1,0);settle(0);
 if(stalls<50)$fatal(1,"backpressure not exercised");
 $display("PASS keyboard events: %0d convergence/map checks; %0d stalled cycles; 16-key permutation, chords 2/3/5/8/16, release, invalid frames, full FIFO, reset, 32-bit map",checks,stalls);
 $finish;
end
initial begin #1000000;$fatal(1,"unit timeout");end
endmodule
