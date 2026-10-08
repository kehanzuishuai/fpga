module voice_bank #(
    parameter VOICES      = 32,
    parameter SAMPLE_W    = 24,
    parameter AGE_W       = 32,
    parameter SAMPLE_RATE = 48000,
    parameter IDX_W       = 5
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,

    input                              note_on,
    input                              note_off,
    input                              all_notes_off,

    input      [6:0]                   midi_note,
    input      [7:0]                   velocity,
    input      [1:0]                   waveform,

    /* Continuous-control plane */
    input                              morph_enable,
    input      [9:0]                   morph,

    output     [VOICES*SAMPLE_W-1:0]   voice_samples,
    output     [VOICES-1:0]            voice_active,

    output reg                         allocation_valid,
    output reg [IDX_W-1:0]             allocation_index
);


/* ============================================================
 * Basic signals
 * ============================================================ */

wire [31:0] phase_inc;

reg  [VOICES*AGE_W-1:0] ages;

wire [VOICES*7-1:0] notes;

reg  [VOICES-1:0] starts;
reg  [VOICES-1:0] stops;

wire [VOICES-1:0] voice_releasing;

wire [VOICES*SAMPLE_W-1:0]
    voice_env_levels;


/* ============================================================
 * Voice allocator
 * ============================================================ */

wire [IDX_W-1:0] chosen;
wire             grant;

wire             unused_steal;

wire [IDX_W-1:0]
    unused_note_off_index;


/* ============================================================
 * Voice age counter
 *
 * Smaller stored age value = older Voice.
 *
 * Example:
 *
 * Voice A started when counter = 3
 * Voice B started when counter = 9
 *
 * A is older than B.
 * ============================================================ */

reg [AGE_W-1:0] age_counter;


/* ============================================================
 * MIDI note -> DDS phase increment
 * ============================================================ */

note_freq_table #(
    .SAMPLE_RATE(SAMPLE_RATE)
) u_note_freq_table (
    .midi_note (midi_note),
    .phase_inc (phase_inc)
);


/* ============================================================
 * Voice allocation
 *
 * IMPORTANT:
 *
 * voice_allocator should use the new balanced-tree version.
 * ============================================================ */

voice_allocator #(
    .VOICES  (VOICES),
    .AGE_W   (AGE_W),
    .ENV_W   (SAMPLE_W),
    .INDEX_W (IDX_W)
) u_voice_allocator (

    .request_valid  (note_on),

    .active         (voice_active),
    .releasing      (voice_releasing),

    .ages           (ages),
    .env_levels     (voice_env_levels),

    .grant_valid    (grant),
    .grant_index    (chosen),

    .steal          (unused_steal),

    .note_off_index (
        unused_note_off_index
    )
);


/* ============================================================
 * Allocation debug output
 * ============================================================ */

always @(*) begin

    allocation_valid =
        note_on && grant;

    allocation_index =
        chosen;

end


/* ============================================================
 * NOTE OFF selection
 *
 * We need to support overlapping copies of the same MIDI note.
 *
 * Example:
 *
 * NOTE ON C4
 * NOTE ON C4
 *
 * Then one NOTE OFF C4 should only release ONE Voice.
 *
 * Policy:
 *
 * 1. Voice must be active
 * 2. Voice must NOT already be releasing
 * 3. Voice note must match midi_note
 * 4. If several match:
 *    choose oldest
 *
 *
 * Old implementation:
 *
 * Voice0 -> Voice1 -> Voice2 -> ... -> Voice31
 *
 * This creates a very deep combinational chain.
 *
 *
 * New implementation:
 *
 *       32
 *        |
 *       16
 *        |
 *        8
 *        |
 *        4
 *        |
 *        2
 *        |
 *        1
 *
 * Balanced reduction tree.
 * ============================================================ */


/* ------------------------------------------------------------
 * Candidate format:
 *
 * [ valid | age | index ]
 * ------------------------------------------------------------ */

localparam OFF_CAND_W =
    1 + AGE_W + IDX_W;

localparam OFF_VALID_BIT =
    OFF_CAND_W - 1;

localparam OFF_AGE_LSB =
    IDX_W;


/* ============================================================
 * Comparator function
 *
 * Returns the older valid candidate.
 * ============================================================ */

