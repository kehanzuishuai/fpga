module voice_allocator #(
    parameter VOICES   = 32,
    parameter AGE_W    = 32,
    parameter ENV_W    = 24,
    parameter INDEX_W  = 5
)(
    input                           request_valid,

    input      [VOICES-1:0]         active,
    input      [VOICES-1:0]         releasing,

    input      [VOICES*AGE_W-1:0]   ages,
    input      [VOICES*ENV_W-1:0]   env_levels,

    output reg                      grant_valid,
    output reg [INDEX_W-1:0]        grant_index,

    output reg                      steal,
    output reg [INDEX_W-1:0]        note_off_index
);


/* ============================================================
 * IMPORTANT
 *
 * This implementation is optimized for 32 voices.
 *
 * Instead of a 32-stage serial comparison chain:
 *
 *     32 -> 31 -> 30 -> ... -> 1
 *
 * we use a balanced reduction tree:
 *
 *     32 -> 16 -> 8 -> 4 -> 2 -> 1
 *
 * This dramatically reduces combinational path depth.
 * ============================================================ */


/* ============================================================
 * Candidate format
 *
 * [ valid | env_level | age | index ]
 * ============================================================ */

localparam CAND_W =
    1 + ENV_W + AGE_W + INDEX_W;

localparam CAND_VALID_BIT =
    CAND_W - 1;

localparam CAND_ENV_LSB =
    INDEX_W + AGE_W;

localparam CAND_AGE_LSB =
    INDEX_W;


/* ============================================================
 * Free candidate format
 *
 * [ valid | index ]
 * ============================================================ */

localparam FREE_W =
    1 + INDEX_W;

localparam FREE_VALID_BIT =
    FREE_W - 1;


/* ============================================================
 * Select better voice candidate
 *
 * Priority:
 *
 * 1. valid candidate
 * 2. quieter envelope
 * 3. older age
 * 4. lower index
 * ============================================================ */

function [CAND_W-1:0] pick_voice;

    input [CAND_W-1:0] a;
    input [CAND_W-1:0] b;

    begin

        if (!a[CAND_VALID_BIT] &&
            !b[CAND_VALID_BIT]) begin

            pick_voice = a;

        end
        else if (a[CAND_VALID_BIT] &&
                !b[CAND_VALID_BIT]) begin

            pick_voice = a;

        end
        else if (!a[CAND_VALID_BIT] &&
                  b[CAND_VALID_BIT]) begin

            pick_voice = b;

        end

        /*
         * Lower envelope level wins.
         */
        else if (
            a[CAND_ENV_LSB +: ENV_W] <
            b[CAND_ENV_LSB +: ENV_W]
        ) begin

            pick_voice = a;

        end
        else if (
            b[CAND_ENV_LSB +: ENV_W] <
            a[CAND_ENV_LSB +: ENV_W]
        ) begin

            pick_voice = b;

        end

        /*
         * Same envelope:
         * smaller age counter means older.
         */
        else if (
            a[CAND_AGE_LSB +: AGE_W] <
            b[CAND_AGE_LSB +: AGE_W]
        ) begin

            pick_voice = a;

        end
        else if (
            b[CAND_AGE_LSB +: AGE_W] <
            a[CAND_AGE_LSB +: AGE_W]
        ) begin

            pick_voice = b;

        end

        /*
         * Fully equal:
         * lower voice index wins.
         */
        else if (
            a[INDEX_W-1:0] <=
            b[INDEX_W-1:0]
        ) begin

            pick_voice = a;

        end
        else begin

            pick_voice = b;

        end

    end

endfunction


/* ============================================================
 * Select first free voice.
 *
 * Tree inputs are ordered from low index to high index.
 * Therefore whenever left candidate is valid,
 * the left candidate always has higher priority.
 * ============================================================ */

