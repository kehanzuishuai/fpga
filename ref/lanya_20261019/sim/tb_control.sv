`timescale 1ns/1ps
module tb_control;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0,pv=0,rr=1,ready=1,safe=1,keys_safe=1;wire pr,rv,cv,linked,kc,sc;
 reg [7:0] seq=0,cmd=0,len=0;reg [47:0] payload=0;
 wire [7:0] rs,cc;wire [47:0] rp;wire [15:0] value;
 reg [4:0] ki=0;wire [6:0] kn;reg [4:0] si=0;wire [31:0] event_data;wire [5:0] count;
 integer config_count=0,kcommit=0,scommit=0,i;
 wifi_control #(.CLK_HZ(1000),.APPLY_TIMEOUT(20),.SESSION_TIMEOUT(500)) dut(
 .clk(clk),.rst_n(rst_n),.packet_valid(pv),.packet_ready(pr),.packet_seq(seq),.packet_cmd(cmd),.packet_len(len),.packet_payload(payload),
 .response_valid(rv),.response_ready(rr),.response_seq(rs),.response_payload(rp),.cfg_valid(cv),.cfg_ready(ready),.cfg_cmd(cc),.cfg_value(value),
 .actual_volume(16'd65535),.actual_tempo(16'd120),.score_playing(1'b0),.score_revision(),.actual_mode(2'd0),.actual_timbre(3'd0),.switching(1'b0),.system_fault(1'b0),.keymap_revision(),.keymap_safe(keys_safe),.tables_safe(safe),.key_index(ki),.key_note(kn),
 .score_index(si),.score_event(event_data),.score_count(count),.keymap_committed(kc),.score_committed(sc),.linked(linked));
 always @(posedge clk)if(rst_n)begin
  if(cv&&ready)config_count=config_count+1;
  if(kc)kcommit=kcommit+1;
  if(sc)scommit=scommit+1;
 end
 task request(input [7:0] s,c,l,input [47:0] p,input [7:0] status);
 integer timeout_count;
 begin
  @(negedge clk);while(!pr)@(negedge clk);
  seq=s;cmd=c;len=l;payload=p;pv=1;@(negedge clk);pv=0;
  timeout_count=0;
  while(!rv)begin @(negedge clk);timeout_count=timeout_count+1;if(timeout_count>100)$fatal(1,"response missing");end
  if(rs!==s || rp[7:0]!==c || rp[15:8]!==status)$fatal(1,"bad reply cmd=%h seq=%d status=%d wanted=%d",c,s,rp[15:8],status);
  @(negedge clk);
 end endtask
 initial begin
  repeat(4)@(negedge clk);rst_n=1;
  request(0,1,0,0,0);
  request(1,16,1,2,0);if(config_count!=1)$fatal(1,"config");
  request(1,16,1,2,0);if(config_count!=1)$fatal(1,"duplicate reapplied");
  request(1,16,1,1,4);if(config_count!=1)$fatal(1,"conflict applied");
  request(1,16,2,2,4); // same payload, different length must conflict
  request(2,16,1,3,1);request(3,17,1,5,1);request(4,19,1,32,1);
  request(5,8'hff,0,0,2);
  ready=0;request(6,18,2,12345,3);if(config_count!=1)$fatal(1,"busy applied");
  ready=1;request(6,18,2,12345,3); // cached BUSY; fresh sequence needed
  request(7,18,2,12345,0);if(config_count!=2)$fatal(1,"new retry missing");
  request(8,32,0,0,0);request(9,33,2,{32'b0,8'd36,8'd0},0);
  if(kn!=60)$fatal(1,"partial map leaked");
  request(81,33,2,{32'b0,8'd60,8'd32},1);
  request(82,33,2,{32'b0,8'd35,8'd1},1);
  request(83,33,2,{32'b0,8'd97,8'd1},1);
  request(10,34,0,0,1); // incomplete
  for(i=1;i<32;i=i+1)begin
   request(8'(10+i),33,2,48'((36+i)*256+i),0);
   if(i==15)request(80,34,0,0,1); // first board alone must never commit
  end
  safe=0;request(26,34,0,0,3);if(kn!=60)$fatal(1,"unsafe commit");
  safe=1;keys_safe=0;request(25,34,0,0,3);if(kn!=60)$fatal(1,"held keys committed");
  keys_safe=1;request(27,34,0,0,0);if(kn!=36 || kcommit!=1)$fatal(1,"commit failed");
  request(27,34,0,0,0);if(kcommit!=1)$fatal(1,"duplicate commit");
  for(i=0;i<32;i=i+1)begin ki=5'(i);#1;if(kn!=36+i)$fatal(1,"map mismatch");end
  ki=0;
  request(70,5,0,0,0);if(rp[47:16]!={16'd1,8'd0,8'd32})$fatal(1,"key metadata");
  request(71,8'h24,1,31,0);if(rp[47:16]!={16'd1,8'd67,8'd31})$fatal(1,"second keyboard readback");
  request(72,8'h24,1,32,1);
  request(28,32,0,0,0);request(29,33,2,{32'b0,8'd40,8'd0},0);request(30,35,0,0,0);
  request(31,34,0,0,1);if(kn!=36)$fatal(1,"abort leaked");
  request(32,48,1,2,0);request(33,49,5,{8'b0,16'd500,8'd100,8'd60,8'd0},0);
  if(count!=0 || event_data!=0)$fatal(1,"partial score leaked");
  request(34,50,0,0,1);
  request(35,49,5,{8'b0,16'd0,8'd100,8'd64,8'd1},1);
  request(36,49,5,{8'b0,16'd1000,8'd0,8'd64,8'd1},0);
  safe=0;request(37,50,0,0,3);safe=1;request(38,50,0,0,0);
  if(count!=2 || event_data!={16'd500,8'd100,8'd60} || scommit!=1)$fatal(1,"score commit");
  si=1;#1;if(event_data!={16'd1000,8'd0,8'd64})$fatal(1,"score read");
  si=2;#1;if(event_data!=0)$fatal(1,"out of range score");
  request(100,48,1,32,0);
  for(i=0;i<32;i=i+1)request(8'(101+i),49,5,{8'b0,16'd65535,8'd127,8'd127,8'(i)},0);
  request(133,50,0,0,0);si=31;#1;
  if(count!=32||event_data!={16'hffff,8'd127,8'd127})$fatal(1,"32 event mask/endpoints");
  request(39,48,1,32,0);request(40,51,0,0,0);request(41,50,0,0,1);
  request(200,8'h14,2,29,1);request(201,8'h14,2,241,1);
  request(202,8'h15,1,2,1);request(203,8'h15,2,1,1);
  request(204,8'h14,2,180,0);request(205,8'h03,0,0,0);
  if(rp[47:16]!={16'd120,16'd65535})$fatal(1,"settings returned command echo instead of actual");
  request(206,8'h04,0,0,0);if(rp[47:16]!={16'd2,8'd0,8'd32})$fatal(1,"score revision metadata");
  request(254,1,0,0,0);request(255,1,0,0,0);request(0,1,0,0,0);
  request(1,32,0,0,0);repeat(510)@(negedge clk);
  if(linked)$fatal(1,"link timeout");request(2,33,2,{32'b0,8'd80,8'd0},1);
  if(kn!=36 || count!=32)$fatal(1,"disconnect corrupted active tables");
  rr=0;@(negedge clk);seq=3;cmd=1;len=0;payload=0;pv=1;@(negedge clk);pv=0;
  repeat(4)@(negedge clk);if(!rv||pr)$fatal(1,"response backpressure");
  repeat(6)begin @(negedge clk);if(rs!=3||rp[31:16]!=16'h3031)$fatal(1,"response changed");end
  rr=1;repeat(3)@(negedge clk);
  rst_n=0;repeat(2)@(negedge clk);rst_n=1;#1;
  if(kn!=60||count!=0||linked)$fatal(1,"reset");
  $display("PASS control: bounds, duplicates, conflict, cfg timeout, atomic key/score commit, abort, disconnect, seq wrap, backpressure, reset");$finish;
 end
 initial begin #1000000;$fatal(1,"watchdog");end
endmodule
