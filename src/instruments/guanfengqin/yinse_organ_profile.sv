`default_nettype none
// Conventional drawbar ratios 1/2,3/2,1,2,3,4,5,6,8. Fresh fixed preset.
module yinse_organ_profile(input wire [3:0] slot,input wire [32:0] phase,input wire [31:0] increment,
 output reg [31:0] harmonic_phase,output reg [7:0] weight);
 reg [35:0] wide_inc;
 wire [35:0] inc_w={4'd0,increment};
 wire [35:0] inc3=inc_w+(inc_w<<1);
 always_comb begin
  harmonic_phase=phase[31:0];weight=0;wide_inc={4'd0,increment};
  case(slot)
   0:begin harmonic_phase=phase[32:1];wide_inc={4'd0,increment}>>1;weight=100;end
   1:begin harmonic_phase=phase[31:0]+phase[32:1];wide_inc=inc3>>1;weight=35;end
   2:begin weight=200;end
   3:begin harmonic_phase=phase[31:0]<<1;wide_inc={4'd0,increment}<<1;weight=100;end
   4:begin harmonic_phase=phase[31:0]+(phase[31:0]<<1);wide_inc=inc3;weight=60;end
   5:begin harmonic_phase=phase[31:0]<<2;wide_inc={4'd0,increment}<<2;weight=35;end
   6:begin harmonic_phase=phase[31:0]+(phase[31:0]<<2);wide_inc=inc_w+(inc_w<<2);weight=20;end
   7:begin harmonic_phase=(phase[31:0]<<1)+(phase[31:0]<<2);wide_inc=inc3<<1;weight=15;end
   8:begin harmonic_phase=phase[31:0]<<3;wide_inc={4'd0,increment}<<3;weight=10;end
   default:begin weight=0;end
  endcase
  if(wide_inc>=36'h080000000)weight=0; // suppress partials at/above Nyquist
 end
endmodule
`default_nettype wire
