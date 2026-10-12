module piano_string_model #(
    parameter SAMPLE_W     = 24,
    parameter PHASE_W      = 32,

    /*
     * 1 / 2048
     * ≈ 0.049 %
     * ≈ 0.85 cent
     *
     * 比上一版更轻，不再明显像 chorus。
     */
    parameter DETUNE_SHIFT = 11
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         sample_tick,

    input  wire                         start,
    input  wire                         active,

    input  wire [PHASE_W-1:0]           phase_a,
    input  wire [PHASE_W-1:0]           phase_inc,

    input  wire [7:0]                   velocity,

    output reg signed [SAMPLE_W-1:0]    body_sample,
    output reg signed [SAMPLE_W-1:0]    hammer_sample
);


/* ============================================================
 * Second virtual string
 * ============================================================ */

wire [PHASE_W-1:0]
    phase_inc_b;


assign phase_inc_b =

    phase_inc

    +

    (
        phase_inc >>
        DETUNE_SHIFT
    );


wire [PHASE_W-1:0]
    phase_b;


dds_phase_accum #(
    .PHASE_W(PHASE_W)
) u_phase_b (

    .clk
        (clk),

    .rst_n
        (rst_n),

    .sample_tick
        (sample_tick),

    .phase_reset
        (start),

    .phase_inc
        (phase_inc_b),

    .phase
        (phase_b)

);


/* ============================================================
 * Two strings
 * ============================================================ */

wire signed [23:0]
    low_a;

wire signed [23:0]
    high_a;

wire signed [23:0]
    low_b;

wire signed [23:0]
    high_b;


piano_dual_wavetable u_table_a (

    .clk
        (clk),

    .addr
        (
            phase_a[
                PHASE_W-1
                -: 8
            ]
        ),

    .low_sample
        (low_a),

    .high_sample
        (high_a)

);


piano_dual_wavetable u_table_b (

    .clk
        (clk),

    .addr
        (
            phase_b[
                PHASE_W-1
                -: 8
            ]
        ),

    .low_sample
        (low_b),

    .high_sample
        (high_b)

);


/* ============================================================
 * Piano note age
 * ============================================================ */

reg [18:0]
    piano_age;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        piano_age <=
            19'd0;

    end

    else if (start) begin

        piano_age <=
            19'd0;

    end

    else if (
        sample_tick &&
        active
    ) begin

        if (
            piano_age !=
            19'h7ffff
        ) begin

            piano_age <=
                piano_age + 1'b1;

        end

    end

end


/* ============================================================
 * Upper-harmonic spectral decay
 * ============================================================ */

function signed [23:0] shape_high;

    input signed [23:0] h;
    input        [18:0] age;
    input        [7:0]  vel;

    reg signed [23:0]
        time_scaled;

    reg signed [23:0]
        vel_scaled;

    begin

        /*
         * First 10 ms:
         * bright
         */
        if (
            age <
            19'd480
        ) begin

            time_scaled =
                h;

        end


        /*
         * 10 ~ 50 ms
         */
        else if (
            age <
            19'd2400
        ) begin

            time_scaled =

                (h >>> 1)

                +

                (h >>> 2);

        end


        /*
         * 50 ~ 150 ms
         */
        else if (
            age <
            19'd7200
        ) begin

            time_scaled =
                h >>> 1;

        end


        /*
         * 150 ~ 500 ms
         */
        else if (
            age <
            19'd24000
        ) begin

            time_scaled =
                h >>> 2;

        end


        /*
         * Long tail
         */
        else begin

            time_scaled =
                h >>> 3;

        end


        /* ----------------------------------------------------
         * Harder strike -> brighter spectrum
         * ---------------------------------------------------- */

        if (
            vel >=
            8'd112
        ) begin

            vel_scaled =
                time_scaled;

        end

        else if (
            vel >=
            8'd80
        ) begin

            vel_scaled =

                (time_scaled >>> 1)

                +

                (time_scaled >>> 2);

        end

        else if (
            vel >=
            8'd48
        ) begin

            vel_scaled =
                time_scaled >>> 1;

        end

        else begin

            vel_scaled =
                time_scaled >>> 2;

        end


        shape_high =
            vel_scaled;

    end

endfunction


wire signed [23:0]
    high_a_dynamic;

wire signed [23:0]
    high_b_dynamic;


assign high_a_dynamic =

    shape_high(
        high_a,
        piano_age,
        velocity
    );


