`timescale 1ns/1ps
// 1) Old (pre_wifi_control) vs new wifi_control on random traffic of every old
//    command (0x07/0x17 excluded), random rec_* inputs: all outputs equal on
//    every clock. 2) Recorder function on the new controller.
module tb_recording;
 localparam integer CLK_HZ=12288; // MS_TICKS = 12 clocks per "millisecond" in this test
 reg clk=0;always #1 clk=~clk;
 reg rst_n=0;
 // shared stimulus
 reg packet_valid=0;reg [7:0] packet_seq=0,packet_cmd=0,packet_len=0;reg [47:0] packet_payload=0;
 reg response_ready=1,cfg_ready=0;reg [1:0] actual_mode=0,actual_performance=0;reg [2:0] actual_timbre=0,performance_state=0;
 reg switching=0,system_fault=0,score_playing=0,tables_safe=1,keymap_safe=1;reg [15:0] actual_volume=0,actual_tempo=120;
 reg [4:0] key_index=0,score_index=0;
 reg rec_event=0,rec_on=0;reg [6:0] rec_note=0,rec_velocity=0;
 // outputs
 wire pr_o,pr_n,rv_o,rv_n,cv_o,cv_n,kc_o,kc_n,sc_o,sc_n,lk_o,lk_n;
 wire [7:0] rs_o,rs_n,cc_o,cc_n;wire [47:0] rp_o,rp_n;wire [15:0] cval_o,cval_n,kr_o,kr_n,sr_o,sr_n;
 wire [6:0] kn_o,kn_n;wire [31:0] se_o,se_n;wire [5:0] cnt_o,cnt_n;wire [223:0] km_o,km_n;
 pre_wifi_control #(.PERFORMANCE_ENABLE(1),.CLK_HZ(CLK_HZ),.APPLY_TIMEOUT(40),.SESSION_TIMEOUT(5000)) o(
  clk,rst_n,packet_valid,pr_o,packet_seq,packet_cmd,packet_len,packet_payload,rv_o,response_ready,rs_o,rp_o,
  cv_o,cfg_ready,cc_o,cval_o,actual_mode,actual_timbre,switching,system_fault,actual_performance,performance_state,
  actual_volume,actual_tempo,score_playing,tables_safe,keymap_safe,key_index,kn_o,score_index,se_o,cnt_o,kc_o,sc_o,kr_o,sr_o,lk_o,km_o);
 wifi_control #(.PERFORMANCE_ENABLE(1),.CLK_HZ(CLK_HZ),.APPLY_TIMEOUT(40),.SESSION_TIMEOUT(5000)) n(
  clk,rst_n,packet_valid,pr_n,packet_seq,packet_cmd,packet_len,packet_payload,rv_n,response_ready,rs_n,rp_n,
  cv_n,cfg_ready,cc_n,cval_n,actual_mode,actual_timbre,switching,system_fault,actual_performance,performance_state,
  actual_volume,actual_tempo,score_playing,tables_safe,keymap_safe,key_index,kn_n,score_index,se_n,cnt_n,kc_n,sc_n,kr_n,sr_n,lk_n,km_n,
  rec_event,rec_on,rec_note,rec_velocity);
 wire [511:0] out_o={pr_o,rv_o,cv_o,kc_o,sc_o,lk_o,rs_o,cc_o,rp_o,cval_o,kr_o,sr_o,kn_o,se_o,cnt_o,km_o};
 wire [511:0] out_n={pr_n,rv_n,cv_n,kc_n,sc_n,lk_n,rs_n,cc_n,rp_n,cval_n,kr_n,sr_n,kn_n,se_n,cnt_n,km_n};
 integer seed=20261024,cycle=0,checked=0,mism=0,packets=0,errors=0,phase=0,i,k;reg [7:0] tmp_cmd;
 reg [7:0] cmds[0:17];
 initial begin
  cmds[0]=8'h01;cmds[1]=8'h02;cmds[2]=8'h03;cmds[3]=8'h04;cmds[4]=8'h05;cmds[5]=8'h06;cmds[6]=8'h10;cmds[7]=8'h11;cmds[8]=8'h12;
  cmds[9]=8'h13;cmds[10]=8'h14;cmds[11]=8'h15;cmds[12]=8'h16;cmds[13]=8'h20;cmds[14]=8'h21;cmds[15]=8'h22;cmds[16]=8'h24;cmds[17]=8'h31;
 end
 // ---------------- phase 0: equivalence on random traffic ----------------
 always @(posedge clk)begin
  cycle<=cycle+1;
  if(phase==0 && rst_n)begin
   checked=checked+1;
   if(out_o!==out_n)begin mism=mism+1;if(mism<6)$display("MISMATCH cycle %0d cmd %h",cycle,packet_cmd);end
   cfg_ready<=$random(seed);response_ready<=($random(seed)&3)!=0;
   actual_timbre<=$unsigned($random(seed))%5;actual_performance<=$unsigned($random(seed))%3;performance_state<=$random(seed);
   switching<=($random(seed)&7)==0;tables_safe<=($random(seed)&7)!=0;keymap_safe<=($random(seed)&7)!=0;score_playing<=$random(seed);
   actual_volume<=$random(seed);actual_tempo<=30+($unsigned($random(seed))%211);key_index<=$random(seed);score_index<=$random(seed);
   rec_event<=$random(seed);rec_on<=$random(seed);rec_note<=$random(seed);rec_velocity<=$random(seed);
   if(packet_valid && pr_o)begin packet_valid<=0;packets=packets+1;end
   else if(!packet_valid && ($random(seed)&3)==0)begin
    packet_valid<=1;
    // repeat the previous sequence sometimes (retry / conflict paths)
    if(($random(seed)&7)!=0)packet_seq<=packet_seq+1;
    tmp_cmd=(($random(seed)&15)==0)?$random(seed):cmds[$unsigned($random(seed))%18];
    if(tmp_cmd==8'h07 || tmp_cmd==8'h17)tmp_cmd=8'h02; // new commands: not in the old controller
    packet_cmd<=tmp_cmd;
    packet_len<=(($random(seed)&3)==0)?$unsigned($random(seed))%7:(packet_cmd==8'h21?2:packet_cmd==8'h31?5:1);
    packet_payload<={$random(seed),$random(seed)};
    if(($random(seed)&1))packet_payload[7:0]<=$unsigned($random(seed))%33;
    if(($random(seed)&1))packet_payload[15:8]<=36+($unsigned($random(seed))%61);
   end
  end
 end
 // ---------------- phase 1: recorder ----------------
 task automatic send(input [7:0] seq,input [7:0] cmd,input [7:0] len,input [47:0] pl,output [7:0] status,output [31:0] data);
  begin
   @(negedge clk);packet_seq=seq;packet_cmd=cmd;packet_len=len;packet_payload=pl;packet_valid=1;
   while(!pr_n)@(negedge clk);   // accepted on the next rising edge
   @(negedge clk);packet_valid=0;
   while(!rv_n)@(negedge clk);
   status=rp_n[15:8];data=rp_n[47:16];
   @(negedge clk);               // response_ready=1: consumed on the edge in between
  end
 endtask
 task automatic key(input on,input [6:0] note,input [6:0] vel);
  begin @(negedge clk);rec_event=1;rec_on=on;rec_note=note;rec_velocity=vel;@(negedge clk);rec_event=0;end
 endtask
 reg [7:0] st,seqn;reg [31:0] d,d2;integer t0,expect_ms,got;
 initial begin
  #5 rst_n=1;
  wait(cycle==300000);
  // stop random traffic
  phase=1;@(negedge clk);packet_valid=0;rec_event=0;response_ready=1;cfg_ready=0;
  repeat(20)@(posedge clk);
  if(mism!=0)begin $display("FAIL equivalence: %0d mismatches",mism);errors=errors+1;end
  $display("equivalence: %0d clocks, %0d packets accepted, %0d mismatches",checked,packets,mism);
  seqn=8'h80;
  // invalid forms
  send(seqn,8'h17,0,0,st,d);seqn=seqn+1;if(st!=1)begin errors=errors+1;$display("FAIL 0x17 len0 status %0d",st);end
  send(seqn,8'h17,1,48'd2,st,d);seqn=seqn+1;if(st!=1)begin errors=errors+1;$display("FAIL 0x17 p0=2 status %0d",st);end
  send(seqn,8'h07,1,0,st,d);seqn=seqn+1;if(st!=1)begin errors=errors+1;$display("FAIL 0x07 len1 status %0d",st);end
  // disabled: events are not recorded
  key(1,60,100);key(0,60,100);
  send(seqn,8'h07,0,0,st,d);seqn=seqn+1;if(st!=0 || d[31])begin errors=errors+1;$display("FAIL disabled recorded %h",d);end
  // enable, record 10 events at known times
  send(seqn,8'h17,1,48'd1,st,d);seqn=seqn+1;t0=cycle;if(st!=0 || d!=1)begin errors=errors+1;$display("FAIL enable %0d %h",st,d);end
  for(k=0;k<10;k=k+1)begin
   repeat(37*k+5)@(posedge clk);
   expect_ms=(cycle-t0)/12;key(k[0]==0,40+k,64+k);
   // the event is stamped on the clock it is presented
  end
  for(k=0;k<10;k=k+1)begin
   send(seqn,8'h07,0,0,st,d);seqn=seqn+1;
   if(st!=0 || !d[31] || d[30]!=(k[0]==0) || d[29:23]!=40+k || d[22:16]!=64+k)begin errors=errors+1;$display("FAIL event %0d: %h",k,d);end
   if(k>0 && d[15:0]<d2[15:0])begin errors=errors+1;$display("FAIL time order %0d",k);end
   d2=d;
  end
  send(seqn,8'h07,0,0,st,d);seqn=seqn+1;if(d[31] || d[30])begin errors=errors+1;$display("FAIL not empty %h",d);end
  if(d[15:0]!=((cycle-t0)/12) && d[15:0]+1!=((cycle-t0)/12))begin errors=errors+1;$display("FAIL ms %0d vs %0d",d[15:0],(cycle-t0)/12);end
  // retry with the same sequence returns the cached reply and pops only once
  key(1,70,90);key(1,71,91);
  send(seqn,8'h07,0,0,st,d);send(seqn,8'h07,0,0,st,d2);seqn=seqn+1;
  if(d!==d2 || d[29:23]!=70)begin errors=errors+1;$display("FAIL retry %h %h",d,d2);end
  send(seqn,8'h07,0,0,st,d);seqn=seqn+1;if(!d[31] || d[29:23]!=71)begin errors=errors+1;$display("FAIL after retry %h",d);end
  // overflow: 70 events, 64 kept, overflow flag after draining
  for(k=0;k<70;k=k+1)key(1,36+(k%60),1);
  got=0;d=32'h80000000;
  while(d[31])begin send(seqn,8'h07,0,0,st,d);seqn=seqn+1;if(d[31])begin got=got+1;if(d[29:23]!=36+((got-1)%60))begin errors=errors+1;$display("FAIL overflow order %0d",got);end end end
  if(got!=64 || !d[30])begin errors=errors+1;$display("FAIL overflow got %0d flag %0d",got,d[30]);end
  // re-enable clears the flag and the buffer, restarts ms
  key(1,50,50);
  send(seqn,8'h17,1,48'd1,st,d);seqn=seqn+1;t0=cycle;
  send(seqn,8'h07,0,0,st,d);seqn=seqn+1;if(d[31] || d[30] || d[15:0]>2)begin errors=errors+1;$display("FAIL re-enable %h",d);end
  // disable stops recording
  send(seqn,8'h17,1,48'd0,st,d);seqn=seqn+1;if(d!=0)begin errors=errors+1;$display("FAIL disable reply %h",d);end
  key(1,55,55);
  send(seqn,8'h07,0,0,st,d);seqn=seqn+1;if(d[31])begin errors=errors+1;$display("FAIL recorded while off %h",d);end
  // the old controller rejects the new commands as unknown (status 2) - documented, not compared
  if(errors==0)$display("PASS recording: equivalence on old commands and recorder function");else $display("FAIL recording: %0d errors",errors);
  $finish;
 end
endmodule
