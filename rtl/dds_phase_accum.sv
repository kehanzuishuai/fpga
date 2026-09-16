`default_nettype none
module dds_phase_accum #(
  parameter int PHASE_W = 32
) (
  input logic clk, input logic rst_n, input logic sample_tick,
  input logic phase_reset, input logic [PHASE_W-1:0] phase_inc,
  output logic [PHASE_W-1:0] phase
);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) phase <= '0;
    else if (phase_reset) phase <= '0;
    else if (sample_tick) phase <= phase + phase_inc;
endmodule
`default_nettype wire
