`default_nettype none
// Optional source-domain helper. Never drives the audio path. All inputs are
// synchronous to clk; upstream supplies already-mapped physical target masks.
module visual_guide_controller(
 input wire clk,rst_n,enable,start,stop,paused,tick_ms,
 input wire keys_valid,input wire [31:0] keys,
 input wire event_valid,input wire [31:0] event_keys,
 input wire [15:0] event_rest_ms,input wire event_last,
 output wire event_ready,output wire [31:0] target_keys,
 output wire [2:0] display_state,output reg [15:0] completed,
 output reg step_done,output wire finished
);
 localparam [2:0] IDLE=0,FETCH=1,WAIT_KEYS=2,RELEASE=3,DONE=5,REST=6;
 reg [2:0] state;
 reg [31:0] target;
 reg [15:0] rest_left,rest_length;
 reg last_event,armed;
 wire accepting=enable && !paused && !start && !stop && keys_valid;
 assign event_ready=accepting && state==FETCH && keys==0;
 assign target_keys=enable && !paused && keys_valid &&
  (state==WAIT_KEYS || state==RELEASE)?target:32'd0;
 assign display_state=!enable?IDLE:paused?3'd4:
  (!keys_valid && state!=IDLE && state!=DONE)?3'd7:state;
 assign finished=enable && state==DONE;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=IDLE;target<=0;completed<=0;rest_left<=0;rest_length<=0;
  last_event<=0;armed<=0;step_done<=0;
 end else begin
  step_done<=0;
  if(!enable || stop)begin state<=IDLE;target<=0;armed<=0;end
  else if(start)begin
   state<=FETCH;target<=0;completed<=0;armed<=0;last_event<=0;
  end else if(paused || !keys_valid)begin
   // Re-arm only after a fresh release, never accept a held stale key.
   armed<=0;
   if(state==REST)rest_left<=rest_length;
  end else case(state)
   FETCH:if(event_valid && event_ready)begin
    target<=event_keys;last_event<=event_last;armed<=1;
    rest_left<=event_rest_ms;rest_length<=event_rest_ms;
    state<=event_keys==0?REST:WAIT_KEYS;
   end
   WAIT_KEYS:begin
    if(keys==0)armed<=1;
    if(armed && keys==target)begin
     state<=RELEASE;step_done<=1;
     if(completed!=16'hffff)completed<=completed+16'd1;
    end
   end
   RELEASE:if(keys==0)begin
    target<=0;armed<=0;state<=last_event?DONE:FETCH;
   end
   REST:begin
    if(keys!=0)rest_left<=rest_length;
    else if(rest_left==0 || (tick_ms && rest_left==1))begin
     step_done<=1;state<=last_event?DONE:FETCH;
     if(completed!=16'hffff)completed<=completed+16'd1;
    end else if(tick_ms)rest_left<=rest_left-16'd1;
   end
   default:begin end
  endcase
 end
endmodule
`default_nettype wire
