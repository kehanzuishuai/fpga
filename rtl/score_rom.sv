`default_nettype none
// Portable event ROM.  duration_ticks is measured in sample_tick periods;
// rest events consume time without ever bypassing the real-time synth chain.
module score_rom #(
  parameter int ADDR_W=5,parameter int DURATION_W=24
) (
  input logic [ADDR_W-1:0] address,
  output logic [6:0] note,output logic [DURATION_W-1:0] duration_ticks,
  output logic [7:0] velocity,output logic rest,output logic valid
);
  always @* begin
    note=0;duration_ticks=0;velocity=0;rest=0;valid=1;
    case(address)
      0:begin note=60;duration_ticks=12000;velocity=104;end
      1:begin note=62;duration_ticks=12000;velocity=108;end
      2:begin note=64;duration_ticks=12000;velocity=112;end
      3:begin note=65;duration_ticks=12000;velocity=116;end
      4:begin rest=1;duration_ticks=6000;velocity=0;end
      5:begin note=67;duration_ticks=24000;velocity=120;end
      6:begin note=69;duration_ticks=12000;velocity=112;end
      7:begin note=71;duration_ticks=12000;velocity=108;end
      8:begin note=72;duration_ticks=24000;velocity=120;end
      9:begin note=67;duration_ticks=12000;velocity=108;end
      10:begin note=64;duration_ticks=12000;velocity=104;end
      11:begin note=60;duration_ticks=24000;velocity=100;end
      default:begin note=0;duration_ticks=0;velocity=0;rest=0;valid=0;end
    endcase
  end
endmodule
`default_nettype wire
