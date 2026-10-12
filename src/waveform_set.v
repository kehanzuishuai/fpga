module waveform_set #(
    parameter SAMPLE_W = 24
)(
    input      [31:0]                  phase,

    output reg signed [SAMPLE_W-1:0]   sine,
    output reg signed [SAMPLE_W-1:0]   square,
    output reg signed [SAMPLE_W-1:0]   saw,
    output reg signed [SAMPLE_W-1:0]   triangle
);


/* ============================================================
 * Quarter-wave sine LUT
 *
 * 只保存 0° ~ 90° 的正弦波。
 * 其他三个象限通过镜像和取负得到。
 * ============================================================ */

function [15:0] sin_q;

    input [6:0] a;

    begin
        case (a)

            7'd0:  sin_q = 16'd0;
            7'd1:  sin_q = 16'd804;
            7'd2:  sin_q = 16'd1608;
            7'd3:  sin_q = 16'd2410;
            7'd4:  sin_q = 16'd3212;
            7'd5:  sin_q = 16'd4011;
            7'd6:  sin_q = 16'd4808;
            7'd7:  sin_q = 16'd5602;

            7'd8:  sin_q = 16'd6393;
            7'd9:  sin_q = 16'd7179;
            7'd10: sin_q = 16'd7962;
            7'd11: sin_q = 16'd8739;
            7'd12: sin_q = 16'd9512;
            7'd13: sin_q = 16'd10278;
            7'd14: sin_q = 16'd11039;
            7'd15: sin_q = 16'd11793;

            7'd16: sin_q = 16'd12539;
            7'd17: sin_q = 16'd13279;
            7'd18: sin_q = 16'd14010;
            7'd19: sin_q = 16'd14732;
            7'd20: sin_q = 16'd15446;
            7'd21: sin_q = 16'd16151;
            7'd22: sin_q = 16'd16846;
            7'd23: sin_q = 16'd17530;

            7'd24: sin_q = 16'd18204;
            7'd25: sin_q = 16'd18868;
            7'd26: sin_q = 16'd19519;
            7'd27: sin_q = 16'd20159;
            7'd28: sin_q = 16'd20787;
            7'd29: sin_q = 16'd21403;
            7'd30: sin_q = 16'd22005;
            7'd31: sin_q = 16'd22594;

            7'd32: sin_q = 16'd23170;
            7'd33: sin_q = 16'd23731;
            7'd34: sin_q = 16'd24279;
            7'd35: sin_q = 16'd24811;
            7'd36: sin_q = 16'd25329;
            7'd37: sin_q = 16'd25832;
            7'd38: sin_q = 16'd26319;
            7'd39: sin_q = 16'd26790;

            7'd40: sin_q = 16'd27245;
            7'd41: sin_q = 16'd27683;
            7'd42: sin_q = 16'd28105;
            7'd43: sin_q = 16'd28510;
            7'd44: sin_q = 16'd28898;
            7'd45: sin_q = 16'd29268;
            7'd46: sin_q = 16'd29621;
            7'd47: sin_q = 16'd29956;

            7'd48: sin_q = 16'd30273;
            7'd49: sin_q = 16'd30571;
            7'd50: sin_q = 16'd30852;
            7'd51: sin_q = 16'd31113;
            7'd52: sin_q = 16'd31356;
            7'd53: sin_q = 16'd31580;
            7'd54: sin_q = 16'd31785;
            7'd55: sin_q = 16'd31971;

            7'd56: sin_q = 16'd32137;
            7'd57: sin_q = 16'd32285;
            7'd58: sin_q = 16'd32412;
            7'd59: sin_q = 16'd32521;

            7'd60: sin_q = 16'd32609;
            7'd61: sin_q = 16'd32678;
            7'd62: sin_q = 16'd32728;
            7'd63: sin_q = 16'd32757;

            default:
                sin_q = 16'd32767;

        endcase
    end

endfunction


/* ============================================================
 * Internal signals
 * ============================================================ */

reg [6:0]  lut_index;
reg        sine_negative;
reg [15:0] sine_magnitude;


/*
 * 内部统一先做成 24 bit 音频
 */
reg signed [23:0] sine24;
reg signed [23:0] square24;
reg signed [23:0] saw24;
reg signed [23:0] triangle24;


/*
 * Saw 用于判断被舍弃的低 8 bit 是否非 0
 */
reg fraction_nonzero;


/*
 * Triangle 专用
 *
 * 23-bit 幅度：
 * 0 ~ 0x7FFFFF
 */
reg [22:0] triangle_mag;


/*
 * ★ 修复点
 *
 * 三角波计算必须用 25 bit 中间变量。
 *
 * 原来：
 *
 * triangle24 << 1
 *
 * 仍然只有 24 bit，
 * 左移时最高位可能直接丢掉。
 *
 * 现在先扩大到 25 bit 再计算。
 */
