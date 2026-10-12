
module score_rom #(
    parameter ADDR_W     = 5,
    parameter DURATION_W = 24
)(
    input      [ADDR_W-1:0]      address,

    output reg [6:0]             note,
    output reg [DURATION_W-1:0]  duration_ticks,
    output reg [7:0]             velocity,
    output reg                   rest,
    output reg                   valid
);


/* ============================================================
 * Score ROM
 *
 * duration_ticks 的单位：
 * sample_tick 周期
 *
 * 例如采样率 48 kHz：
 *
 * 12000 / 48000 = 0.25 s
 * 24000 / 48000 = 0.50 s
 *  6000 / 48000 = 0.125 s
 * ============================================================ */

always @(*) begin

    /*
     * Default values
     */
    note           = 7'd0;
    duration_ticks = {DURATION_W{1'b0}};
    velocity       = 8'd0;
    rest           = 1'b0;
    valid          = 1'b1;


    case (address)

        5'd0: begin
            note           = 7'd60;
            duration_ticks = 24'd12000;
            velocity       = 8'd104;
        end

        5'd1: begin
            note           = 7'd62;
            duration_ticks = 24'd12000;
            velocity       = 8'd108;
        end

        5'd2: begin
            note           = 7'd64;
            duration_ticks = 24'd12000;
            velocity       = 8'd112;
        end

        5'd3: begin
            note           = 7'd65;
            duration_ticks = 24'd12000;
            velocity       = 8'd116;
        end

        5'd4: begin
            rest           = 1'b1;
            duration_ticks = 24'd6000;
            velocity       = 8'd0;
        end

        5'd5: begin
            note           = 7'd67;
            duration_ticks = 24'd24000;
            velocity       = 8'd120;
        end

        5'd6: begin
            note           = 7'd69;
            duration_ticks = 24'd12000;
            velocity       = 8'd112;
        end

        5'd7: begin
            note           = 7'd71;
            duration_ticks = 24'd12000;
            velocity       = 8'd108;
        end

        5'd8: begin
            note           = 7'd72;
            duration_ticks = 24'd24000;
            velocity       = 8'd120;
        end

        5'd9: begin
            note           = 7'd67;
            duration_ticks = 24'd12000;
            velocity       = 8'd108;
        end

        5'd10: begin
            note           = 7'd64;
            duration_ticks = 24'd12000;
            velocity       = 8'd104;
        end

        5'd11: begin
            note           = 7'd60;
            duration_ticks = 24'd24000;
            velocity       = 8'd100;
        end


        /*
         * End of score
         */
        default: begin

            note           = 7'd0;
            duration_ticks = {DURATION_W{1'b0}};
            velocity       = 8'd0;

            rest           = 1'b0;
            valid          = 1'b0;

        end

    endcase

end


endmodule