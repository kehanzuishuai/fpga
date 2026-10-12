module piano_envelope #(
    parameter ENV_W = 24
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 sample_tick,

    input  wire                 gate_on,
    input  wire                 gate_off,

    output reg  [ENV_W-1:0]     level,
    output reg                  active,
    output reg  [2:0]           stage
);


/* ============================================================
 * Piano envelope
 *
 * ST_ATTACK:
 *     very fast hammer/string build-up
 *
 * ST_FAST_DECAY:
 *     strong initial decay
 *
 * ST_SLOW_DECAY:
 *     natural piano decay while key is still held
 *
 * ST_TAIL:
 *     very slow long tail
 *
 * ST_RELEASE:
 *     damper comes down after key release
 * ============================================================ */

localparam ST_IDLE       = 3'd0;
localparam ST_ATTACK     = 3'd1;
localparam ST_FAST_DECAY = 3'd2;
localparam ST_SLOW_DECAY = 3'd3;
localparam ST_TAIL       = 3'd4;
localparam ST_RELEASE    = 3'd5;


/* 24-bit full scale */
localparam [ENV_W-1:0] MAX_LEVEL =
    {ENV_W{1'b1}};


/*
 * 48 kHz:
 *
 * about 96 samples
 * ≈ 2 ms attack
 *
 * 16777215 / 96
 * ≈ 174763
 */
localparam [ENV_W-1:0] ATTACK_STEP =
    24'd174763;


reg [6:0] attack_count;

reg [18:0] age_samples;


/* ============================================================
 * Decay amount
 *
 * Exponential-style decay:
 *
 * level -= level >> N
 *
 * No multiplier.
 * ============================================================ */

wire [ENV_W-1:0] fast_decay_a;
wire [ENV_W-1:0] fast_decay_b;
wire [ENV_W-1:0] fast_decay;

wire [ENV_W-1:0] slow_decay;
wire [ENV_W-1:0] tail_decay;

wire [ENV_W-1:0] release_decay_a;
wire [ENV_W-1:0] release_decay_b;
wire [ENV_W-1:0] release_decay;


assign fast_decay_a =
    level >> 14;

assign fast_decay_b =
    level >> 16;

assign fast_decay =
    fast_decay_a + fast_decay_b;


/*
 * ~2.7 second time constant
 */
assign slow_decay =
    level >> 17;


/*
 * Long tail
 */
assign tail_decay =
    level >> 19;


/*
 * Damper release:
 * much faster than natural decay
 */
assign release_decay_a =
    level >> 11;

assign release_decay_b =
    level >> 13;

assign release_decay =
    release_decay_a + release_decay_b;


/* ============================================================
 * Envelope FSM
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        level        <= {ENV_W{1'b0}};
        active       <= 1'b0;
        stage        <= ST_IDLE;

        attack_count <= 7'd0;
        age_samples  <= 19'd0;

    end

    else begin

        /* ----------------------------------------------------
         * New note always has highest priority
         * ---------------------------------------------------- */

        if (gate_on) begin

            level        <= {ENV_W{1'b0}};
            active       <= 1'b1;
            stage        <= ST_ATTACK;

            attack_count <= 7'd0;
            age_samples  <= 19'd0;

        end


        /* ----------------------------------------------------
         * Key released -> damper
         * ---------------------------------------------------- */

        else if (
            gate_off &&
            active
        ) begin

            stage <=
                ST_RELEASE;

        end


        else if (sample_tick) begin

            case (stage)


                /* ============================================
                 * Idle
                 * ============================================ */

                ST_IDLE: begin

                    level  <=
                        {ENV_W{1'b0}};

                    active <=
                        1'b0;

                end


                /* ============================================
                 * Attack
                 *
                 * ≈ 2 ms
                 * ============================================ */

                ST_ATTACK: begin

                    age_samples <=
                        age_samples + 1'b1;


                    if (
                        attack_count >=
                        7'd95
                    ) begin

                        level <=
                            MAX_LEVEL;

                        stage <=
                            ST_FAST_DECAY;

                    end

                    else begin

                        attack_count <=
                            attack_count + 1'b1;


                        if (
                            level >
                            (
                                MAX_LEVEL -
                                ATTACK_STEP
                            )
                        ) begin

                            level <=
                                MAX_LEVEL;

                        end

                        else begin

                            level <=
                                level +
                                ATTACK_STEP;

                        end

                    end

                end


                /* ============================================
                 * Fast initial decay
                 *
                 * roughly first 350 ms
                 * ============================================ */

                ST_FAST_DECAY: begin

                    age_samples <=
                        age_samples + 1'b1;


                    if (
                        fast_decay !=
                        {ENV_W{1'b0}}
                    ) begin

                        level <=
                            level -
                            fast_decay;

                    end

                    else begin

                        level <=
                            level - 1'b1;

                    end


                    if (
                        age_samples >=
                        19'd16800
                    ) begin

                        stage <=
                            ST_SLOW_DECAY;

                    end

                end


                /* ============================================
                 * Slow natural decay
                 *
                 * 0.35 s -> about 2.5 s
                 * ============================================ */

                ST_SLOW_DECAY: begin

                    age_samples <=
                        age_samples + 1'b1;


                    if (
                        slow_decay !=
                        {ENV_W{1'b0}}
                    ) begin

                        level <=
                            level -
                            slow_decay;

                    end

                    else begin

                        level <=
                            level - 1'b1;

                    end


                    if (
                        age_samples >=
                        19'd120000
                    ) begin

                        stage <=
                            ST_TAIL;

                    end

                end


                /* ============================================
                 * Long tail
                 * ============================================ */

                ST_TAIL: begin

                    if (
                        tail_decay !=
                        {ENV_W{1'b0}}
                    ) begin

                        level <=
                            level -
                            tail_decay;

                    end

                    else if (
                        level !=
                        {ENV_W{1'b0}}
                    ) begin

                        level <=
                            level - 1'b1;

                    end

                end


                /* ============================================
                 * Damper release
                 * ============================================ */

                ST_RELEASE: begin

                    if (
                        level <=
                        24'd512
                    ) begin

                        level <=
                            {ENV_W{1'b0}};

                        active <=
                            1'b0;

                        stage <=
                            ST_IDLE;

                    end

                    else if (
                        release_decay !=
                        {ENV_W{1'b0}}
                    ) begin

                        level <=
                            level -
                            release_decay;

                    end

                    else begin

                        level <=
                            level - 1'b1;

                    end

                end


                default: begin

                    level  <=
                        {ENV_W{1'b0}};

                    active <=
                        1'b0;

                    stage  <=
                        ST_IDLE;

                end

            endcase

        end

    end

end


endmodule