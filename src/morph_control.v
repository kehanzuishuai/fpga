
module morph_control #(
    parameter STEP = 10'd4
)(
    input             clk,
    input             rst_n,
    input             sample_tick,
    input             enable_target,
    input      [9:0]  morph_target,
    output reg        morph_enable,
    output reg [9:0]  morph_value
);

reg [9:0] diff;

always @(*) begin
    if (morph_value >= morph_target)
        diff = morph_value - morph_target;
    else
        diff = morph_target - morph_value;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        morph_enable <= 1'b0;
        morph_value  <= 10'd0;
    end
    else if (sample_tick) begin
        morph_enable <= enable_target;

        if (morph_value < morph_target) begin
            if (diff <= STEP)
                morph_value <= morph_target;
            else
                morph_value <= morph_value + STEP;
        end
        else if (morph_value > morph_target) begin
            if (diff <= STEP)
                morph_value <= morph_target;
            else
                morph_value <= morph_value - STEP;
        end
    end
end

endmodule


