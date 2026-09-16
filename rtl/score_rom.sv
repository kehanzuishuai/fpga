`default_nettype none
// Small synthesizable default score. Replace the case table or generate this
// module from a score compiler for a longer tune; no vendor memory IP is used.
module score_rom #(
  parameter int ADDR_W=5
) (
  input logic [ADDR_W-1:0] address,
  output logic [6:0] note, output logic [15:0] duration_ms, output logic valid
);
  always @* begin
    valid=1; duration_ms=16'd300;
    case(address)
      0:note=60; 1:note=62; 2:note=64; 3:note=65; 4:note=67; 5:note=69; 6:note=71; 7:note=72;
      8:note=71; 9:note=69; 10:note=67; 11:note=65; 12:note=64; 13:note=62; 14:note=60;
      default: begin note=0; duration_ms=0; valid=0; end
    endcase
  end
endmodule
`default_nettype wire
