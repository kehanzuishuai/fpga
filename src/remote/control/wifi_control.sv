`default_nettype none
// Stop-and-wait controller. All effects occur once per accepted request.
// cfg_ready acknowledges enqueueing a request, NOT completion of mode switching.
module wifi_control #(parameter integer STREAM_ENABLE=0,PERFORMANCE_ENABLE=0,CLK_HZ=12288000,
 APPLY_TIMEOUT=CLK_HZ/5,SESSION_TIMEOUT=CLK_HZ*5,
 parameter [223:0] DEFAULT_KEYS=224'hb76acd8af5aad4a74a8d09f3a6cc972a4c88f1a2c4870a0c07ef9ebc)(
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
 input wire [1:0] actual_performance,input wire [2:0] performance_state,
 input wire [15:0] actual_volume,actual_tempo,input wire score_playing,
 input wire tables_safe,keymap_safe,input wire [4:0] key_index,output wire [6:0] key_note,
 input wire [4:0] score_index,output wire [31:0] score_event,
 output reg [5:0] score_count,output reg keymap_committed,score_committed,
 output reg [15:0] keymap_revision,score_revision,output reg linked,
 output wire [223:0] key_map,
 // Physical-key recording for the phone (commands 0x07/0x17).
 input wire rec_event,rec_on,input wire [6:0] rec_note,rec_velocity,
 output wire recording_enabled,output reg recording_restarted,
 input wire sample_tick,stream_start,stream_stop,stream_abort,stream_ready,
 output wire stream_valid,stream_on,stream_loaded,stream_playing,stream_fault,
 output wire [6:0] stream_note,stream_velocity
);
 reg stream_begin,stream_push,stream_seal;
 reg [47:0] stream_data;
 wire [31:0] stream_status;
 wire stream_push_ready;
 generate if(STREAM_ENABLE!=0)begin:G_STREAM
 wifi_stream_player stream(.clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),.tempo(actual_tempo),
 .begin_session(stream_begin),.unload(score_committed),.push(stream_push),.push_data(stream_data),.seal(stream_seal),
 .start(stream_start),.stop(stream_stop),.abort_play(stream_abort),.push_ready(stream_push_ready),
 .loaded(stream_loaded),.playing(stream_playing),.fault(stream_fault),.status(stream_status),
 .event_valid(stream_valid),.event_ready(stream_ready),.event_on(stream_on),.event_note(stream_note),.event_velocity(stream_velocity));
 end else begin:G_NO_STREAM
 assign stream_status=0;assign stream_push_ready=0;assign stream_loaded=0;assign stream_playing=0;assign stream_fault=0;
 assign stream_valid=0;assign stream_on=0;assign stream_note=0;assign stream_velocity=0;
 end endgenerate
 reg [7:0] current_seq,current_cmd;
 reg [63:0] current_request,last_request;
 reg [7:0] last_seq;reg [47:0] last_response;reg cache_valid;
 reg waiting;reg [31:0] wait_ticks,link_ticks;
 reg [223:0] keys_active,keys_stage;
 reg [1023:0] score_active,score_stage;
 reg [31:0] key_written;reg key_open,score_open;
 reg [31:0] score_written;reg [5:0] stage_count;
 reg [15:0] volume;reg [4:0] effects; reg [7:0] expression_velocity, expression_glide, expression_vibrato;
 integer i;
 // Recorder: 64 x {on,note,velocity,ms} in distributed RAM. The millisecond
 // counter restarts at 0 when recording is switched on.
 localparam integer MS_TICKS=CLK_HZ/1000;
 reg rec_enabled,rec_overflow;reg [15:0] rec_ms;reg [31:0] rec_tick;
 reg [30:0] rec_mem[0:63];reg [6:0] rec_wp,rec_rp;
 wire rec_empty=rec_wp==rec_rp;
 wire rec_full=rec_wp=={~rec_rp[6],rec_rp[5:0]};
 wire rec_control=packet_valid && packet_ready && packet_cmd==8'h17 && packet_len==1 && packet_payload[7:0]<=1 && !(cache_valid && last_seq==packet_seq);
 assign recording_enabled=rec_enabled;
 wire rec_write=rec_event && rec_enabled && !rec_full && !rec_control;
 wire [30:0] rec_head=rec_mem[rec_rp[5:0]];
 always @(posedge clk)if(rec_write)rec_mem[rec_wp[5:0]]<={rec_on,rec_note,rec_velocity,rec_ms};
 // Commit scans one staged key per clock. A 128-bit membership set replaces
 // 496 simultaneous pitch comparisons; active mapping stays atomic.
 reg checking_keys,key_commit_safe;
 reg [4:0] key_scan_index;
 reg [127:0] key_seen;
 wire [6:0] key_scan_note=keys_stage[key_scan_index*7+:7];
 wire [63:0] request_bits={packet_len,packet_cmd,packet_payload};
 wire [7:0] p0=packet_payload[7:0],p1=packet_payload[15:8];
 wire [15:0] value=packet_payload[15:0];
 wire [31:0] needed_mask=stage_count==32?32'hffffffff:((32'h1<<stage_count)-1'b1);
 assign packet_ready=!waiting && !checking_keys && !response_valid;
 assign key_note=keys_active[key_index*7+:7];
 assign key_map=keys_active;
 assign score_event={1'b0,score_index}<score_count?score_active[score_index*32+:32]:32'b0;
 task automatic reply(input [7:0] status,input [31:0] result);
  begin
   response_valid<=1;response_seq<=packet_seq;
   response_payload<={result,status,packet_cmd};
   if(status!=4)begin cache_valid<=1;last_seq<=packet_seq;
    last_request<=request_bits;last_response<={result,status,packet_cmd};end
  end
 endtask
 task automatic key_reply(input [7:0] status);
  begin
   checking_keys<=0;response_valid<=1;response_seq<=current_seq;
   response_payload<={32'd0,status,current_cmd};
   cache_valid<=1;last_seq<=current_seq;last_request<=current_request;
   last_response<={32'd0,status,current_cmd};
  end
 endtask
 initial if(APPLY_TIMEOUT<1 || SESSION_TIMEOUT<1 || CLK_HZ<1)$fatal(1,"control parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  response_valid<=0;response_seq<=0;response_payload<=0;stream_begin<=0;stream_push<=0;stream_seal<=0;stream_data<=0;
  cfg_valid<=0;cfg_cmd<=0;cfg_value<=0;waiting<=0;wait_ticks<=0;
  current_seq<=0;current_cmd<=0;current_request<=0;
  cache_valid<=0;last_seq<=0;last_request<=0;last_response<=0;
  key_written<=0;key_open<=0;score_open<=0;score_written<=0;stage_count<=0;
  score_count<=0;score_revision<=0;keymap_revision<=0;volume<=65535;effects<=0; expression_velocity<=8'd100; expression_glide<=0; expression_vibrato<=0; linked<=0;link_ticks<=0;
  keymap_committed<=0;score_committed<=0;
  keys_active<=DEFAULT_KEYS;keys_stage<=DEFAULT_KEYS;
  checking_keys<=0;key_commit_safe<=0;key_scan_index<=0;key_seen<=0;
  recording_restarted<=0;rec_enabled<=0;rec_overflow<=0;rec_ms<=0;rec_tick<=0;rec_wp<=0;rec_rp<=0;
  for(i=0;i<32;i=i+1)begin score_active[i*32+:32]<=0;score_stage[i*32+:32]<=0;end
 end else begin
  keymap_committed<=0;score_committed<=0;recording_restarted<=0;stream_begin<=0;stream_push<=0;stream_seal<=0;
  if(rec_tick>=32'(MS_TICKS-1))begin rec_tick<=0;rec_ms<=rec_ms+1'b1;end else rec_tick<=rec_tick+1'b1;
  if(rec_event && rec_enabled && !rec_control)begin if(rec_full)rec_overflow<=1;else rec_wp<=rec_wp+1'b1;end
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
    if(current_cmd==8'h13)effects<=cfg_value[4:0]; if(current_cmd==8'h18)expression_velocity<=cfg_value[7:0]; if(current_cmd==8'h19)expression_glide<=cfg_value[7:0]; if(current_cmd==8'h1a)expression_vibrato<=cfg_value[7:0];
   end else if(wait_ticks>=32'(APPLY_TIMEOUT-1))begin
    cfg_valid<=0;waiting<=0;response_valid<=1;response_seq<=current_seq;
    response_payload<={32'b0,8'd3,current_cmd};
    cache_valid<=1;last_seq<=current_seq;last_request<=current_request;
    last_response<={32'b0,8'd3,current_cmd};
   end else wait_ticks<=wait_ticks+1'b1;
  end
  if(checking_keys)begin
   key_commit_safe<=key_commit_safe && tables_safe && keymap_safe;
   if(key_seen[key_scan_note])key_reply(1);
   else if(key_scan_index==31)begin
    if(!key_commit_safe || !tables_safe || !keymap_safe)key_reply(3);
    else begin
     keys_active<=keys_stage;key_open<=0;keymap_revision<=keymap_revision+1'b1;
     keymap_committed<=1;key_reply(0);
    end
   end else begin key_seen[key_scan_note]<=1;key_scan_index<=key_scan_index+1'b1;end
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
    8'h06:if(packet_len==0 && PERFORMANCE_ENABLE!=0)reply(0,{8'd0,5'd0,performance_state,8'd1,6'd0,actual_performance});else reply(2,0);
    8'h05:if(packet_len==0)reply(0,{keymap_revision,8'd0,8'd32});else reply(1,0);
    8'h08:if(packet_len==0)reply(0,{8'd1,expression_vibrato,expression_glide,expression_velocity});else reply(1,0);
    8'h07:if(packet_len==0)begin
     if(!rec_empty)begin reply(0,{1'b1,rec_head});rec_rp<=rec_rp+1'b1;end
     else reply(0,{1'b0,rec_overflow,14'd0,rec_ms});
    end else reply(1,0);
    8'h17:if(packet_len==1 && p0<=1)begin
     rec_enabled<=p0[0];rec_rp<=rec_wp;rec_overflow<=0;
     if(p0[0])begin rec_ms<=0;rec_tick<=0;recording_restarted<=1;end
     reply(0,{31'd0,p0[0]});
    end else reply(1,0);
    8'h24:if(packet_len==1 && p0<32)reply(0,{keymap_revision,1'b0,keys_active[p0[4:0]*7+:7],p0});else reply(1,0);
    8'h10,8'h11,8'h12,8'h13,8'h14,8'h15,8'h16,8'h18,8'h19,8'h1a:begin
     if((packet_cmd==8'h10 && packet_len==1 && p0<=2) ||
        (packet_cmd==8'h11 && packet_len==1 && p0<=4) ||
        (packet_cmd==8'h12 && packet_len==2) ||
        (packet_cmd==8'h13 && packet_len==1 && p0<=31) ||
        (packet_cmd==8'h14 && packet_len==2 && value>=30 && value<=240) ||
        (packet_cmd==8'h15 && packet_len==1 && p0<=1) ||
        (packet_cmd==8'h16 && PERFORMANCE_ENABLE!=0 && packet_len==1 && p0<=2) || ((packet_cmd==8'h18 || packet_cmd==8'h19 || packet_cmd==8'h1a) && packet_len==1 && p0<=100))begin
      waiting<=1;wait_ticks<=0;cfg_valid<=1;cfg_cmd<=packet_cmd;cfg_value<=value;
      current_seq<=packet_seq;current_cmd<=packet_cmd;current_request<=request_bits;
     end else if(packet_cmd==8'h10 && packet_len==1 && p0<=2)reply(2,0);else reply(1,0);
    end
    8'h20:if(packet_len==0)begin key_open<=1;key_written<=0;reply(0,0);end else reply(1,0);
    8'h21:if(packet_len==2 && key_open && p0<32 && p1>=36 && p1<=96)begin
     keys_stage[p0[4:0]*7+:7]<=p1[6:0];key_written[p0[4:0]]<=1;reply(0,0);
    end else reply(1,0);
    8'h22:if(packet_len!=0 || !key_open || key_written!=32'hffffffff)reply(1,0);
     else begin
      checking_keys<=1;key_seen<=0;key_scan_index<=0;key_commit_safe<=tables_safe && keymap_safe;
      current_seq<=packet_seq;current_cmd<=packet_cmd;current_request<=request_bits;
     end
    8'h23:if(packet_len==0)begin key_open<=0;key_written<=0;reply(0,0);end else reply(1,0);
    8'h40:if(STREAM_ENABLE!=0 && packet_len==0)begin
     if(!tables_safe || !keymap_safe || score_playing || actual_performance==2)reply(3,0);
     else begin stream_begin<=1;reply(0,32'h53545231);end
    end else reply(2,0);
    8'h41:if(STREAM_ENABLE!=0 && packet_len==6 && p0>=36 && p0<=96 && p1<128)begin
     if(!stream_push_ready)reply(3,stream_status);
     else begin stream_data<=packet_payload;stream_push<=1;reply(0,0);end
    end else reply(1,0);
    8'h42:if(STREAM_ENABLE!=0 && packet_len==0)reply(0,stream_status);else reply(2,0);
    8'h43:if(STREAM_ENABLE!=0 && packet_len==0 && stream_loaded && !stream_fault)begin stream_seal<=1;reply(0,0);end else reply(3,0);
    8'h30:if(packet_len==1 && p0>0 && p0<=32)begin
     score_open<=1;stage_count<=p0[5:0];score_written<=0;reply(0,0);
    end else reply(1,0);
    8'h31:if(packet_len==5 && score_open && {1'b0,p0[4:0]}<stage_count && p0<32 &&
     p1<128 && packet_payload[23:16]<128 && packet_payload[39:24]!=0 &&
     (packet_payload[23:16]==0 || (p1>=36 && p1<=96)))begin
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
`default_nettype none
// Fixed 256 x 48-bit look-ahead queue. Times are absolute base-ms at 120 BPM.
// Note-on velocity>0; note-off velocity=0. No note-duration serialization.
module wifi_stream_player #(parameter integer SAMPLE_RATE=48000)(
 input wire clk,rst_n,sample_tick,begin_session,unload,push,seal,start,stop,abort_play,
 input wire [15:0] tempo,input wire [47:0] push_data,
 output wire push_ready,output reg loaded,output wire playing,output reg fault,
 output wire [31:0] status,
 output wire event_valid,input wire event_ready,output wire event_on,
 output wire [6:0] event_note,event_velocity
);
 localparam [1:0] IDLE=0,RUN=1,DRAIN=2;
 reg [1:0] state;
 reg [47:0] mem[0:255];
 reg [47:0] head;
 reg [8:0] wp,rp;
 wire [8:0] used=wp-rp;
 wire empty=wp==rp,full=used==9'd256;
 reg sealed,started,finished;
 reg [7:0] fault_code;
 reg [31:0] elapsed,phase,last_time;
 reg [1:0] head_wait;
 reg [127:0] active;
 reg [7:0] scan;
 wire [31:0] next_phase=phase+32'(tempo)*32'd1000;
 wire due=head[47:16]<=elapsed;
 wire [6:0] note=head[6:0];
 wire on=head[15:8]!=0;
 wire bad=head[7] || head[15] || note<36 || note>96 || (on?active[note]:!active[note]);
 assign playing=state!=IDLE;
 assign push_ready=loaded && !sealed && !fault && !full && !finished;
 assign event_valid=(state==RUN && !fault && !stop && !abort_play && !empty && head_wait==0 && due && !bad) ||
  (state==DRAIN && scan<128 && active[scan[6:0]] && !abort_play);
 assign event_on=state==RUN && on;
 assign event_note=state==DRAIN?scan[6:0]:note;
 assign event_velocity=event_on?head[14:8]:7'd0;
 assign status={fault_code,3'b0,finished,fault,sealed,playing,loaded,7'b0,used};
 // Synchronous read, no reset on RAM, so Gowin can infer memory resources.
 always @(posedge clk)begin
  if(push && push_ready)mem[wp[7:0]]<=push_data;
  head<=mem[rp[7:0]];
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  wp<=0;rp<=0;state<=IDLE;loaded<=0;sealed<=0;started<=0;finished<=0;fault<=0;fault_code<=0;
  elapsed<=0;phase<=0;last_time<=0;head_wait<=2;active<=0;scan<=0;
 end else if(begin_session || unload)begin
  wp<=0;rp<=0;state<=IDLE;loaded<=begin_session;sealed<=0;started<=0;finished<=0;fault<=0;fault_code<=0;
  elapsed<=0;phase<=0;last_time<=0;head_wait<=2;active<=0;scan<=0;
 end else begin
  if(head_wait!=0)head_wait<=head_wait-1'b1;
  if(seal && loaded)sealed<=1;
  if(push && push_ready)begin
   if(push_data[47:16]<last_time)begin fault<=1;fault_code<=2;if(state==RUN)begin state<=DRAIN;scan<=0;end end
   else begin wp<=wp+1'b1;last_time<=push_data[47:16];end
  end
  if(abort_play && state!=IDLE)begin
   // Mode/timbre transitions clear the synth engine itself; discard old timeline.
   state<=IDLE;active<=0;rp<=wp;finished<=1;head_wait<=2;
  end else if(push && push_ready && push_data[47:16]<last_time)begin
   fault<=1;fault_code<=2;if(state==RUN)begin state<=DRAIN;scan<=0;end
  end else if(stop && state==RUN)begin state<=DRAIN;scan<=0;end
  else case(state)
   IDLE:if(start && !stop && !abort_play && loaded && !started && !empty && !fault)begin
    state<=RUN;started<=1;elapsed<=0;phase<=0;head_wait<=2;
   end
   RUN:begin
    if(sample_tick)begin
     if(next_phase>=32'(SAMPLE_RATE*120))begin phase<=next_phase-32'(SAMPLE_RATE*120);elapsed<=elapsed+1'b1;end
     else phase<=next_phase;
    end
    if(empty)begin
     if(!sealed || |active)begin fault<=1;fault_code<=!sealed?8'd1:8'd3;state<=DRAIN;scan<=0;end
     else begin state<=IDLE;finished<=1;end
    end else if(head_wait==0 && due)begin
     if(bad)begin fault<=1;fault_code<=4;state<=DRAIN;scan<=0;end
     else if(event_ready)begin active[note]<=on;rp<=rp+1'b1;head_wait<=2;end
    end
   end
   DRAIN:begin
    if(scan==128)begin state<=IDLE;rp<=wp;finished<=1;head_wait<=2;end
    else if(!active[scan[6:0]] || event_ready)begin active[scan[6:0]]<=0;scan<=scan+1'b1;end
   end
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire

