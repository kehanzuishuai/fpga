/* ============================================================
 * piano_note_loader
 *
 * One instance for all voices.  At Note On it does what AMY's
 * interp_partials_note_on() does: for the note and velocity it
 * interpolates the stored piano data between the two nearest
 * stored notes (every 4 semitones, MIDI 24..104) and the two
 * nearest stored velocities (40, 80, 120), and writes the result
 * into the RAM of the chosen voice:
 *
 *   per slot (15 partials + hammer):
 *     word 0      phase increment  = note increment * partial ratio
 *     word 1      phase            = 0
 *     word 2      level            = start of the attack
 *     word 3      slope            = 0
 *     word 4..24  21 level points  (Q4.8)
 *
 * One note takes about 1350 clk cycles (0.11 ms at 12.288 MHz): the
 * level ROM is read on every clock (tools/loader_pipeline_20261024.py).
 * While `busy` is high the Note FIFO must not deliver events.
 *
 * tools/fpga_piano_model.py (class Loader) is the bit-exact model.
 * ============================================================ */

module piano_note_loader #(
    parameter VOICES = 32,
    parameter IDX_W  = 5
)(
    input  wire              clk,
    input  wire              rst_n,

    input  wire              req_valid,
    input  wire [IDX_W-1:0]  req_voice,
    input  wire [6:0]        req_note,
    input  wire [7:0]        req_velocity,
    input  wire [31:0]       req_inc0,

    output wire              busy,

    input  wire [VOICES-1:0] voice_ready,

    output reg  [VOICES-1:0] ld_we,
    output reg  [8:0]        ld_addr,
    output reg  [31:0]       ld_data,
    output reg  [VOICES-1:0] ld_done,
    output reg  [21:0]       ld_rel_slope
);


localparam [4:0] W_INC   = 5'd0;
localparam [4:0] W_PHASE = 5'd1;
localparam [4:0] W_LEVEL = 5'd2;
localparam [4:0] W_SLOPE = 5'd3;
localparam [4:0] W_BP0   = 5'd4;

/* Start of the attack: 13.0 level units below amplitude 16 */
localparam [25:0] L_INIT = 26'h3400000;

localparam [11:0] L_MISSING = 12'hFFF;
localparam [11:0] L_MAX     = 12'hFFE;

/* Q4.8 extra attenuation per velocity step below 40 (0.61 dB) */
localparam [4:0] EXTRA_PER_VEL = 5'd26;


/* ============================================================
 * States
 * ============================================================ */

localparam [2:0] S_IDLE = 3'd0;
localparam [2:0] S_PREP = 3'd1;
localparam [2:0] S_WAIT = 3'd2;
localparam [2:0] S_RUN  = 3'd3;
localparam [2:0] S_DONE = 3'd4;

reg [2:0] state;

assign busy = (state != S_IDLE);

/* Slot stream: partial frequency and the four header words of a slot */
localparam [3:0] H_R0  = 4'd0;
localparam [3:0] H_R1  = 4'd1;
localparam [3:0] H_R2  = 4'd2;
localparam [3:0] H_R3  = 4'd3;
localparam [3:0] H_W0  = 4'd4;
localparam [3:0] H_W1  = 4'd5;
localparam [3:0] H_W2  = 4'd6;
localparam [3:0] H_W3  = 4'd7;
localparam [3:0] H_END = 4'd8;

reg [3:0] hstate;
reg [3:0] hslot;

/* Level stream: 16 slots x 21 points x 4 ROM words */
localparam [10:0] RD_TOTAL = 11'd1344;

reg [10:0] rd_count;
reg [1:0]  rd_word_q;
reg        rd_valid_q;
reg        lvl_interp;
reg        lvl_wr;

wire rd_issue = (state == S_RUN) && (rd_count != RD_TOTAL);


/* ============================================================
 * Request registers
 * ============================================================ */

reg [IDX_W-1:0] voice_r;
reg [6:0]       note_r;
reg [7:0]       vel_r;
reg [31:0]      inc0_r;

reg [3:0] slot;
reg [4:0] point;


/* ============================================================
 * Position in the stored grid
 *
 *   grid note j   = MIDI 24 + 4*j, j = 0..20
 *   ap            = quarters of the way from j to j+1   (0..4)
 *   velocity vl   = 0: between 40 and 80, 1: between 80 and 120
 *   av            = position between the two velocities (0..256)
 * ============================================================ */

wire [6:0] note_c;
wire [6:0] note_t;
wire [4:0] grid_j;
wire [6:0] ap_wide;
wire [2:0] ap;

