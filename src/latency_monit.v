

module latency_monitor #(
    parameter SAMPLE_W = 24,
    parameter COUNT_W  = 24,
    parameter VOICES   = 32,
    parameter IDX_W    = 5,

    parameter [SAMPLE_W-1:0] EFFECTIVE_THRESHOLD =
        {{(SAMPLE_W-1){1'b0}}, 1'b1}
)(
    input                           clk,
    input                           rst_n,
    input                           sample_tick,

    input                           event_strobe,
    input      [IDX_W-1:0]          event_voice_index,

    input signed [VOICES*SAMPLE_W-1:0] voice_samples,

    output reg                      dbg_event,
    output reg                      dbg_audio,
    output reg                      latency_valid,

    output reg [COUNT_W-1:0]        latency_samples
);


/* ============================================================
 * Internal state
 * ============================================================ */

/*
 * pending = 1
 *
 * 表示当前正在等待目标 Voice 真正产生声音
 */
reg pending;


/*
 * 记录本次事件分配到了哪个 Voice
 */
reg [IDX_W-1:0] target_index;


/*
 * 当前目标 Voice 的音频采样值
 */
reg signed [SAMPLE_W-1:0] target_sample;


/*
 * 目标 Voice 当前采样值的绝对值
 */
reg [SAMPLE_W-1:0] abs_target;


/* ============================================================
 * Select target Voice sample
 * ============================================================ */
always @(*) begin

    /*
     * 从所有 Voice 的拼接总线里，
     * 取出 target_index 对应的 SAMPLE_W 位
     */
    target_sample =
        voice_samples[target_index*SAMPLE_W +: SAMPLE_W];


    /*
     * Absolute value
     */
    if (target_sample[SAMPLE_W-1])
        abs_target = -target_sample;
    else
        abs_target = target_sample;

end


/* ============================================================
 * Latency measurement
 * ============================================================ */
always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        pending         <= 1'b0;
        target_index    <= {IDX_W{1'b0}};

        latency_samples <= {COUNT_W{1'b0}};
        latency_valid   <= 1'b0;

        dbg_event       <= 1'b0;
        dbg_audio       <= 1'b0;

    end

    else begin

        /*
         * Debug pulse
         */
        dbg_event <= event_strobe;

        /*
         * 默认只保持一个 clock 周期
         */
        dbg_audio     <= 1'b0;
        latency_valid <= 1'b0;


        /* ----------------------------------------------------
         * New Voice allocation event
         *
         * 开始计时
         * ---------------------------------------------------- */
        if (event_strobe) begin

            pending <= 1'b1;

            target_index <= event_voice_index;

            latency_samples <= {COUNT_W{1'b0}};

        end


        /* ----------------------------------------------------
         * Only count latency on audio sample boundaries
         * ---------------------------------------------------- */
        else if (sample_tick && pending) begin


            /*
             * 目标 Voice 已经产生有效声音
             */
            if (abs_target >= EFFECTIVE_THRESHOLD) begin

                pending <= 1'b0;

                latency_valid <= 1'b1;
                dbg_audio     <= 1'b1;

            end


            /*
             * Counter overflow protection
             *
             * &latency_samples = 1
             * 表示所有 bit 都为 1
             */
            else if (&latency_samples) begin

                pending <= 1'b0;

                latency_valid <= 1'b1;

            end


            /*
             * 还没有声音
             *
             * 延迟 +1 sample
             */
            else begin

                latency_samples <=
                    latency_samples + 1'b1;

            end

        end

    end

end


endmodule

