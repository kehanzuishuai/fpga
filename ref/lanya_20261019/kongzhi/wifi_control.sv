`default_nettype none
// Stop-and-wait controller. All effects occur once per accepted request.
// cfg_ready acknowledges enqueueing a request, NOT completion of mode switching.
module wifi_control #(parameter integer CLK_HZ=12288000,
 APPLY_TIMEOUT=CLK_HZ/5,SESSION_TIMEOUT=CLK_HZ*5)(
 input wire clk,rst_n,
 input wire packet_valid,output wire packet_ready,
 input wire [7:0] packet_seq,packet_cmd,packet_len,
 input wire [47:0] packet_payload,
 output reg response_valid,input wire response_ready,
 output reg [7:0] response_seq,output reg [47:0] response_payload,
 output reg cfg_valid,input wire cfg_ready,
 output reg [7:0] cfg_cmd,output reg [15:0] cfg_value,
 input wire [1:0] actual_mode,input wire [2:0] actual_timbre,
 input wire switching,system_fault,
 input wire [15:0] actual_volume,actual_tempo,input wire score_playing,
 input wire tables_safe,keymap_safe,input wire [4:0] key_index,output wire [6:0] key_note,
 input wire [4:0] score_index,output wire [31:0] score_event,
 output reg [5:0] score_count,output reg keymap_committed,score_committed,
 output reg [15:0] keymap_revision,score_revision,output reg linked
);
 reg [7:0] current_seq,current_cmd;
 reg [63:0] current_request,last_request;
 reg [7:0] last_seq;reg [47:0] last_response;reg cache_valid;
 reg waiting;reg [31:0] wait_ticks,link_ticks;
 reg [223:0] keys_active,keys_stage;
 reg [1023:0] score_active,score_stage;
 reg [31:0] key_written;reg key_open,score_open;
 reg [31:0] score_written;reg [5:0] stage_count;
 reg [15:0] volume;reg [4:0] effects;
 integer i;
 wire [63:0] request_bits={packet_len,packet_cmd,packet_payload};
 wire [7:0] p0=packet_payload[7:0],p1=packet_payload[15:8];
 wire [15:0] value=packet_payload[15:0];
 wire [31:0] needed_mask=stage_count==32?32'hffffffff:((32'h1<<stage_count)-1'b1);
 assign packet_ready=!waiting && !response_valid;
 assign key_note=keys_active[key_index*7+:7];
 assign score_event={1'b0,score_index}<score_count?score_active[score_index*32+:32]:32'b0;
 task automatic reply(input [7:0] status,input [31:0] result);
  begin
   response_valid<=1;response_seq<=packet_seq;
   response_payload<={result,status,packet_cmd};
   if(status!=4)begin cache_valid<=1;last_seq<=packet_seq;
    last_request<=request_bits;last_response<={result,status,packet_cmd};end
  end
 endtask
 initial if(APPLY_TIMEOUT<1 || SESSION_TIMEOUT<1 || CLK_HZ<1)$fatal(1,"control parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  response_valid<=0;response_seq<=0;response_payload<=0;
  cfg_valid<=0;cfg_cmd<=0;cfg_value<=0;waiting<=0;wait_ticks<=0;
  current_seq<=0;current_cmd<=0;current_request<=0;
  cache_valid<=0;last_seq<=0;last_request<=0;last_response<=0;
  key_written<=0;key_open<=0;score_open<=0;score_written<=0;stage_count<=0;
  score_count<=0;score_revision<=0;keymap_revision<=0;volume<=65535;effects<=0;linked<=0;link_ticks<=0;
  keymap_committed<=0;score_committed<=0;
  for(i=0;i<32;i=i+1)begin keys_active[i*7+:7]<=7'(60+(i%16)+(i/16)*12);keys_stage[i*7+:7]<=7'(60+(i%16)+(i/16)*12);end
  for(i=0;i<32;i=i+1)begin score_active[i*32+:32]<=0;score_stage[i*32+:32]<=0;end
 end else begin
  keymap_committed<=0;score_committed<=0;
  if(response_valid && response_ready)response_valid<=0;
  if(linked)begin
   if(link_ticks>=32'(SESSION_TIMEOUT-1))begin linked<=0;key_open<=0;score_open<=0;end
   else link_ticks<=link_ticks+1'b1;
  end
  if(waiting)begin
   if(cfg_valid && cfg_ready)begin
    cfg_valid<=0;waiting<=0;response_valid<=1;response_seq<=current_seq;
    response_payload<={16'b0,cfg_value,8'd0,current_cmd};
    cache_valid<=1;last_seq<=current_seq;last_request<=current_request;
    last_response<={16'b0,cfg_value,8'd0,current_cmd};
    if(current_cmd==8'h12)volume<=cfg_value;
    if(current_cmd==8'h13)effects<=cfg_value[4:0];
   end else if(wait_ticks>=32'(APPLY_TIMEOUT-1))begin
    cfg_valid<=0;waiting<=0;response_valid<=1;response_seq<=current_seq;
    response_payload<={32'b0,8'd3,current_cmd};
    cache_valid<=1;last_seq<=current_seq;last_request<=current_request;
    last_response<={32'b0,8'd3,current_cmd};
   end else wait_ticks<=wait_ticks+1'b1;
  end
  if(packet_valid && packet_ready)begin
   linked<=1;link_ticks<=0;
   if(cache_valid && last_seq==packet_seq)begin
    if(last_request==request_bits)begin response_valid<=1;response_seq<=packet_seq;response_payload<=last_response;end
    else reply(8'd4,0);
   end else case(packet_cmd)
    8'h01:if(packet_len==0)reply(0,32'h42543031);else reply(1,0);
    8'h02:if(packet_len==0)reply(0,{volume,{3'b0,effects},{1'b0,system_fault,switching,actual_timbre,actual_mode}});else reply(1,0);
    8'h03:if(packet_len==0)reply(0,{actual_tempo,actual_volume});else reply(1,0);
    8'h04:if(packet_len==0)reply(0,{score_revision,7'b0,score_playing,2'b0,score_count});else reply(1,0);
    8'h05:if(packet_len==0)reply(0,{keymap_revision,8'd0,8'd32});else reply(1,0);
    8'h24:if(packet_len==1 && p0<32)reply(0,{keymap_revision,1'b0,keys_active[p0[4:0]*7+:7],p0});else reply(1,0);
    8'h10,8'h11,8'h12,8'h13,8'h14,8'h15:begin
     if((packet_cmd==8'h10 && packet_len==1 && p0<=2) ||
        (packet_cmd==8'h11 && packet_len==1 && p0<=4) ||
        (packet_cmd==8'h12 && packet_len==2) ||
        (packet_cmd==8'h13 && packet_len==1 && p0<=31) ||
        (packet_cmd==8'h14 && packet_len==2 && value>=30 && value<=240) ||
        (packet_cmd==8'h15 && packet_len==1 && p0<=1))begin
      waiting<=1;wait_ticks<=0;cfg_valid<=1;cfg_cmd<=packet_cmd;cfg_value<=value;
      current_seq<=packet_seq;current_cmd<=packet_cmd;current_request<=request_bits;
     end else reply(1,0);
    end
    8'h20:if(packet_len==0)begin key_open<=1;key_written<=0;reply(0,0);end else reply(1,0);
    8'h21:if(packet_len==2 && key_open && p0<32 && p1>=36 && p1<=96)begin
     keys_stage[p0[4:0]*7+:7]<=p1[6:0];key_written[p0[4:0]]<=1;reply(0,0);
    end else reply(1,0);
    8'h22:if(packet_len!=0 || !key_open || key_written!=32'hffffffff)reply(1,0);
     else if(!tables_safe || !keymap_safe)reply(3,0);
     else begin keys_active<=keys_stage;key_open<=0;keymap_revision<=keymap_revision+1'b1;keymap_committed<=1;reply(0,0);end
    8'h23:if(packet_len==0)begin key_open<=0;key_written<=0;reply(0,0);end else reply(1,0);
    8'h30:if(packet_len==1 && p0>0 && p0<=32)begin
     score_open<=1;stage_count<=p0[5:0];score_written<=0;reply(0,0);
    end else reply(1,0);
    8'h31:if(packet_len==5 && score_open && {1'b0,p0[4:0]}<stage_count && p0<32 &&
     p1<128 && packet_payload[23:16]<128 && packet_payload[39:24]!=0)begin
     score_stage[p0[4:0]*32+:32]<=packet_payload[39:8];score_written[p0[4:0]]<=1;reply(0,0);
    end else reply(1,0);
    8'h32:if(packet_len!=0 || !score_open || (score_written&needed_mask)!=needed_mask)reply(1,0);
     else if(!tables_safe)reply(3,0);
     else begin score_active<=score_stage;score_count<=stage_count;score_revision<=score_revision+1'b1;
      score_open<=0;score_committed<=1;reply(0,0);end
    8'h33:if(packet_len==0)begin score_open<=0;score_written<=0;reply(0,0);end else reply(1,0);
    default:reply(2,0);
   endcase
  end
 end
endmodule
`default_nettype wire
