`timescale 1ns/1ps

/* ============================================================
 * Reproduces the keyboard symptoms with the reader + bridge of
 * the given source set (compile against the baseline copy or
 * against src/).  It only uses the ports both versions have.
 *
 * Prints every Note Event that leaves the bridge.
 *
 *   +define+KEY16=<0|1>  +define+MULTI=<0|1>
 * ============================================================ */

`ifndef KEY16
`define KEY16 0
`endif
`ifndef MULTI
`define MULTI 0
`endif

module tb_ttp229_baseline;

reg clk = 1'b0;
reg rst_n = 1'b0;

always #40.690 clk = ~clk;      /* 12.288 MHz */

reg  [15:0] touch = 16'd0;
wire        scl;
wire        sdo;

ttp229_bfm #(
    .KEY16 (`KEY16),
    .MULTI (`MULTI),
    .DV_EN (1)
) u_chip (
    .touch (touch),
    .scl   (scl),
    .sdo   (sdo)
);

wire [15:0] key_state;
wire        frame_valid;

ttp229_reader #(
    .HALF_TICKS (123),
    .GAP_TICKS  (36864),
    .ACTIVE_LOW (1)
) u_reader (
    .clk         (clk),
    .rst_n       (rst_n),
    .ttp229_scl  (scl),
    .ttp229_sdo  (sdo),
    .key_state   (key_state),
    .frame_valid (frame_valid)
);

wire       event_valid;
wire       event_note_on;
wire [6:0] event_note;
wire [7:0] event_velocity;
wire [1:0] event_waveform;

ttp229_event_bridge #(
    .BASE_NOTE (7'd60),
    .VELOCITY  (8'd100)
) u_bridge (
    .clk            (clk),
    .rst_n          (rst_n),
    .frame_valid    (frame_valid),
    .key_state      (key_state),
    .event_ready    (1'b1),
    .event_valid    (event_valid),
    .event_note_on  (event_note_on),
    .event_note     (event_note),
    .event_velocity (event_velocity),
    .event_waveform (event_waveform)
);

integer on_count  = 0;
integer off_count = 0;

always @(posedge clk) begin
    if (rst_n && event_valid) begin
        if (event_note_on) on_count  = on_count + 1;
        else               off_count = off_count + 1;

        $display("  t=%0.2f ms  %s  note %0d (key %0d)",
                 $time / 1.0e6,
                 event_note_on ? "NOTE ON " : "NOTE OFF",
                 event_note,
                 event_note - 59);
    end
end

task press_and_release;
    input [15:0] pads;
    begin
        on_count  = 0;
        off_count = 0;
        $display("touch pads %b", pads);
        touch = pads;
        #(20_000_000);
        touch = 16'd0;
        #(20_000_000);
        $display("  -> %0d Note On, %0d Note Off", on_count, off_count);
    end
endtask

initial begin
    $display("=== TTP229 model: KEY16=%0d MULTI=%0d ===", `KEY16, `MULTI);
    #(1000);
    rst_n = 1'b1;
    #(10_000_000);

    press_and_release(16'b0000_0000_0000_0001);    /* key 1          */
    press_and_release(16'b0000_0000_1000_0000);    /* key 8          */
    press_and_release(16'b0000_0001_0000_0000);    /* key 9          */
    press_and_release(16'b1000_0000_0000_0000);    /* key 16         */
    press_and_release(16'b0000_0000_1001_0101);    /* keys 1,3,5,8   */

    $finish;
end

endmodule
