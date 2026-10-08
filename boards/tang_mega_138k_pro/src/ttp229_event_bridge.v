module ttp229_event_bridge #(
    parameter [6:0] BASE_NOTE = 7'd60,
    parameter [7:0] VELOCITY  = 8'd100
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        frame_valid,
    input  wire [15:0] key_state,

    input  wire        event_ready,

    output reg         event_valid,
    output reg         event_note_on,
    output reg  [6:0]  event_note,

    output wire [7:0]  event_velocity,
    output reg  [1:0]  event_waveform
);


/* ============================================================
 * Fixed velocity
 * ============================================================ */

assign event_velocity = VELOCITY;


/* ============================================================
 * Timbre mapping
 *
 * Key 1 ~ 4   : sine
 * Key 5 ~ 8   : square
 * Key 9 ~ 12  : saw
 * Key 13 ~ 16 : piano
 * ============================================================ */

always @(*) begin

    case (event_note - BASE_NOTE)

        7'd0,
        7'd1,
        7'd2,
        7'd3:
            event_waveform = 2'd0;


        7'd4,
        7'd5,
        7'd6,
        7'd7:
            event_waveform = 2'd1;


        7'd8,
        7'd9,
        7'd10,
        7'd11:
            event_waveform = 2'd2;


        default:
            event_waveform = 2'd3;

    endcase

end


/* ============================================================
 * Previous key state
 * ============================================================ */

reg [15:0] prev_state;


/* ============================================================
 * Pending events
 * ============================================================ */

reg [15:0] pending_on;
reg [15:0] pending_off;


/* ============================================================
 * Next-state signals
 * ============================================================ */

reg [15:0] prev_state_n;

reg [15:0] pending_on_n;
reg [15:0] pending_off_n;

reg       event_valid_n;
reg       event_note_on_n;
reg [6:0] event_note_n;

reg       found;
reg       selected_on;
reg [3:0] selected_index;

integer i;


/* ============================================================
 * Event scheduler
 * ============================================================ */

always @(*) begin

    prev_state_n =
        prev_state;

    pending_on_n =
        pending_on;

    pending_off_n =
        pending_off;

    event_valid_n =
        event_valid;

    event_note_on_n =
        event_note_on;

    event_note_n =
        event_note;


    found =
        1'b0;

    selected_on =
        1'b0;

    selected_index =
        4'd0;


    /* --------------------------------------------------------
     * Detect key changes
     * -------------------------------------------------------- */

    if (frame_valid) begin

        pending_on_n =
            pending_on_n
            |
            (
                key_state
                &
                ~prev_state
            );


        pending_off_n =
            pending_off_n
            |
            (
                ~key_state
                &
                prev_state
            );


        prev_state_n =
            key_state;

    end


    /* --------------------------------------------------------
     * Current event accepted
     * -------------------------------------------------------- */

    if (
        event_valid_n
        &&
        event_ready
    ) begin

        event_valid_n =
            1'b0;

    end


    /* --------------------------------------------------------
     * Select next pending event
     * -------------------------------------------------------- */

    if (!event_valid_n) begin


        /* Note On priority */

        for (
            i = 0;
            i < 16;
            i = i + 1
        ) begin

            if (
                (!found)
                &&
                pending_on_n[i]
            ) begin

                found =
                    1'b1;

                selected_on =
                    1'b1;

                selected_index =
                    i;

            end

        end


        /* Note Off */

        if (!found) begin

            for (
                i = 0;
                i < 16;
                i = i + 1
            ) begin

                if (
                    (!found)
                    &&
                    pending_off_n[i]
                ) begin

                    found =
                        1'b1;

                    selected_on =
                        1'b0;

                    selected_index =
                        i;

                end

            end

        end


        /* ----------------------------------------------------
         * Create event
         * ---------------------------------------------------- */

        if (found) begin

            event_valid_n =
                1'b1;

            event_note_on_n =
                selected_on;


            event_note_n =
                BASE_NOTE
                +
                {
                    3'b000,
                    selected_index
                };


            if (selected_on) begin

                pending_on_n[selected_index] =
                    1'b0;

            end

            else begin

                pending_off_n[selected_index] =
                    1'b0;

            end

        end

    end

end


/* ============================================================
 * Registers
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        prev_state <=
            16'd0;

        pending_on <=
            16'd0;

        pending_off <=
            16'd0;

        event_valid <=
            1'b0;

        event_note_on <=
            1'b0;

        event_note <=
            7'd0;

    end

    else begin

        prev_state <=
            prev_state_n;

        pending_on <=
            pending_on_n;

        pending_off <=
            pending_off_n;

        event_valid <=
            event_valid_n;

        event_note_on <=
            event_note_on_n;

        event_note <=
            event_note_n;

    end

end


endmodule
