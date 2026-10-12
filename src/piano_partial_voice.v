/* ============================================================
 * piano_partial_voice
 *
 * One piano voice built from 15 sine partials with their own
 * frequency and their own amplitude curve, plus one hammer noise
 * slot.  It replaces voice.v + piano_string_model.v +
 * piano_dual_wavetable.v + piano_envelope.v and keeps the port
 * names of voice.v, so voice_bank.v instantiates it the same way.
 *
 * Method (after the AMY "interp_partials" piano, see
 * docs/02_amy_to_fpga.md):
 *
 *   sample = sum over slots of  amp(slot) * wave(slot)
 *
 *   wave   = sin(phase)             slots 0..14
 *            filtered noise         slot 15 (hammer)
 *   amp    = 16 * 2^-level - 0.001  (AMY units), 0 below 0.0011
 *   level  moves in straight lines (in dB) between 21 points per
 *          slot that the note loader wrote into the voice RAM
 *
 * The 16 slots are computed one after the other inside the
 * 256 clk cycles of one 48 kHz sample (clk = 12.288 MHz):
 *
 *   8 clk per slot                -> 128 clk per sample
 *   13 clk per slot at a segment
 *   boundary (21 times per note)  -> 208 clk per sample
 *
 * Resources per voice: 1 BSRAM (state + parameters), 2 pROM
 * (sine, 2^-x), 1 multiplier 27x18.
 *
 * Fixed point formats (same as tools/piano_tables.py):
 *   level   Q4.22 unsigned, 1.0 = 6.02 dB, 0 = amplitude 16.0
 *   phase   28 bit, one cycle = 2^28
 *   amp     24 bit unsigned, full scale = 16.0
 *   sample  24 bit signed,   full scale = 16.0
 *
 * tools/fpga_piano_model.py is the bit-exact model of this file;
 * sim/tb/tb_piano_voice.v compares them sample by sample.
 * ============================================================ */

module piano_partial_voice #(
    parameter SAMPLE_W = 24,
    parameter PHASE_W  = 32,

    /* Start value of the hammer noise generator (different per voice) */
    parameter [15:0] NOISE_SEED = 16'hACE1
)(
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        sample_tick,

    input  wire                        start,
    input  wire                        stop,

    /* Compatibility with voice.v: the loader sets the frequencies. */
    input  wire [PHASE_W-1:0]          phase_inc_in,
    input  wire [6:0]                  note_in,
    input  wire [7:0]                  velocity_in,
    input  wire [1:0]                  waveform_in,
    input  wire                        morph_enable,
    input  wire [9:0]                  morph_in,

    /* --------------------------------------------------------
     * Note loader
     *
     * ld_ready : this voice waits for its parameters; the engine
     *            is stopped and the loader may write the RAM
     * ld_we    : write strobe for this voice only
     * ld_done  : all words written, play from the next sample
     * -------------------------------------------------------- */
    output wire                        ld_ready,
    input  wire                        ld_we,
    input  wire [8:0]                  ld_addr,
    input  wire [31:0]                 ld_data,
    input  wire                        ld_done,
    input  wire [21:0]                 ld_rel_slope,

    /* 0: hammer noise slot muted (A/B comparison) */
    input  wire                        hammer_enable,

    output wire                        active,
    output reg                         releasing,
    output wire [SAMPLE_W-1:0]         env_level,

    output reg  [6:0]                  note,
    output reg  [PHASE_W-1:0]          phase_inc,

    output reg signed [SAMPLE_W-1:0]   sample,

    /* Debug / test bench */
    output reg                         dbg_sample_strobe,
    output wire                        dbg_rel,
    output wire                        dbg_fade,
    output reg                         dbg_overrun
);


/* ============================================================
 * Constants (tools/piano_tables.py)
 * ============================================================ */

localparam [4:0] W_INC   = 5'd0;
localparam [4:0] W_PHASE = 5'd1;
localparam [4:0] W_LEVEL = 5'd2;
localparam [4:0] W_SLOPE = 5'd3;
localparam [4:0] W_BP0   = 5'd4;

localparam [3:0] HAMMER_SLOT = 4'd15;

/* AMY: lin = 10^(dB/20) - 0.001, and amplitudes <= 0.0011 are off */
localparam signed [24:0] AMP_OFFSET = 25'sd1049;
localparam signed [24:0] AMP_GATE   = 25'sd1153;