/*
 * String B slightly softer
 */
wire signed [23:0]
    high_b_soft;


assign high_b_soft =

    (high_b >>> 1)

    +

    (high_b >>> 2);


assign high_b_dynamic =

    shape_high(
        high_b_soft,
        piano_age,
        velocity
    );


/* ============================================================
 * String B low body slightly softer
 * ============================================================ */

wire signed [23:0]
    low_b_soft;


assign low_b_soft =

    low_b

    -

    (low_b >>> 3);


/* ============================================================
 * Construct string A / B
 * ============================================================ */

wire signed [24:0]
    string_a;

wire signed [24:0]
    string_b;


assign string_a =

    $signed({
        low_a[23],
        low_a
    })

    +

    $signed({
        high_a_dynamic[23],
        high_a_dynamic
    });


assign string_b =

    $signed({
        low_b_soft[23],
        low_b_soft
    })

    +

    $signed({
        high_b_dynamic[23],
        high_b_dynamic
    });


/* ============================================================
 * Mix two strings
 *
 * each string / 2
 * ============================================================ */

wire signed [25:0]
    body_full;


assign body_full =

    (
        $signed({
            string_a[24],
            string_a
        })
        >>> 1
    )

    +

    (
        $signed({
            string_b[24],
            string_b
        })
        >>> 1
    );


/* ============================================================
 * Body saturation
 * ============================================================ */

always @(*) begin

    if (
        body_full >
        26'sd8388607
    ) begin

        body_sample =
            24'sh7fffff;

    end

    else if (
        body_full <
        -26'sd8388608
    ) begin

        body_sample =
            24'sh800000;

    end

    else begin

        body_sample =
            body_full[23:0];

    end

end


/* ============================================================
 * Hammer transient
 *
 * Important:
 *
 * This output is intentionally SEPARATE from body_sample.
 *
 * It will bypass the slow piano envelope in voice.v.
 * ============================================================ */

reg [15:0]
    hammer_lfsr;


wire
    hammer_feedback;


assign hammer_feedback =

    hammer_lfsr[15]

    ^

    hammer_lfsr[13]

    ^

    hammer_lfsr[12]

    ^

    hammer_lfsr[10];


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        hammer_lfsr <=
            16'hACE1;

    end

    else if (start) begin

        hammer_lfsr <=
            16'hACE1;

    end

    else if (
        sample_tick &&
        active
    ) begin

        hammer_lfsr <= {

            hammer_lfsr[14:0],

            hammer_feedback

        };

    end

end


wire signed [23:0]
    hammer_noise_raw;


assign hammer_noise_raw =

    $signed({

        {4{hammer_lfsr[15]}},

        hammer_lfsr,

        4'b0000

    });


/* ============================================================
 * Hammer =
 *
 * pitched high-frequency transient
 * +
 * small broadband impact component
 * ============================================================ */

wire signed [24:0]
    hammer_mix_early;

wire signed [24:0]
    hammer_mix_mid;

wire signed [24:0]
    hammer_mix_late;


assign hammer_mix_early =

    $signed({
        high_a[23],
        high_a
    })
    >>> 2

    +

    (
        $signed({
            hammer_noise_raw[23],
            hammer_noise_raw
        })
        >>> 4
    );


assign hammer_mix_mid =

    $signed({
        high_a[23],
        high_a
    })
    >>> 3

    +

    (
        $signed({
            hammer_noise_raw[23],
            hammer_noise_raw
        })
        >>> 5
    );


assign hammer_mix_late =

    $signed({
        high_a[23],
        high_a
    })
    >>> 4

    +

    (
        $signed({
            hammer_noise_raw[23],
            hammer_noise_raw
        })
        >>> 6
    );


always @(*) begin

    hammer_sample =
        24'sd0;


    /*
     * 0 ~ 1 ms
     */
    if (
        active &&
        piano_age <
        19'd48
    ) begin

        hammer_sample =
            hammer_mix_early[23:0];

    end


    /*
     * 1 ~ 3 ms
     */
    else if (
        active &&
        piano_age <
        19'd144
    ) begin

        hammer_sample =
            hammer_mix_mid[23:0];

    end


    /*
     * 3 ~ 6 ms
     */
    else if (
        active &&
        piano_age <
        19'd288
    ) begin

        hammer_sample =
            hammer_mix_late[23:0];

    end

end


endmodule