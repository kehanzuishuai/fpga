"""Pipelined piano note loader (32-key latency, user approval 2026-10-24).

Before: one shared loader walks 16 slots x (8 frequency clocks + 21 level
points x 7 clocks) = 2480 clocks per note (0.2 ms at 12.288 MHz); 32 keys
pressed together wait 6.5 ms for their last voice.
After: the level ROM is read on every clock (ptr0..ptr3 in turn, 4 clocks per
point), the point's interpolation is pipelined behind the reads, and each
slot's frequency and header words come from a small slot sequencer that runs
alongside and writes when the level stream does not. About 1350 clocks per
note. The interpolation arithmetic is untouched; every word written to the
voice RAM is the same as before. The voice clears its audibility record on the
write to address 0 (slot 0, W_INC): that write happens on clock 4 of S_RUN,
the first level point on clock 6, so the record collects the same bits.
Apply to src/piano_note_loader.v. Idempotent.
"""
from pathlib import Path
import sys

HEADER_OLD = ' * One note takes about 2500 clk cycles (0.2 ms at 12.288 MHz).\n'
HEADER_NEW = (' * One note takes about 1350 clk cycles (0.11 ms at 12.288 MHz): the\n'
              ' * level ROM is read on every clock (tools/loader_pipeline_20261024.py).\n')

STATES_OLD = '''localparam [4:0] S_IDLE = 5'd0;
localparam [4:0] S_PREP = 5'd1;
localparam [4:0] S_WAIT = 5'd2;
localparam [4:0] S_R0   = 5'd3;
localparam [4:0] S_R1   = 5'd4;
localparam [4:0] S_R2   = 5'd5;
localparam [4:0] S_R3   = 5'd6;
localparam [4:0] S_R4   = 5'd7;
localparam [4:0] S_R5   = 5'd8;
localparam [4:0] S_R6   = 5'd9;
localparam [4:0] S_R7   = 5'd10;
localparam [4:0] S_L0   = 5'd11;
localparam [4:0] S_L1   = 5'd12;
localparam [4:0] S_L2   = 5'd13;
localparam [4:0] S_L3   = 5'd14;
localparam [4:0] S_L4   = 5'd15;
localparam [4:0] S_L5   = 5'd16;
localparam [4:0] S_L6   = 5'd17;
localparam [4:0] S_DONE = 5'd18;

reg [4:0] state;

assign busy = (state != S_IDLE);
'''
STATES_NEW = '''localparam [2:0] S_IDLE = 3'd0;
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
'''

MUX_OLD = '''    case (state)
        S_L1:    level_addr = ptr1;
        S_L2:    level_addr = ptr2;
        S_L3:    level_addr = ptr3;
        default: level_addr = ptr0;
    endcase

    if (state == S_R1)
        ratio_addr = {grid_j1, slot};
    else
        ratio_addr = {grid_j, slot};
'''
MUX_NEW = '''    case (rd_count[1:0])
        2'd1:    level_addr = ptr1;
        2'd2:    level_addr = ptr2;
        2'd3:    level_addr = ptr3;
        default: level_addr = ptr0;
    endcase

    if (hstate == H_R1)
        ratio_addr = {grid_j1, hslot};
    else
        ratio_addr = {grid_j, hslot};
'''

SEQ_ANCHOR = "assign voice_onehot = {{(VOICES-1){1'b0}}, 1'b1} << voice_r;\n"
SEQ_NEW = '''

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

'''


def convert(s):
    if 'tools/loader_pipeline_20261024.py' in s:
        return s
    for old, new in ((HEADER_OLD, HEADER_NEW), (STATES_OLD, STATES_NEW), (MUX_OLD, MUX_NEW)):
        assert s.count(old) == 1, old[:60]
        s = s.replace(old, new)
    assert s.count(SEQ_ANCHOR) == 1 and s.count('\nendmodule') == 1
    head, rest = s.split(SEQ_ANCHOR)
    body, tail = rest.split('\nendmodule')
    assert body.strip().startswith('always @(posedge clk or negedge rst_n) begin')
    assert 'S_L6: begin' in body and 'S_DONE: begin' in body
    return head + SEQ_ANCHOR + SEQ_NEW + 'endmodule' + tail


def rewrite(path):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    s = raw.decode('utf-8').replace('\r\n', '\n')
    t = convert(s)
    if t != s:
        path.write_bytes((t.replace('\n', '\r\n') if crlf else t).encode('utf-8'))
        print('updated', path)
    else:
        print('unchanged', path)


if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    rewrite(root / 'src/piano_note_loader.v')
