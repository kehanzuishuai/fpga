
module adsr_env #(
    parameter ENV_W = 24,
    parameter [ENV_W-1:0] ATTACK_STEP  = 24'd349525,
    parameter [ENV_W-1:0] DECAY_STEP   = 24'd17476,
    parameter [ENV_W-1:0] SUSTAIN      = 24'd12582912,
    parameter [ENV_W-1:0] RELEASE_STEP = 24'd8738
)(
    input                   clk,
    input                   rst_n,
    input                   sample_tick,
    input                   gate_on,
    input                   gate_off,

    output reg [ENV_W-1:0]  level,
    output reg              active,
    output reg [1:0]        stage
);

localparam [1:0] OFF           = 2'd0;
localparam [1:0] ATTACK        = 2'd1;
localparam [1:0] DECAY         = 2'd2;
localparam [1:0] SUSTAIN_STAGE = 2'd3;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        level  <= {ENV_W{1'b0}};
        stage  <= OFF;
        active <= 1'b0;
    end

    else if (gate_on) begin
        level  <= {ENV_W{1'b0}};
        stage  <= ATTACK;
        active <= 1'b1;
    end

    else if (gate_off && active) begin
        stage <= OFF;
    end

    else if (sample_tick) begin

        case (stage)

            ATTACK: begin
                if (level >= ({ENV_W{1'b1}} - ATTACK_STEP)) begin
                    level <= {ENV_W{1'b1}};
                    stage <= DECAY;
                end
                else
                    level <= level + ATTACK_STEP;
            end

            DECAY: begin
                if (level <= (SUSTAIN + DECAY_STEP)) begin
                    level <= SUSTAIN;
                    stage <= SUSTAIN_STAGE;
                end
                else
                    level <= level - DECAY_STEP;
            end

            SUSTAIN_STAGE: begin
                level <= SUSTAIN;
            end

            default: begin
                if (active) begin
                    if (level <= RELEASE_STEP) begin
                        level  <= {ENV_W{1'b0}};
                        active <= 1'b0;
                    end
                    else
                        level <= level - RELEASE_STEP;
                end
            end

        endcase
    end
end

endmodule