reg signed [24:0] triangle_calc;


/* ============================================================
 * Waveform generation
 * ============================================================ */

always @(*) begin


    /* --------------------------------------------------------
     * 1. Sine
     *
     * phase[31:30] 表示当前在哪个象限
     * -------------------------------------------------------- */

    case (phase[31:30])

        /*
         * 0° ~ 90°
         */
        2'b00: begin

            lut_index =
                {1'b0, phase[29:24]};

            sine_negative =
                1'b0;

        end


        /*
         * 90° ~ 180°
         *
         * LUT反着查
         */
        2'b01: begin

            lut_index =
                7'd64 -
                {1'b0, phase[29:24]};

            sine_negative =
                1'b0;

        end


        /*
         * 180° ~ 270°
         */
        2'b10: begin

            lut_index =
                {1'b0, phase[29:24]};

            sine_negative =
                1'b1;

        end


        /*
         * 270° ~ 360°
         */
        default: begin

            lut_index =
                7'd64 -
                {1'b0, phase[29:24]};

            sine_negative =
                1'b1;

        end

    endcase


    /*
     * 查正弦 LUT
     */
    sine_magnitude =
        sin_q(lut_index);


    /*
     * LUT 是 16 bit
     *
     * 后面补 8 个 0
     * 变成 24 bit
     */
    if (sine_negative)

        sine24 =
            -$signed({
                sine_magnitude,
                8'b0
            });

    else

        sine24 =
            $signed({
                sine_magnitude,
                8'b0
            });



    /* --------------------------------------------------------
     * 2. Sawtooth
     * -------------------------------------------------------- */

    /*
     * 判断 phase 最低 8 bit 是否存在小数部分
     */
    fraction_nonzero =
        |phase[7:0];


    if (
        fraction_nonzero &&
        phase[31:8] != 24'h7FFFFF
    )

        saw24 =
            $signed(phase[31:8])
            + 24'sd1;

    else

        saw24 =
            $signed(phase[31:8]);



    /* --------------------------------------------------------
     * 3. Triangle
     * -------------------------------------------------------- */

    /*
     * phase[31] = 0
     *
     * 前半周期：
     * 0 → 最大值
     */
    if (!phase[31])

        triangle_mag =
            phase[30:8];


    /*
     * phase[31] = 1
     *
     * 后半周期：
     * 最大值 → 0
     *
     * 用按位取反实现折返。
     */
    else

        triangle_mag =
            ~phase[30:8];


    /*
     * 核心公式：
     *
     * triangle = 2 * magnitude - 0x7FFFFF
     *
     * 使用25 bit计算，避免左移溢出。
     *
     * {1'b0, triangle_mag, 1'b0}
     *
     * 最后的 1'b0 就等价于 ×2。
     */
    triangle_calc =
        $signed({
            1'b0,
            triangle_mag,
            1'b0
        })
        -
        25'sd8388607;


    /*
     * 结果范围已经在24 bit signed范围内，
     * 所以取低24 bit即可。
     */
    triangle24 =
        triangle_calc[23:0];



    /* --------------------------------------------------------
     * 4. Square
     * -------------------------------------------------------- */

    /*
     * phase最高位直接决定正负。
     *
     * 前半周期：正
     * 后半周期：负
     */
    if (phase[31])

        square24 =
            -24'sh7FFFFF;

    else

        square24 =
            24'sh7FFFFF;

end



/* ============================================================
 * Output width conversion
 *
 * 内部固定用24bit生成。
 * 最后根据 SAMPLE_W 调整输出宽度。
 * ============================================================ */

generate


    /*
     * SAMPLE_W < 24
     *
     * 例如16bit输出：
     * 取24bit中的高16bit。
     */
    if (SAMPLE_W < 24) begin : G_NARROW

        always @(*) begin

            sine =
                sine24[23 -: SAMPLE_W];

            square =
                square24[23 -: SAMPLE_W];

            saw =
                saw24[23 -: SAMPLE_W];

            triangle =
                triangle24[23 -: SAMPLE_W];

        end

    end


    /*
     * 正好24bit
     */
    else if (SAMPLE_W == 24) begin : G_NATIVE

        always @(*) begin

            sine     = sine24;
            square   = square24;
            saw      = saw24;
            triangle = triangle24;

        end

    end


    /*
     * SAMPLE_W > 24
     *
     * 低位补0。
     */
    else begin : G_WIDE

        always @(*) begin

            sine =
                {
                    sine24,
                    {(SAMPLE_W-24){1'b0}}
                };

            square =
                {
                    square24,
                    {(SAMPLE_W-24){1'b0}}
                };

            saw =
                {
                    saw24,
                    {(SAMPLE_W-24){1'b0}}
                };

            triangle =
                {
                    triangle24,
                    {(SAMPLE_W-24){1'b0}}
                };

        end

    end


endgenerate


endmodule