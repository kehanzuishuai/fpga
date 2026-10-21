`default_nettype none
module yinse_envelope(input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [15:0] attack_step,decay_step,sustain_level,release_step,
 output reg [15:0] level,output wire active);
 localparam [2:0] OFF=0,ATTACK=1,DECAY=2,SUSTAIN=3,RELEASE=4;
 reg [2:0] state;
 wire [16:0] attack_sum={1'b0,level}+{1'b0,attack_step};
 wire [16:0] decay_floor={1'b0,sustain_level}+{1'b0,decay_step};
 assign active=state!=OFF;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin state<=OFF;level<=0;end
 else if(clear)begin state<=OFF;level<=0;end
 else if(start)begin state<=ATTACK;level<=0;end
 else if(stop && state!=OFF)state<=RELEASE;
 else if(sample_tick)case(state)
  ATTACK:if(attack_sum>=65535)begin level<=65535;state<=DECAY;end else level<=attack_sum[15:0];
  DECAY:if({1'b0,level}<=decay_floor)begin level<=sustain_level;state<=(sustain_level==0)?OFF:SUSTAIN;end
   else level<=level-decay_step;
  SUSTAIN:level<=sustain_level;
  RELEASE:if(level<=release_step)begin level<=0;state<=OFF;end else level<=level-release_step;
  default:begin state<=OFF;level<=0;end
 endcase
endmodule
`default_nettype wire
