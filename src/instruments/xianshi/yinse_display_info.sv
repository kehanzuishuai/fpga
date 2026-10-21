`default_nettype none
// ASCII metadata ONLY; feed the existing screen renderer, not a second TMDS path.
module yinse_display_info(input wire [2:0] current_id,input wire switching,
 output reg [127:0] name_ascii,output wire [2:0] display_id,output wire busy);
 assign display_id=current_id;assign busy=switching;
 always_comb case(current_id)
  0:name_ascii="PIANO           ";
  1:name_ascii="ORGAN           ";
  2:name_ascii="FLUTE           ";
  3:name_ascii="GUITAR          ";
  4:name_ascii="FM BELL         ";
  default:name_ascii="INVALID         ";
 endcase
endmodule
`default_nettype wire
