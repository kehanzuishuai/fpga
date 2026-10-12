module timbre_morph #(
    parameter SAMPLE_W = 24
)(
    input  signed [SAMPLE_W-1:0] sine,
    input  signed [SAMPLE_W-1:0] square,
    input  signed [SAMPLE_W-1:0] saw,
    input  signed [SAMPLE_W-1:0] triangle,

    input  [9:0] morph,

    output reg signed [SAMPLE_W-1:0] sample
);


/* ============================================================
 * Internal calculation width
 * ============================================================ */

localparam CALC_W = SAMPLE_W + 13;


/* ============================================================
 * Adjacent waveform pair
 * ============================================================ */

reg signed [SAMPLE_W-1:0] a;
reg signed [SAMPLE_W-1:0] b;


/* ============================================================
 * Interpolation coefficient
 *
 * frac:
 * 0 ... 1020
 *
 * Q10:
 * 1024 represents 1.0
 * ============================================================ */

reg [9:0] frac;

reg [11:0] frac_calc;
reg [9:0]  segment_pos;


/* ============================================================
 * Interpolation datapath
 * ============================================================ */

reg signed [SAMPLE_W:0] delta;
reg signed [11:0] frac_signed;

reg signed [CALC_W-1:0] product;
reg signed [CALC_W-1:0] a_extended;
reg signed [CALC_W-1:0] interpolated;

reg signed [CALC_W-1:0] max_sample;
reg signed [CALC_W-1:0] min_sample;


/* ============================================================
 * Combinational interpolation
 * ============================================================ */

always @(*) begin

    /* --------------------------------------------------------
     * Defaults
     * -------------------------------------------------------- */

    a           = sine;
    b           = sine;

    frac        = 10'd0;
    frac_calc   = 12'd0;
    segment_pos = 10'd0;


    /* --------------------------------------------------------
     * Exact endpoints
     * -------------------------------------------------------- */

    if (morph == 10'd0) begin

        a    = sine;
        b    = sine;
        frac = 10'd0;

    end

    else if (morph == 10'd1023) begin

        a    = triangle;
        b    = triangle;
        frac = 10'd0;

    end


    /* --------------------------------------------------------
     * Sine -> Square
     *
     * morph = 1 ... 340
     * -------------------------------------------------------- */

    else if (morph < 10'd341) begin

        a = sine;
        b = square;

        segment_pos = morph;

        /*
         * x * 3
         *
         * Do NOT use multiplier/DSP.
         *
         * 3*x = 2*x + x
         *
         * max:
         * 340 * 3 = 1020
         */
        frac_calc =
            ({2'b00, segment_pos} << 1)
            +
            {2'b00, segment_pos};

        frac =
            frac_calc[9:0];

    end


    /* --------------------------------------------------------
     * Square -> Saw
     *
     * morph = 341 ... 681
     * -------------------------------------------------------- */

    else if (morph < 10'd682) begin

        a = square;
        b = saw;

        segment_pos =
            morph - 10'd341;

        /*
         * 3*x = 2*x + x
         */
        frac_calc =
            ({2'b00, segment_pos} << 1)
            +
            {2'b00, segment_pos};

        frac =
            frac_calc[9:0];

    end


    /* --------------------------------------------------------
     * Saw -> Triangle
     *
     * morph = 682 ... 1022
     * -------------------------------------------------------- */

    else begin

        a = saw;
        b = triangle;

        segment_pos =
            morph - 10'd682;

        /*
         * 3*x = 2*x + x
         */
        frac_calc =
            ({2'b00, segment_pos} << 1)
            +
            {2'b00, segment_pos};

        frac =
            frac_calc[9:0];

    end


    /* ========================================================
     * Difference:
     *
     * delta = B - A
     *
     * One extra bit is required.
     * ======================================================== */

    delta =
        $signed({
            b[SAMPLE_W-1],
            b
        })
        -
        $signed({
            a[SAMPLE_W-1],
            a
        });


    /* ========================================================
     * Q10 interpolation coefficient
     * ======================================================== */

    frac_signed =
        $signed({
            2'b00,
            frac
        });


    /* ========================================================
     * TRUE variable multiplication
     *
     * This multiplication is worth using DSP for.
     *
     * (B-A) × frac
     * ======================================================== */

    product =
        delta * frac_signed;


    /* ========================================================
     * Sign extend A
     * ======================================================== */

    a_extended =
        {
            {(CALC_W-SAMPLE_W){
                a[SAMPLE_W-1]
            }},
            a
        };


    /* ========================================================
     * Linear interpolation:
     *
     * A + (B-A) * frac / 1024
     * ======================================================== */

    interpolated =
        a_extended
        +
        (product >>> 10);


    /* ========================================================
     * Signed SAMPLE_W limits
     * ======================================================== */

    max_sample =
        (
            $signed({
                {(CALC_W-1){1'b0}},
                1'b1
            })
            << (SAMPLE_W-1)
        )
        - 1'b1;


    min_sample =
        -(
            $signed({
                {(CALC_W-1){1'b0}},
                1'b1
            })
            << (SAMPLE_W-1)
        );


    /* ========================================================
     * Saturation
     * ======================================================== */

    if (morph == 10'd0) begin

        sample = sine;

    end

    else if (morph == 10'd1023) begin

        sample = triangle;

    end

    else if (interpolated > max_sample) begin

        sample =
            {
                1'b0,
                {(SAMPLE_W-1){1'b1}}
            };

    end

    else if (interpolated < min_sample) begin

        sample =
            {
                1'b1,
                {(SAMPLE_W-1){1'b0}}
            };

    end

    else begin

        sample =
            interpolated[SAMPLE_W-1:0];

    end

end


endmodule