`default_nettype none
// IDs: 0 original piano, 1 organ, 2 simplified flute, 3 KS guitar, 4 FM bell.
// Rates are Q0.16 increments per 48 kHz sample, not exact duration promises.
module yinse_preset(input wire [2:0] instrument_id,
 output reg [15:0] attack_step,decay_step,sustain_level,release_step,
 output reg [4:0] fx_ctrl,output reg valid);
 always_comb begin
  valid=1;attack_step=683;decay_step=1;sustain_level=65535;release_step=92;fx_ctrl=5'b10010;
  case(instrument_id)
   0:begin fx_ctrl=5'b10011;end // Existing piano owns its own envelope.
   1:begin attack_step=683;decay_step=1;sustain_level=65535;release_step=92;end
   2:begin attack_step=23;decay_step=6;sustain_level=49152;release_step=12;end
   3:begin attack_step=1366;decay_step=1;sustain_level=65535;release_step=69;end
   4:begin attack_step=1366;decay_step=1;sustain_level=0;release_step=23;end
   default:begin valid=0;fx_ctrl=0;end
  endcase
 end
endmodule
`default_nettype wire