function [OFF_CAND_W-1:0]
    pick_oldest_match;

    input [OFF_CAND_W-1:0] a;
    input [OFF_CAND_W-1:0] b;

    begin

        /* Neither valid */
        if (
            !a[OFF_VALID_BIT] &&
            !b[OFF_VALID_BIT]
        ) begin

            pick_oldest_match = a;

        end

        /* Only A valid */
        else if (
            a[OFF_VALID_BIT] &&
            !b[OFF_VALID_BIT]
        ) begin

            pick_oldest_match = a;

        end

        /* Only B valid */
        else if (
            !a[OFF_VALID_BIT] &&
            b[OFF_VALID_BIT]
        ) begin

            pick_oldest_match = b;

        end

        /*
         * Both valid.
         *
         * Smaller age value means
         * the Voice was allocated earlier.
         */
        else if (
            a[OFF_AGE_LSB +: AGE_W] <
            b[OFF_AGE_LSB +: AGE_W]
        ) begin

            pick_oldest_match = a;

        end

        else if (
            b[OFF_AGE_LSB +: AGE_W] <
            a[OFF_AGE_LSB +: AGE_W]
        ) begin

            pick_oldest_match = b;

        end

        /*
         * Same age:
         * choose lower Voice index.
         */
        else if (
            a[IDX_W-1:0] <=
            b[IDX_W-1:0]
        ) begin

            pick_oldest_match = a;

        end

        else begin

            pick_oldest_match = b;

        end

    end

endfunction


/* ============================================================
 * Level 0
 *
 * Generate 32 NOTE-OFF candidates.
 *
 * This implementation is intentionally optimized for
 * the project's fixed 32-voice architecture.
 * ============================================================ */

wire [32*OFF_CAND_W-1:0]
    off_l0;


genvar off_g;

generate

    for (
        off_g = 0;
        off_g < 32;
        off_g = off_g + 1
    ) begin : GEN_NOTE_OFF_INPUT

        localparam [IDX_W-1:0]
            OFF_INDEX = off_g;

        wire note_match;


        assign note_match =

            voice_active[off_g]

            &&

            !voice_releasing[off_g]

            &&

            (
                notes[
                    off_g*7
                    +: 7
                ]
                ==
                midi_note
            );


        assign off_l0[
            off_g*OFF_CAND_W
            +: OFF_CAND_W
        ] =
        {
            note_match,

            ages[
                off_g*AGE_W
                +: AGE_W
            ],

            OFF_INDEX
        };

    end

endgenerate


/* ============================================================
 * Tree Level 1
 *
 * 32 -> 16
 * ============================================================ */

wire [16*OFF_CAND_W-1:0]
    off_l1;


genvar off1;

generate

    for (
        off1 = 0;
        off1 < 16;
        off1 = off1 + 1
    ) begin : GEN_OFF_L1

        assign off_l1[
            off1*OFF_CAND_W
            +: OFF_CAND_W
        ] =
            pick_oldest_match(

                off_l0[
                    (2*off1)*OFF_CAND_W
                    +: OFF_CAND_W
                ],

                off_l0[
                    (2*off1+1)*OFF_CAND_W
                    +: OFF_CAND_W
                ]

            );

    end

endgenerate


/* ============================================================
 * Tree Level 2
 *
 * 16 -> 8
 * ============================================================ */

wire [8*OFF_CAND_W-1:0]
    off_l2;


genvar off2;

generate

    for (
        off2 = 0;
        off2 < 8;
        off2 = off2 + 1
    ) begin : GEN_OFF_L2

        assign off_l2[
            off2*OFF_CAND_W
            +: OFF_CAND_W
        ] =
            pick_oldest_match(

                off_l1[
                    (2*off2)*OFF_CAND_W
                    +: OFF_CAND_W
                ],

                off_l1[
                    (2*off2+1)*OFF_CAND_W
                    +: OFF_CAND_W
                ]

            );

    end

endgenerate


/* ============================================================
 * Tree Level 3
 *
 * 8 -> 4
 * ============================================================ */

wire [4*OFF_CAND_W-1:0]
    off_l3;


genvar off3;

generate

    for (
        off3 = 0;
        off3 < 4;
        off3 = off3 + 1
    ) begin : GEN_OFF_L3

        assign off_l3[
            off3*OFF_CAND_W
            +: OFF_CAND_W
        ] =
            pick_oldest_match(

                off_l2[
                    (2*off3)*OFF_CAND_W
                    +: OFF_CAND_W
                ],

                off_l2[
                    (2*off3+1)*OFF_CAND_W
                    +: OFF_CAND_W
                ]

            );

    end

endgenerate


