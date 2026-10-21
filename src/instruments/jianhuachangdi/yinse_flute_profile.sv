`default_nettype none
// Approximation, not a physical flute bore model. Fundamental + two partials.
module yinse_flute_profile(input wire [3:0] slot,input wire [31:0] phase,increment,
 output reg [31:0] harmonic_phase,output reg [7:0] weight);
 reg [33:0] wide_inc;
 always_comb begin
  harmonic_phase=phase;weight=0;wide_inc={2'd0,increment};
  case(slot)
   0:weight=240;
   1:begin harmonic_phase=phase<<1;wide_inc={2'd0,increment}<<1;weight=20;end
   2:begin harmonic_phase=phase+(phase<<1);wide_inc={2'd0,increment}+({2'd0,increment}<<1);weight=8;end
   default:weight=0;
  endcase
  if(wide_inc>=34'h080000000)weight=0;
 end
endmodule
`default_nettype wire
