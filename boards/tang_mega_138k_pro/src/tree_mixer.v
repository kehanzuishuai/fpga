
module tree_mixer #(
    parameter VOICES       = 32,
    parameter SAMPLE_W     = 24,
    parameter LOG2_VOICES  = 5
)(
    input signed [VOICES*SAMPLE_W-1:0] samples,

    output signed
        [SAMPLE_W+LOG2_VOICES-1:0] mixed
);

localparam MIX_W = SAMPLE_W + LOG2_VOICES;

localparam N1 = VOICES / 2;
localparam N2 = VOICES / 4;
localparam N3 = (VOICES >= 8)  ? VOICES/8  : 1;
localparam N4 = (VOICES >= 16) ? VOICES/16 : 1;
localparam N5 = (VOICES >= 32) ? VOICES/32 : 1;


wire signed [VOICES*MIX_W-1:0] l0;
wire signed [N1*MIX_W-1:0]     l1;
wire signed [N2*MIX_W-1:0]     l2;
wire signed [N3*MIX_W-1:0]     l3;
wire signed [N4*MIX_W-1:0]     l4;
wire signed [N5*MIX_W-1:0]     l5;

genvar i;

generate

    /* Extend every voice to MIX_W */
    for (i = 0; i < VOICES; i = i + 1) begin : G_L0

        assign l0[i*MIX_W +: MIX_W] =
        {
            {(MIX_W-SAMPLE_W)
            {samples[i*SAMPLE_W+SAMPLE_W-1]}},

            samples[i*SAMPLE_W +: SAMPLE_W]
        };

    end


    /* 32 -> 16 */
    for (i = 0; i < N1; i = i + 1) begin : G_L1

        assign l1[i*MIX_W +: MIX_W] =
            l0[(2*i)*MIX_W +: MIX_W]
            +
            l0[(2*i+1)*MIX_W +: MIX_W];

    end


    /* 16 -> 8 */
    for (i = 0; i < N2; i = i + 1) begin : G_L2

        assign l2[i*MIX_W +: MIX_W] =
            l1[(2*i)*MIX_W +: MIX_W]
            +
            l1[(2*i+1)*MIX_W +: MIX_W];

    end


    if (VOICES >= 8) begin : G_L3

        for (i = 0; i < N3; i = i + 1) begin : G_ADD3

            assign l3[i*MIX_W +: MIX_W] =
                l2[(2*i)*MIX_W +: MIX_W]
                +
                l2[(2*i+1)*MIX_W +: MIX_W];

        end

    end
    else begin : G_NO_L3

        assign l3[MIX_W-1:0] = {MIX_W{1'b0}};

    end


    if (VOICES >= 16) begin : G_L4

        for (i = 0; i < N4; i = i + 1) begin : G_ADD4

            assign l4[i*MIX_W +: MIX_W] =
                l3[(2*i)*MIX_W +: MIX_W]
                +
                l3[(2*i+1)*MIX_W +: MIX_W];

        end

    end
    else begin : G_NO_L4

        assign l4[MIX_W-1:0] = {MIX_W{1'b0}};

    end


    if (VOICES >= 32) begin : G_L5

        for (i = 0; i < N5; i = i + 1) begin : G_ADD5

            assign l5[i*MIX_W +: MIX_W] =
                l4[(2*i)*MIX_W +: MIX_W]
                +
                l4[(2*i+1)*MIX_W +: MIX_W];

        end

    end
    else begin : G_NO_L5

        assign l5[MIX_W-1:0] = {MIX_W{1'b0}};

    end


    if (VOICES == 4) begin : G_OUT4

        assign mixed = l2[MIX_W-1:0];

    end
    else if (VOICES == 8) begin : G_OUT8

        assign mixed = l3[MIX_W-1:0];

    end
    else if (VOICES == 16) begin : G_OUT16

        assign mixed = l4[MIX_W-1:0];

    end
    else begin : G_OUT32

        assign mixed = l5[MIX_W-1:0];

    end

endgenerate

endmodule
