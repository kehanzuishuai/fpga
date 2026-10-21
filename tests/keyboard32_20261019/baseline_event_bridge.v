module baseline_event_bridge #(
    /*
     * Note of key 1 when USE_NOTE_TABLE = 0.
     * Key n plays BASE_NOTE + (n - 1): 16 semitones, MIDI 60..75.
     */
    parameter [6:0] BASE_NOTE = 7'd60,

    /*
     * 1: the note of key n is NOTE_TABLE[(n-1)*7 +: 7]
     */
    parameter USE_NOTE_TABLE = 0,

    parameter [16*7-1:0] NOTE_TABLE = {
        7'd75, 7'd74, 7'd73, 7'd72,
        7'd71, 7'd70, 7'd69, 7'd68,
        7'd67, 7'd66, 7'd65, 7'd64,
        7'd63, 7'd62, 7'd61, 7'd60
    },

    /*
     * The TTP229 has no force sensing.  Every Note On carries this
     * velocity unless USE_VELOCITY_IN = 1.
     */
    parameter [7:0] VELOCITY = 8'd100,

    /*
     * 1: velocity_in is sampled when the Note On is created
     *    (test injection, later a real keyboard)
     */
    parameter USE_VELOCITY_IN = 0
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        frame_valid,
    input  wire [15:0] key_state,

    input  wire [7:0]  velocity_in,

    input  wire        event_ready,

    output reg         event_valid,
    output reg         event_note_on,
    output reg  [6:0]  event_note,

    output reg  [7:0]  event_velocity,

    /* Compatibility only: the piano engine ignores the waveform. */
    output wire [1:0]  event_waveform,

    /* Key that produced the event, 0 = key 1 */
    output reg  [3:0]  event_key_index,

    /* Keys the synthesizer has been told are down */
    output reg  [15:0] reported_state
);


assign event_waveform = 2'd3;


/* ============================================================
 * Event scheduler
 *
 * The bridge compares what the keyboard shows (key_state) with
 * what the synthesizer has been told (reported_state) and sends
 * one event per differing key.
 *
 * - every key has its own bit, keys never merge
 * - a Note Off can not be lost: as long as a key differs, its
 *   event stays due, however long event_ready is low
 * - a key that went down and up again before its Note On left
 *   produces nothing instead of an On followed by a stray Off
 * - Note Off goes first, so voices are freed before they are
 *   requested again
 * ============================================================ */

wire [15:0] need_off;
wire [15:0] need_on;

assign need_off =  reported_state & ~key_state;
assign need_on  = ~reported_state &  key_state;


function [4:0] first_one16;

    input [15:0] value;

    integer k;

    begin

        first_one16 = 5'd16;

        for (k = 15; k >= 0; k = k - 1)
            if (value[k])
                first_one16 = k;

    end

endfunction


wire [4:0] off_index;
wire [4:0] on_index;

assign off_index = first_one16(need_off);
assign on_index  = first_one16(need_on);

wire       pick_valid;
wire       pick_on;
wire [3:0] pick_index;

assign pick_valid = (need_off != 16'd0) || (need_on != 16'd0);
assign pick_on    = (need_off == 16'd0);
assign pick_index = pick_on ? on_index[3:0] : off_index[3:0];


wire [6:0] pick_note;

assign pick_note =
    (USE_NOTE_TABLE != 0)
    ?
    NOTE_TABLE[pick_index*7 +: 7]
    :
    (BASE_NOTE + {3'b000, pick_index});


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        reported_state  <= 16'd0;

        event_valid     <= 1'b0;
        event_note_on   <= 1'b0;
        event_note      <= 7'd0;
        event_velocity  <= VELOCITY;
        event_key_index <= 4'd0;

    end

    else begin

        /* Current event taken by the Note FIFO */
        if (event_valid && event_ready)
            event_valid <= 1'b0;


        /* Output register free: issue the next event */
        if ((!event_valid || event_ready) && pick_valid) begin

            event_valid     <= 1'b1;
            event_note_on   <= pick_on;
            event_note      <= pick_note;
            event_key_index <= pick_index;

            if (USE_VELOCITY_IN != 0)
                event_velocity <= velocity_in;
            else
                event_velocity <= VELOCITY;

            reported_state[pick_index] <= pick_on;

        end

    end

end


endmodule
