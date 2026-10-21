`default_nettype none
// Single melody, durations in base milliseconds at 120 BPM. Tempo changes the
// timebase only, never note pitch. Every NoteOff survives output backpressure.
module wifi_score_player #(parameter integer SAMPLE_RATE=48000)(
 input wire clk,rst_n,sample_tick,start,stop,abort_play,
 input wire [15:0] tempo,input wire [5:0] score_count,
 output reg [4:0] score_index,input wire [31:0] score_event,
 output wire playing,output wire tables_safe,
 output wire event_valid,input wire event_ready,output wire event_on,
 output wire [6:0] event_note,event_velocity
);
 localparam [2:0] IDLE=0,LOAD=1,ON_WAIT=2,RUN=3,OFF_WAIT=4;
 localparam [31:0] BASE=32'(SAMPLE_RATE*120);
 reg [2:0] state;reg [6:0] note,velocity;reg [15:0] remaining;
 reg [31:0] phase;reg sounding,stopping;
 wire [1:0] unused_padding={score_event[15],score_event[7]};
 wire [31:0] advance=phase+32'(tempo)*32'd1000;
 wire ms_tick=advance>=BASE;
 assign playing=state!=IDLE;
 assign tables_safe=state==IDLE;
 assign event_valid=(state==ON_WAIT && !stop && !abort_play) || state==OFF_WAIT;
 assign event_on=state==ON_WAIT;
 assign event_note=note;assign event_velocity=state==ON_WAIT?velocity:7'd0;
 task automatic advance_note;
 begin
  if(stopping || {1'b0,score_index}+6'd1>=score_count)begin state<=IDLE;score_index<=0;end
  else begin score_index<=score_index+1'b1;state<=LOAD;end
 end endtask
 initial if(SAMPLE_RATE<2000 || SAMPLE_RATE>192000)$fatal(1,"sample rate");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin state<=IDLE;score_index<=0;note<=0;velocity<=0;remaining<=0;phase<=0;sounding<=0;stopping<=0;end
 else begin
  if(state==IDLE)begin
   stopping<=0;phase<=0;
   if(start && !stop && !abort_play && score_count!=0)begin score_index<=0;state<=LOAD;end
  end else if(stop || abort_play)begin
   stopping<=1;
   if(state==OFF_WAIT && event_ready)begin sounding<=0;state<=IDLE;score_index<=0;end
   else if(sounding || state==OFF_WAIT)state<=OFF_WAIT;
   else begin state<=IDLE;score_index<=0;end
  end else case(state)
   LOAD:begin
    note<=score_event[6:0];velocity<=score_event[14:8];remaining<=score_event[31:16];phase<=0;
    if(score_event[14:8]==0)state<=RUN;else state<=ON_WAIT;
   end
   ON_WAIT:if(event_ready)begin sounding<=1;state<=RUN;end
   RUN:if(sample_tick)begin
    phase<=ms_tick?advance-BASE:advance;
    if(ms_tick)begin
     if(remaining<=1)begin if(sounding)state<=OFF_WAIT;else advance_note;end
     else remaining<=remaining-1'b1;
    end
   end
   OFF_WAIT:if(event_ready)begin sounding<=0;advance_note;end
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire
