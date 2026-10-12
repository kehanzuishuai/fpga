

module dds_phase_accum #(
    parameter PHASE_W = 32
)(
    input                      clk,
    input                      rst_n,
    input                      sample_tick,
    input                      phase_reset,
    input      [PHASE_W-1:0]   phase_inc,
    output reg [PHASE_W-1:0]   phase
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        phase <= {PHASE_W{1'b0}};
    else if (phase_reset)
        phase <= {PHASE_W{1'b0}};
    else if (sample_tick)
        phase <= phase + phase_inc;
end

endmodule