/* round(2^18 / 3): segment lengths are 192 * 2^n samples */
localparam signed [17:0] K3 = 18'sd87381;

/* Voice stealing: 16 level units (96 dB) in 64 samples */
localparam signed [21:0] FADE_SLOPE = 22'sd1048576;

localparam [25:0] LEVEL_TOP = 26'h3FFFFFF;


/* ============================================================
 * Voice state
 * ============================================================ */

localparam [1:0] V_IDLE = 2'd0;
localparam [1:0] V_FADE = 2'd1;   /* old note fades out before a reload */
localparam [1:0] V_LOAD = 2'd2;   /* waiting for the note loader        */
localparam [1:0] V_PLAY = 2'd3;

reg [1:0]  vstate;

reg [4:0]  seg;         /* 0..20: segment in progress, 21: tail      */
reg [17:0] seg_cnt;     /* samples done in this segment               */
reg [21:0] rel_slope;

assign active    = (vstate != V_IDLE);
assign env_level = {SAMPLE_W{1'b0}};


/* ============================================================
 * Engine state
 * ============================================================ */

localparam [1:0] E_IDLE   = 2'd0;
localparam [1:0] E_RELOAD = 2'd1;
localparam [1:0] E_RUN    = 2'd2;
localparam [1:0] E_FIN    = 2'd3;

reg [1:0] eng;
reg [3:0] slot;
reg [2:0] step;

/* Flags latched at the sample tick: one value for all 16 slots */
reg rel_s;
reg fade_s;
reg boundary_s;

assign dbg_rel  = rel_s;
assign dbg_fade = fade_s;

assign ld_ready = (vstate == V_LOAD) && (eng == E_IDLE);


/* ============================================================
 * Segment length: 192 << n samples
 * ============================================================ */

function [3:0] seg_shift;
    input [4:0] s;
    begin
        case (s)
            5'd0, 5'd1, 5'd2, 5'd3: seg_shift = 4'd0;
            5'd4, 5'd5:             seg_shift = 4'd1;
            5'd6, 5'd7:             seg_shift = 4'd2;
            5'd8, 5'd9:             seg_shift = 4'd3;
            5'd10, 5'd11:           seg_shift = 4'd4;
            5'd12, 5'd13:           seg_shift = 4'd5;
            5'd14, 5'd15:           seg_shift = 4'd6;
            5'd16, 5'd17:           seg_shift = 4'd7;
            default:                seg_shift = 4'd8;
        endcase
    end
endfunction

wire [3:0]  cur_shift;
wire [17:0] seg_last;

assign cur_shift = seg_shift(seg);
assign seg_last  = (18'd192 << cur_shift) - 18'd1;


/* ============================================================
 * Voice RAM: 16 slots x 32 words
 * ============================================================ */

reg         ram_we;
reg  [8:0]  ram_waddr;
reg  [31:0] ram_wdata;
reg  [8:0]  ram_raddr;
wire [31:0] ram_rdata;

piano_voice_ram u_ram (
    .clk   (clk),
    .we    (ram_we),
    .waddr (ram_waddr),
    .wdata (ram_wdata),
    .raddr (ram_raddr),
    .rdata (ram_rdata)
);


/* ============================================================
 * Datapath registers
 * ============================================================ */

reg [27:0] inc_r;
reg [27:0] phase_r;
reg [25:0] lvl_r;
reg [16:0] sin_val_r;
reg [23:0] amp_r;

reg signed [26:0] mul_a;
reg signed [17:0] mul_b;
reg signed [44:0] mul_p;

reg signed [47:0] acc;
reg               add_pending;
reg               audible;


/* ============================================================
 * Sine: quarter wave ROM with linear interpolation
 * ============================================================ */

wire        quad_mirror;
wire        quad_negate;
wire [8:0]  sine_addr;
wire [9:0]  sine_frac;
wire [25:0] sine_q;

assign quad_mirror = phase_r[26];
assign quad_negate = phase_r[27];

assign sine_addr = quad_mirror ? ~phase_r[25:17] : phase_r[25:17];
assign sine_frac = quad_mirror ? ~phase_r[16:7]  : phase_r[16:7];

piano_sine_rom u_sine (
    .clk  (clk),
    .addr (sine_addr),
    .q    (sine_q)
);

wire [17:0] sin_i;

assign sin_i = {1'b0, sin_val_r} + {9'd0, mul_p[18:10]};


/* ============================================================
 * Hammer noise: 16 bit LFSR, two one-pole low-pass filters.
 * Runs on every sample so that every strike is different.
 * ============================================================ */

reg [15:0]        lfsr;
reg signed [20:0] noise_y1;
reg signed [20:0] noise_y2;

wire [15:0]        lfsr_n;
wire signed [20:0] noise_x;
wire signed [21:0] noise_d1;
wire signed [20:0] noise_y1_n;
wire signed [21:0] noise_d2;
wire signed [20:0] noise_y2_n;

assign lfsr_n = {
    lfsr[14:0],
    lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]
};

assign noise_x    = {lfsr_n[15], lfsr_n, 4'b0000};
assign noise_d1   = {noise_x[20], noise_x} - {noise_y1[20], noise_y1};
assign noise_y1_n = noise_y1 + (noise_d1 >>> 3);
assign noise_d2   = {noise_y1_n[20], noise_y1_n} - {noise_y2[20], noise_y2};
assign noise_y2_n = noise_y2 + (noise_d2 >>> 3);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lfsr     <= NOISE_SEED;
        noise_y1 <= 21'sd0;
        noise_y2 <= 21'sd0;
    end
    else if (sample_tick) begin
        lfsr     <= lfsr_n;
        noise_y1 <= noise_y1_n;
        noise_y2 <= noise_y2_n;
    end
end

wire signed [19:0] noise_half;
reg  signed [17:0] noise_w;

assign noise_half = noise_y2[20:1];

always @(*) begin
    if (noise_half > 20'sd131071)
        noise_w = 18'sd131071;
    else if (noise_half < -20'sd131071)
        noise_w = -18'sd131071;
    else
        noise_w = noise_half[17:0];
end


/* ============================================================
 * Wave of the current slot, 18 bit signed, full scale 2^17 - 1
 * ============================================================ */

reg signed [17:0] wave_w;

always @(*) begin
    if (slot == HAMMER_SLOT)
        wave_w = hammer_enable ? noise_w : 18'sd0;
    else if (quad_negate)
        wave_w = -$signed(sin_i);
    else
        wave_w = $signed(sin_i);
end


/* ============================================================
 * Amplitude from level:  16 * 2^-level - 0.001, gated
 * ============================================================ */

wire [17:0] exp_q;

piano_exp_rom u_exp (
    .clk  (clk),
    .addr (lvl_r[21:12]),
    .q    (exp_q)
);

wire [23:0]        amp_raw;
wire signed [24:0] amp_off;
wire [23:0]        amp_now;

assign amp_raw = {exp_q, 6'b000000} >> lvl_r[25:22];
assign amp_off = $signed({1'b0, amp_raw}) - AMP_OFFSET;
assign amp_now = (amp_off <= AMP_GATE) ? 24'd0 : amp_off[23:0];


/* ============================================================
 * Level update
 * ============================================================ */

wire signed [21:0] slope_eff;
wire signed [27:0] lvl_sum;
reg  [25:0]        lvl_next;

assign slope_eff =
    fade_s ? FADE_SLOPE :
    rel_s  ? $signed(rel_slope) :
             $signed(ram_rdata[21:0]);

assign lvl_sum =
    $signed({2'b00, lvl_r}) +
    $signed({{6{slope_eff[21]}}, slope_eff});

always @(*) begin
    if (lvl_sum[27])
        lvl_next = 26'd0;
    else if (lvl_sum[26])
        lvl_next = LEVEL_TOP;
    else
        lvl_next = lvl_sum[25:0];
end


/* ============================================================
 * Slope towards the next point (segment boundary)
 *
 *   slope = (point - level) / (192 * 2^n)
 *         = ((point - level) * K3) >> (18 + 6 + n)
 * ============================================================ */

wire signed [26:0] reload_x;
wire signed [44:0] reload_shifted;

assign reload_x =
    $signed({1'b0, ram_rdata[11:0], 14'd0}) -
    $signed({1'b0, lvl_r});

assign reload_shifted = mul_p >>> (6'd24 + {2'b00, cur_shift});


/* ============================================================
 * RAM address / write control (combinational)
 * ============================================================ */

always @(*) begin

    ram_raddr = {slot, W_INC};
    ram_we    = 1'b0;
    ram_waddr = {slot, W_PHASE};
    ram_wdata = 32'd0;


    if (vstate == V_LOAD) begin

        /* The loader owns the write port */
        ram_we    = ld_we;
        ram_waddr = ld_addr;
        ram_wdata = ld_data;

    end

    else if (eng == E_RELOAD) begin

        case (step)
            3'd0: ram_raddr = {slot, W_LEVEL};
            3'd1: ram_raddr = {slot, W_BP0 + seg};
            3'd4: begin
                ram_we    = 1'b1;
                ram_waddr = {slot, W_SLOPE};
                ram_wdata = {{10{reload_shifted[21]}}, reload_shifted[21:0]};
            end
            default: ;
        endcase

    end

    else if (eng == E_RUN) begin

        case (step)
            3'd0: ram_raddr = {slot, W_INC};
            3'd1: ram_raddr = {slot, W_PHASE};
            3'd2: begin
                ram_raddr = {slot, W_LEVEL};
                ram_we    = 1'b1;
                ram_waddr = {slot, W_PHASE};
                ram_wdata = {4'd0, ram_rdata[27:0] + inc_r};
            end
            3'd3: ram_raddr = {slot, W_SLOPE};
            3'd4: begin
                ram_we    = 1'b1;
                ram_waddr = {slot, W_LEVEL};
                ram_wdata = {6'd0, lvl_next};
            end
            default: ;
        endcase

    end

end


/* ============================================================
 * Output scaling: 2^41 in acc = amplitude 16.0 = 2^23 in sample
 * ============================================================ */

wire signed [47:0] acc_shifted;
reg  signed [SAMPLE_W-1:0] sample_next;

assign acc_shifted = acc >>> 18;

always @(*) begin
    if (acc_shifted > 48'sd8388607)
        sample_next = 24'sh7FFFFF;
    else if (acc_shifted < -48'sd8388608)
        sample_next = 24'sh800000;
    else
        sample_next = acc_shifted[SAMPLE_W-1:0];
end


/* ============================================================
 * Multiplier: one 27 x 18 signed, shared by three products
 * ============================================================ */

always @(posedge clk) begin
    mul_p <= mul_a * mul_b;
end


/* ============================================================
 * Sequencer
 * ============================================================ */

wire engine_wanted;

assign engine_wanted =
    (vstate == V_PLAY) || (vstate == V_FADE);

wire may_stop;

assign may_stop = rel_s || fade_s || (seg >= 5'd2);


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        vstate      <= V_IDLE;
        releasing   <= 1'b0;
        note        <= 7'd0;
        phase_inc   <= {PHASE_W{1'b0}};
        seg         <= 5'd0;
        seg_cnt     <= 18'd0;
        rel_slope   <= 22'd0;

        eng         <= E_IDLE;
        slot        <= 4'd0;
        step        <= 3'd0;
        rel_s       <= 1'b0;
        fade_s      <= 1'b0;
        boundary_s  <= 1'b0;

        inc_r       <= 28'd0;
        phase_r     <= 28'd0;
        lvl_r       <= 26'd0;
        sin_val_r   <= 17'd0;
        amp_r       <= 24'd0;
        mul_a       <= 27'sd0;
        mul_b       <= 18'sd0;

        acc         <= 48'sd0;
        add_pending <= 1'b0;
        audible     <= 1'b0;

        sample            <= {SAMPLE_W{1'b0}};
        dbg_sample_strobe <= 1'b0;
        dbg_overrun       <= 1'b0;

    end

    else begin

        dbg_sample_strobe <= 1'b0;


        /* ----------------------------------------------------
         * Product of the slot that just finished
         * ---------------------------------------------------- */

        if (add_pending) begin
            acc         <= acc + {{3{mul_p[44]}}, mul_p};
            add_pending <= 1'b0;
        end


        /* ----------------------------------------------------
         * Engine
         * ---------------------------------------------------- */

        case (eng)

            E_IDLE: begin

                if (sample_tick && engine_wanted) begin

                    slot    <= 4'd0;
                    step    <= 3'd0;
                    acc     <= 48'sd0;
                    audible <= 1'b0;

                    rel_s   <= releasing;
                    fade_s  <= (vstate == V_FADE);

                    if (
                        (vstate == V_PLAY) &&
                        !releasing &&
                        (seg <= 5'd20) &&
                        (seg_cnt == 18'd0)
                    ) begin
                        boundary_s <= 1'b1;
                        eng        <= E_RELOAD;
                    end
                    else begin
                        boundary_s <= 1'b0;
                        eng        <= E_RUN;
                    end

                end

            end


            /* ------------------------------------------------
             * Segment boundary: new slope for this slot
             * ------------------------------------------------ */

            E_RELOAD: begin

                step <= step + 1'b1;

                case (step)

                    3'd1: lvl_r <= ram_rdata[25:0];

                    3'd2: begin
                        mul_a <= reload_x;
                        mul_b <= K3;
                    end

                    3'd4: begin
                        step <= 3'd0;
                        eng  <= E_RUN;
                    end

                    default: ;

                endcase

            end


            /* ------------------------------------------------
             * One slot: phase, level, amplitude, product
             * ------------------------------------------------ */

            E_RUN: begin

                step <= step + 1'b1;

                case (step)

                    3'd1: inc_r <= ram_rdata[27:0];

                    3'd2: phase_r <= ram_rdata[27:0];

                    3'd3: lvl_r <= ram_rdata[25:0];

                    3'd4: begin
                        sin_val_r <= sine_q[25:9];
                        mul_a     <= {18'd0, sine_q[8:0]};
                        mul_b     <= {8'd0, sine_frac};
                    end

                    3'd5: amp_r <= amp_now;

                    3'd6: begin
                        mul_a <= {3'b000, amp_r};
                        mul_b <= wave_w;
                    end

                    3'd7: begin

                        add_pending <= 1'b1;

                        if (amp_r != 24'd0)
                            audible <= 1'b1;

                        step <= 3'd0;

                        if (slot == 4'd15) begin
                            eng <= E_FIN;
                        end
                        else begin
                            slot <= slot + 1'b1;
                            eng  <= boundary_s ? E_RELOAD : E_RUN;
                        end

                    end

                    default: ;

                endcase

            end


            /* ------------------------------------------------
             * Sample complete
             * ------------------------------------------------ */

            E_FIN: begin

                step <= step + 1'b1;

                if (step == 3'd1) begin

                    sample            <= sample_next;
                    dbg_sample_strobe <= 1'b1;

                    step <= 3'd0;
                    eng  <= E_IDLE;


                    /* Segment bookkeeping */
                    if (!rel_s && !fade_s && (seg <= 5'd20)) begin
                        if (seg_cnt == seg_last) begin
                            seg     <= seg + 1'b1;
                            seg_cnt <= 18'd0;
                        end
                        else begin
                            seg_cnt <= seg_cnt + 1'b1;
                        end
                    end


                    /* All slots silent: the note is over */
                    if (!audible && may_stop) begin
                        if (vstate == V_FADE)
                            vstate <= V_LOAD;
                        else if (vstate == V_PLAY)
                            vstate <= V_IDLE;
                    end

                end

            end

        endcase


        /* A sample tick while the engine is still busy */
        if (sample_tick && (eng != E_IDLE))
            dbg_overrun <= 1'b1;


        /* ----------------------------------------------------
         * Note control.  Highest priority: a new note.
         * ---------------------------------------------------- */

        if (start) begin

            note      <= note_in;
            phase_inc <= phase_inc_in;
            releasing <= 1'b0;

            if (vstate == V_PLAY || vstate == V_FADE)
                vstate <= V_FADE;
            else
                vstate <= V_LOAD;

        end

        else begin

            if (stop && active)
                releasing <= 1'b1;

            if ((vstate == V_LOAD) && ld_done) begin
                vstate    <= V_PLAY;
                seg       <= 5'd0;
                seg_cnt   <= 18'd0;
                rel_slope <= ld_rel_slope;
            end

            if (vstate == V_IDLE)
                releasing <= 1'b0;

        end

    end

end


endmodule


/* ============================================================
 * Voice RAM: 512 x 32, one write port, one registered read port.
 * Written in the form GowinSynthesis maps to one SDPB block.
 * ============================================================ */

module piano_voice_ram (
    input  wire        clk,
    input  wire        we,
    input  wire [8:0]  waddr,
    input  wire [31:0] wdata,
    input  wire [8:0]  raddr,
    output reg  [31:0] rdata
);

reg [31:0] mem [0:511];

always @(posedge clk) begin
    if (we)
        mem[waddr] <= wdata;
end

always @(posedge clk) begin
    rdata <= mem[raddr];
end

endmodule
