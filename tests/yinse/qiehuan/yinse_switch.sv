`default_nettype none
// Same AUDIO clock as the note loader. requested_id and keys_down must be coherent
// in this domain. Never reset the audio PLL or DAC to switch instruments.
module yinse_switch #(parameter integer FADE_SAMPLES=240,parameter integer KEYS=16)(
 input wire clk,rst_n,sample_tick,input wire [2:0] requested_id,
 input wire [KEYS-1:0] keys_down,input wire loader_busy,
 output reg [2:0] current_id,output reg [15:0] gain,
 output wire block_events,output reg flush_events,clear_aux,committed,
 output wire switching
);
 localparam [1:0] RUN=0,FADE_OUT=1,BARRIER=2,FADE_IN=3;
 localparam integer STEP=(65535+FADE_SAMPLES-1)/FADE_SAMPLES;
 reg [1:0] state;
 wire valid_request=requested_id<=4;
 assign switching=state!=RUN;
 // Fresh notes may start on the committed instrument during fade-in. Keeping
 // them blocked would lose a held key's only NoteOn edge. The clear/flush pulse
 // still wins for one clock, preventing an acknowledged event being cleared.
 assign block_events=(state!=RUN && state!=FADE_IN) || clear_aux || flush_events ||
                     (valid_request && requested_id!=current_id);
 initial if(FADE_SAMPLES<1 || FADE_SAMPLES>65535 || KEYS<1)$fatal(1,"switch parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin state<=RUN;current_id<=0;gain<=65535;flush_events<=0;clear_aux<=0;committed<=0;end
 else begin
  flush_events<=0;clear_aux<=0;committed<=0;
  if(sample_tick)case(state)
   RUN:if(valid_request && requested_id!=current_id)begin state<=FADE_OUT;flush_events<=1;end
   FADE_OUT:if(gain<=16'(STEP))begin gain<=0;state<=BARRIER;end else gain<=gain-16'(STEP);
   BARRIER:if(!loader_busy && keys_down==0 && valid_request)begin
    current_id<=requested_id;clear_aux<=1;flush_events<=1;committed<=1;state<=FADE_IN;
   end
   FADE_IN:if(requested_id!=current_id && valid_request)begin state<=FADE_OUT;flush_events<=1;end
    else if(gain>=16'(65535-STEP))begin gain<=65535;state<=RUN;end else gain<=gain+16'(STEP);
   default:begin state<=RUN;gain<=65535;current_id<=0;end
  endcase
 end
endmodule
`default_nettype wire