function [FREE_W-1:0] pick_free;

    input [FREE_W-1:0] a;
    input [FREE_W-1:0] b;

    begin

        if (a[FREE_VALID_BIT])
            pick_free = a;
        else
            pick_free = b;

    end

endfunction


/* ============================================================
 * Level 0
 * 32 candidates
 * ============================================================ */

wire [32*FREE_W-1:0] free_l0;
wire [32*CAND_W-1:0] release_l0;
wire [32*CAND_W-1:0] active_l0;


genvar g;

generate

    for (g = 0; g < 32; g = g + 1) begin : GEN_INPUT

        localparam [INDEX_W-1:0] G_INDEX = g;

        assign free_l0[g*FREE_W +: FREE_W] =
        {
            !active[g],
            G_INDEX
        };


        assign release_l0[g*CAND_W +: CAND_W] =
        {
            active[g] && releasing[g],

            env_levels[
                g*ENV_W +: ENV_W
            ],

            ages[
                g*AGE_W +: AGE_W
            ],

            G_INDEX
        };


        assign active_l0[g*CAND_W +: CAND_W] =
        {
            active[g],

            env_levels[
                g*ENV_W +: ENV_W
            ],

            ages[
                g*AGE_W +: AGE_W
            ],

            G_INDEX
        };

    end

endgenerate


/* ============================================================
 * Level 1
 *
 * 32 -> 16
 * ============================================================ */

wire [16*FREE_W-1:0] free_l1;
wire [16*CAND_W-1:0] release_l1;
wire [16*CAND_W-1:0] active_l1;


genvar l1;

generate

    for (l1 = 0; l1 < 16; l1 = l1 + 1) begin : GEN_L1

        assign free_l1[l1*FREE_W +: FREE_W] =
            pick_free(
                free_l0[(2*l1)*FREE_W +: FREE_W],
                free_l0[(2*l1+1)*FREE_W +: FREE_W]
            );


        assign release_l1[l1*CAND_W +: CAND_W] =
            pick_voice(
                release_l0[(2*l1)*CAND_W +: CAND_W],
                release_l0[(2*l1+1)*CAND_W +: CAND_W]
            );


        assign active_l1[l1*CAND_W +: CAND_W] =
            pick_voice(
                active_l0[(2*l1)*CAND_W +: CAND_W],
                active_l0[(2*l1+1)*CAND_W +: CAND_W]
            );

    end

endgenerate


/* ============================================================
 * Level 2
 *
 * 16 -> 8
 * ============================================================ */

wire [8*FREE_W-1:0] free_l2;
wire [8*CAND_W-1:0] release_l2;
wire [8*CAND_W-1:0] active_l2;


genvar l2;

generate

    for (l2 = 0; l2 < 8; l2 = l2 + 1) begin : GEN_L2

        assign free_l2[l2*FREE_W +: FREE_W] =
            pick_free(
                free_l1[(2*l2)*FREE_W +: FREE_W],
                free_l1[(2*l2+1)*FREE_W +: FREE_W]
            );


        assign release_l2[l2*CAND_W +: CAND_W] =
            pick_voice(
                release_l1[(2*l2)*CAND_W +: CAND_W],
                release_l1[(2*l2+1)*CAND_W +: CAND_W]
            );


        assign active_l2[l2*CAND_W +: CAND_W] =
            pick_voice(
                active_l1[(2*l2)*CAND_W +: CAND_W],
                active_l1[(2*l2+1)*CAND_W +: CAND_W]
            );

    end

endgenerate


/* ============================================================
 * Level 3
 *
 * 8 -> 4
 * ============================================================ */

wire [4*FREE_W-1:0] free_l3;
wire [4*CAND_W-1:0] release_l3;
wire [4*CAND_W-1:0] active_l3;


genvar l3;