/* ============================================================
 * Tree Level 4
 *
 * 4 -> 2
 * ============================================================ */

wire [2*OFF_CAND_W-1:0]
    off_l4;


genvar off4;

generate

    for (
        off4 = 0;
        off4 < 2;
        off4 = off4 + 1
    ) begin : GEN_OFF_L4

        assign off_l4[
            off4*OFF_CAND_W
            +: OFF_CAND_W
        ] =
            pick_oldest_match(

                off_l3[
                    (2*off4)*OFF_CAND_W
                    +: OFF_CAND_W
                ],

                off_l3[
                    (2*off4+1)*OFF_CAND_W
                    +: OFF_CAND_W
                ]

            );

    end

endgenerate


/* ============================================================
 * Tree Level 5
 *
 * 2 -> 1
 * ============================================================ */

wire [OFF_CAND_W-1:0]
    off_final;


assign off_final =
    pick_oldest_match(

        off_l4[
            0*OFF_CAND_W
            +: OFF_CAND_W
        ],

        off_l4[
            1*OFF_CAND_W
            +: OFF_CAND_W
        ]

    );


/* ============================================================
 * Final NOTE-OFF result
 * ============================================================ */

wire match_found;

wire [IDX_W-1:0]
    match_index;


assign match_found =
    off_final[OFF_VALID_BIT];


assign match_index =
    off_final[IDX_W-1:0];


/* ============================================================
 * Generate Voice START / STOP pulses
 * ============================================================ */

always @(*) begin

    starts =
        {VOICES{1'b0}};

    stops =
        {VOICES{1'b0}};


    /* --------------------------------------------------------
     * NOTE ON
     *
     * Start exactly one selected Voice.
     * -------------------------------------------------------- */

    if (
        note_on &&
        grant
    ) begin

        starts[chosen] =
            1'b1;

    end


    /* --------------------------------------------------------
     * ALL NOTES OFF
     *
     * Release every currently active Voice.
     * -------------------------------------------------------- */

    if (all_notes_off) begin

        stops =
            voice_active;

    end


    /* --------------------------------------------------------
     * Normal NOTE OFF
     *
     * Release ONE oldest matching Voice.
     * -------------------------------------------------------- */

    else if (
        note_off &&
        match_found
    ) begin

        stops[match_index] =
            1'b1;

    end

end


/* ============================================================
 * Voice allocation age memory
 * ============================================================ */

always @(
    posedge clk or
    negedge rst_n
) begin

    if (!rst_n) begin

        age_counter <=
            {AGE_W{1'b0}};

        ages <=
            {(VOICES*AGE_W){1'b0}};

    end

    else if (
        note_on &&
        grant
    ) begin

        /*
         * Record when this Voice
         * was allocated.
         */
        ages[
            chosen*AGE_W
            +: AGE_W
        ] <=
            age_counter;


        /*
         * Global allocation sequence counter.
         */
        age_counter <=
            age_counter + 1'b1;

    end

end


/* ============================================================
 * 32 independent Voices
 * ============================================================ */

genvar g;

generate

    for (
        g = 0;
        g < VOICES;
        g = g + 1
    ) begin : G_VOICE

        wire [31:0]
            unused_inc;


        voice #(
            .SAMPLE_W(SAMPLE_W)
        ) u_voice (

            .clk          (clk),
            .rst_n        (rst_n),

            .sample_tick  (sample_tick),


            /* Voice control */

            .start        (
                starts[g]
            ),

            .stop         (
                stops[g]
            ),


            /* New NOTE parameters */

            .phase_inc_in (
                phase_inc
            ),

            .note_in      (
                midi_note
            ),

            .velocity_in  (
                velocity
            ),

            .waveform_in  (
                waveform
            ),


            /* Continuous expression */

            .morph_enable (
                morph_enable
            ),

            .morph_in     (
                morph
            ),


            /* Voice state */

            .active       (
                voice_active[g]
            ),

            .releasing    (
                voice_releasing[g]
            ),

            .env_level    (
                voice_env_levels[
                    g*SAMPLE_W
                    +: SAMPLE_W
                ]
            ),

            .note         (
                notes[
                    g*7
                    +: 7
                ]
            ),


            /* Debug */

            .phase_inc    (
                unused_inc
            ),


            /* Audio */

            .sample       (
                voice_samples[
                    g*SAMPLE_W
                    +: SAMPLE_W
                ]
            )

        );

    end

endgenerate


endmodule