assign note_c = (note_r < 7'd24)  ? 7'd24 :
                (note_r > 7'd104) ? 7'd104 : note_r;

assign note_t = note_c - 7'd24;

assign grid_j = (note_t[6:2] > 5'd19) ? 5'd19 : note_t[6:2];

assign ap_wide = note_t - {grid_j, 2'b00};
assign ap      = ap_wide[2:0];

wire [7:0]  vel_c;
wire        vel_l;
wire [7:0]  vel_d;
wire [15:0] av_prod;
wire [8:0]  av;

assign vel_c = (vel_r < 8'd40)  ? 8'd40 :
               (vel_r > 8'd120) ? 8'd120 : vel_r;

assign vel_l = (vel_c >= 8'd80);

assign vel_d = vel_l ? (vel_c - 8'd80) : (vel_c - 8'd40);

assign av_prod = vel_d * 8'd205;

assign av = av_prod[13:5];

wire [7:0]  soft_steps;
wire [12:0] extra_att;

assign soft_steps = (vel_r < 8'd40) ? (8'd40 - vel_r) : 8'd0;

assign extra_att = soft_steps * EXTRA_PER_VEL;


/* ============================================================
 * ROM addresses
 *
 * level ROM: ((note*3 + vel)*16 + slot)*21 + point
 *            = (note*3 + vel)*336 + word, word = slot*21 + point
 * ============================================================ */

wire [6:0]  nv_index;
wire [14:0] base0;

assign nv_index = {1'b0, grid_j, 1'b0} + {2'b00, grid_j} + {6'd0, vel_l};

assign base0 =
    {nv_index, 8'd0} +
    {2'b00, nv_index, 6'd0} +
    {4'd0, nv_index, 4'd0};

reg [14:0] ptr0;    /* note j,   lower velocity */
reg [14:0] ptr1;    /* note j,   upper velocity */
reg [14:0] ptr2;    /* note j+1, lower velocity */
reg [14:0] ptr3;    /* note j+1, upper velocity */

reg  [14:0] level_addr;
wire [11:0] level_q;

piano_level_rom u_level_rom (
    .clk  (clk),
    .addr (level_addr),
    .q    (level_q)
);

reg  [8:0]  ratio_addr;
wire [19:0] ratio_q;

piano_ratio_rom u_ratio_rom (
    .clk  (clk),
    .addr (ratio_addr),
    .q    (ratio_q)
);

wire [21:0] note_q;

piano_note_rom u_note_rom (
    .clk  (clk),
    .addr (note_r),
    .q    (note_q)
);

wire [4:0] grid_j1;

assign grid_j1 = grid_j + 5'd1;

always @(*) begin

    case (rd_count[1:0])
        2'd1:    level_addr = ptr1;
        2'd2:    level_addr = ptr2;
        2'd3:    level_addr = ptr3;
        default: level_addr = ptr0;
    endcase

    if (hstate == H_R1)
        ratio_addr = {grid_j1, hslot};
    else
        ratio_addr = {grid_j, hslot};

end


/* ============================================================
 * Interpolation
 * ============================================================ */

reg [11:0] lv_a;
reg [11:0] lv_b;
reg [11:0] lv_c;
reg [11:0] lv_d;

/* pitch: between note j and note j+1, at both velocities */

wire signed [12:0] dp_lo;
wire signed [12:0] dp_hi;
wire signed [16:0] mp_lo;
wire signed [16:0] mp_hi;
wire signed [16:0] lo_w;
wire signed [16:0] hi_w;

assign dp_lo = $signed({1'b0, lv_c}) - $signed({1'b0, lv_a});
assign dp_hi = $signed({1'b0, lv_d}) - $signed({1'b0, lv_b});

/*
 * Keep pitch weighting in fabric. Gowin 1.9.12 folds (zero-extended
 * unsigned ROM word - another ROM word) * ap into a DSP pre-adder,
 * but extends the subtrahend with ones in the synthesized netlist.
 * That adds 4096 to level differences and 2^20 to ratio differences:
 * grid notes sound correct, intermediate notes become bells/silence.
 * Explicit quarter weights avoid that faulty DSP transformation while
 * preserving the signed product and its subsequent floor shift exactly.
 */
function signed [24:0] pitch_weight;
    input signed [24:0] delta;
    input [2:0] quarters;
    begin
        case (quarters)
            3'd0: pitch_weight = 25'sd0;
            3'd1: pitch_weight = delta;
            3'd2: pitch_weight = delta <<< 1;
            3'd3: pitch_weight = delta + (delta <<< 1);
            3'd4: pitch_weight = delta <<< 2;
            default: pitch_weight = 25'sd0;
        endcase
    end
endfunction

assign mp_lo = pitch_weight($signed({{12{dp_lo[12]}}, dp_lo}), ap);
assign mp_hi = pitch_weight($signed({{12{dp_hi[12]}}, dp_hi}), ap);

assign lo_w = $signed({5'd0, lv_a}) + (mp_lo >>> 2);
assign hi_w = $signed({5'd0, lv_b}) + (mp_hi >>> 2);

reg signed [13:0] lo_r;
reg signed [13:0] hi_r;
reg               missing_r;

/* velocity: between the two velocity layers */

wire signed [14:0] dv;
wire signed [24:0] mv;
wire signed [24:0] xv;
wire signed [24:0] xe;
reg  [11:0]        level_out;

assign dv = $signed({hi_r[13], hi_r}) - $signed({lo_r[13], lo_r});
assign mv = dv * $signed({1'b0, av});
/*
 * Every operand has to be signed here: one unsigned operand would
 * turn ">>>" into a logical shift and a falling level into silence.
 */
assign xv = $signed({{11{lo_r[13]}}, lo_r}) + (mv >>> 8);
assign xe = xv + $signed({12'd0, extra_att});

always @(*) begin
    if (missing_r)
        level_out = L_MISSING;
    else if (xe > 25'sd4094)
        level_out = L_MAX;
    else if (xe < 25'sd0)
        level_out = 12'd0;
    else
        level_out = xe[11:0];
end

/* partial ratio and phase increment */

reg [19:0] ratio_a;

wire signed [20:0] dr;
wire signed [24:0] mr;
wire signed [24:0] ratio_w;
reg  [19:0]        ratio_r;
reg  [51:0]        inc_prod;

assign dr      = $signed({1'b0, ratio_q}) - $signed({1'b0, ratio_a});
assign mr      = pitch_weight($signed({{4{dr[20]}}, dr}), ap);
assign ratio_w = $signed({5'd0, ratio_a}) + (mr >>> 2);


/* ============================================================
 * Sequencer
 * ============================================================ */

wire [VOICES-1:0] voice_onehot;

assign voice_onehot = {{(VOICES-1){1'b0}}, 1'b1} << voice_r;


/*
 * Level stream: one ROM read per clock (ptr0..ptr3), the word lands in
 * lv_a..lv_d on the next clock; one clock after lv_d the point is
 * interpolated over pitch (lo_r, hi_r, missing_r), on the clock after
 * that over velocity and written (lvl_wr).  Reads of the next point
 * overwrite lv_a only at the end of the interpolation clock.
 * Slot stream: as the old S_R0..S_R7 per slot; a header write waits
 * while lvl_wr owns the write port.
 */
always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        state        <= S_IDLE;
        hstate       <= H_END;
        hslot        <= 4'd0;
        rd_count     <= 11'd0;
        rd_word_q    <= 2'd0;
        rd_valid_q   <= 1'b0;
        lvl_interp   <= 1'b0;
        lvl_wr       <= 1'b0;
        voice_r      <= {IDX_W{1'b0}};
        note_r       <= 7'd0;
        vel_r        <= 8'd0;
        inc0_r       <= 32'd0;
        slot         <= 4'd0;
        point        <= 5'd0;
        ptr0         <= 15'd0;
        ptr1         <= 15'd0;
        ptr2         <= 15'd0;
        ptr3         <= 15'd0;
        lv_a         <= 12'd0;
        lv_b         <= 12'd0;
        lv_c         <= 12'd0;
        lv_d         <= 12'd0;
        lo_r         <= 14'sd0;
        hi_r         <= 14'sd0;
        missing_r    <= 1'b0;
        ratio_a      <= 20'd0;
        ratio_r      <= 20'd0;
        inc_prod     <= 52'd0;
        ld_we        <= {VOICES{1'b0}};
        ld_addr      <= 9'd0;
        ld_data      <= 32'd0;
        ld_done      <= {VOICES{1'b0}};
        ld_rel_slope <= 22'd0;
    end

    else begin

        ld_we   <= {VOICES{1'b0}};
        ld_done <= {VOICES{1'b0}};

        /* ------------------------------------------------
         * Level stream
         * ------------------------------------------------ */

        rd_valid_q <= rd_issue;
        rd_word_q  <= rd_count[1:0];

        if (rd_issue) begin
            rd_count <= rd_count + 11'd1;
            if (rd_count[1:0] == 2'd3) begin
                ptr0 <= ptr0 + 15'd1;
                ptr1 <= ptr1 + 15'd1;
                ptr2 <= ptr2 + 15'd1;
                ptr3 <= ptr3 + 15'd1;
            end
        end

        if (rd_valid_q) begin
            case (rd_word_q)
                2'd0:    lv_a <= level_q;
                2'd1:    lv_b <= level_q;
                2'd2:    lv_c <= level_q;
                default: lv_d <= level_q;
            endcase
        end

        lvl_interp <= rd_valid_q && (rd_word_q == 2'd3);

        if (lvl_interp) begin
            lo_r <= lo_w[13:0];
            hi_r <= hi_w[13:0];
            missing_r <=
                (lv_a == L_MISSING) || (lv_b == L_MISSING) ||
                (lv_c == L_MISSING) || (lv_d == L_MISSING);
        end

        lvl_wr <= lvl_interp;

        if (lvl_wr) begin
            ld_we   <= voice_onehot;
            ld_addr <= {slot, W_BP0 + point};
            ld_data <= {20'd0, level_out};
            if (point == 5'd20) begin
                point <= 5'd0;
                slot  <= slot + 1'b1;
            end
            else begin
                point <= point + 1'b1;
            end
        end

        /* ------------------------------------------------
         * Slot stream: frequency and header words
         * ------------------------------------------------ */

        case (hstate)
            H_R0: hstate <= H_R1;
            H_R1: begin
                ratio_a <= ratio_q;
                hstate  <= H_R2;
            end
            H_R2: begin
                if ((ratio_a == 20'd0) || (ratio_q == 20'd0))
                    ratio_r <= 20'd0;
                else
                    ratio_r <= ratio_w[19:0];
                hstate <= H_R3;
            end
            H_R3: begin
                inc_prod <= inc0_r * ratio_r;
                hstate   <= H_W0;
            end
            H_W0: if (!lvl_wr) begin
                ld_we   <= voice_onehot;
                ld_addr <= {hslot, W_INC};
                ld_data <= {4'd0, inc_prod[46:19]};
                hstate  <= H_W1;
            end
            H_W1: if (!lvl_wr) begin
                ld_we   <= voice_onehot;
                ld_addr <= {hslot, W_PHASE};
                ld_data <= 32'd0;
                hstate  <= H_W2;
            end
            H_W2: if (!lvl_wr) begin
                ld_we   <= voice_onehot;
                ld_addr <= {hslot, W_LEVEL};
                ld_data <= {6'd0, L_INIT};
                hstate  <= H_W3;
            end
            H_W3: if (!lvl_wr) begin
                ld_we   <= voice_onehot;
                ld_addr <= {hslot, W_SLOPE};
                ld_data <= 32'd0;
                if (hslot == 4'd15) begin
                    hstate <= H_END;
                end
                else begin
                    hslot  <= hslot + 1'b1;
                    hstate <= H_R0;
                end
            end
            default: ;
        endcase

        /* ------------------------------------------------
         * Note sequencer
         * ------------------------------------------------ */

        case (state)
            S_IDLE: begin
                if (req_valid) begin
                    voice_r <= req_voice;
                    note_r  <= req_note;
                    vel_r   <= req_velocity;
                    inc0_r  <= req_inc0;
                    state   <= S_PREP;
                end
            end
            S_PREP: begin
                ptr0     <= base0;
                ptr1     <= base0 + 15'd336;
                ptr2     <= base0 + 15'd1008;
                ptr3     <= base0 + 15'd1344;
                slot     <= 4'd0;
                point    <= 5'd0;
                hslot    <= 4'd0;
                rd_count <= 11'd0;
                state    <= S_WAIT;
            end
            /* The voice may still fade out an old note */
            S_WAIT: begin
                ld_rel_slope <= note_q;
                if (voice_ready[voice_r]) begin
                    hstate <= H_R0;
                    state  <= S_RUN;
                end
            end
            S_RUN: begin
                if ((rd_count == RD_TOTAL) && (hstate == H_END) &&
                    !rd_valid_q && !lvl_interp && !lvl_wr)
                    state <= S_DONE;
            end
            S_DONE: begin
                ld_done <= voice_onehot;
                state   <= S_IDLE;
            end
            default: state <= S_IDLE;
        endcase

    end

end

endmodule