generate

    for (l3 = 0; l3 < 4; l3 = l3 + 1) begin : GEN_L3

        assign free_l3[l3*FREE_W +: FREE_W] =
            pick_free(
                free_l2[(2*l3)*FREE_W +: FREE_W],
                free_l2[(2*l3+1)*FREE_W +: FREE_W]
            );


        assign release_l3[l3*CAND_W +: CAND_W] =
            pick_voice(
                release_l2[(2*l3)*CAND_W +: CAND_W],
                release_l2[(2*l3+1)*CAND_W +: CAND_W]
            );


        assign active_l3[l3*CAND_W +: CAND_W] =
            pick_voice(
                active_l2[(2*l3)*CAND_W +: CAND_W],
                active_l2[(2*l3+1)*CAND_W +: CAND_W]
            );

    end

endgenerate


/* ============================================================
 * Level 4
 *
 * 4 -> 2
 * ============================================================ */

wire [2*FREE_W-1:0] free_l4;
wire [2*CAND_W-1:0] release_l4;
wire [2*CAND_W-1:0] active_l4;


genvar l4;

generate

    for (l4 = 0; l4 < 2; l4 = l4 + 1) begin : GEN_L4

        assign free_l4[l4*FREE_W +: FREE_W] =
            pick_free(
                free_l3[(2*l4)*FREE_W +: FREE_W],
                free_l3[(2*l4+1)*FREE_W +: FREE_W]
            );


        assign release_l4[l4*CAND_W +: CAND_W] =
            pick_voice(
                release_l3[(2*l4)*CAND_W +: CAND_W],
                release_l3[(2*l4+1)*CAND_W +: CAND_W]
            );


        assign active_l4[l4*CAND_W +: CAND_W] =
            pick_voice(
                active_l3[(2*l4)*CAND_W +: CAND_W],
                active_l3[(2*l4+1)*CAND_W +: CAND_W]
            );

    end

endgenerate


/* ============================================================
 * Level 5
 *
 * 2 -> 1
 * ============================================================ */

wire [FREE_W-1:0] free_final;
wire [CAND_W-1:0] release_final;
wire [CAND_W-1:0] active_final;


assign free_final =
    pick_free(
        free_l4[0*FREE_W +: FREE_W],
        free_l4[1*FREE_W +: FREE_W]
    );


assign release_final =
    pick_voice(
        release_l4[0*CAND_W +: CAND_W],
        release_l4[1*CAND_W +: CAND_W]
    );


assign active_final =
    pick_voice(
        active_l4[0*CAND_W +: CAND_W],
        active_l4[1*CAND_W +: CAND_W]
    );


/* ============================================================
 * Final selection
 * ============================================================ */

wire free_valid;
wire release_valid;
wire active_valid;

wire [INDEX_W-1:0] free_index;
wire [INDEX_W-1:0] release_index;
wire [INDEX_W-1:0] active_index;


assign free_valid =
    free_final[FREE_VALID_BIT];

assign free_index =
    free_final[INDEX_W-1:0];


assign release_valid =
    release_final[CAND_VALID_BIT];

assign release_index =
    release_final[INDEX_W-1:0];


assign active_valid =
    active_final[CAND_VALID_BIT];

assign active_index =
    active_final[INDEX_W-1:0];


always @(*) begin

    grant_valid    = 1'b0;
    grant_index    = {INDEX_W{1'b0}};

    steal          = 1'b0;

    note_off_index =
        {INDEX_W{1'b0}};


    if (request_valid) begin

        /*
         * Priority 1:
         * free voice
         */
        if (free_valid) begin

            grant_valid = 1'b1;
            grant_index = free_index;

            steal = 1'b0;

        end

        /*
         * Priority 2:
         * quietest releasing voice
         */
        else if (release_valid) begin

            grant_valid = 1'b1;
            grant_index = release_index;

            steal = 1'b1;

        end

        /*
         * Priority 3:
         * quietest active voice
         */
        else if (active_valid) begin

            grant_valid = 1'b1;
            grant_index = active_index;

            steal = 1'b1;

        end

    end

end


endmodule
