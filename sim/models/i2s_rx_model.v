`timescale 1ns/1ps

/* ============================================================
 * Receiver for standard (Philips) I2S, the way a DAC reads it.
 * Written from the I2S rule only; it knows nothing about the
 * transmitter.
 *
 *   - LRCK and DATA are read on the rising edge of BCK.
 *   - LRCK low = left, high = right.
 *   - The first rising edge that shows a new LRCK level still
 *     carries the last bit of the word before; the next rising
 *     edge carries the MSB of the new word.
 *
 * A word is everything between two LRCK changes, MSB first.
 * word_bits tells how many bits it had (32 expected).
 *
 * frame_event fires when a right word is complete; left_word
 * and right_word then hold one frame.
 *
 * The receiver starts as if LRCK had been high (idle level of
 * the transmitter), so that the very first frame is decoded.
 *
 * Besides decoding it measures the wire timing:
 *   bck_period_min/max   time between rising edges of BCK
 *   bck_high_min/max     high time of BCK
 *   setup_min            LRCK/DATA last change -> BCK rising
 *   hold_min             BCK rising -> next LRCK/DATA change
 *   bad_edge             LRCK/DATA changes that were not together
 *                        with a falling edge of BCK
 * ============================================================ */

module i2s_rx_model (
    input  wire bclk,
    input  wire lrck,
    input  wire data
);

reg  [31:0] left_word  = 32'd0;
reg  [31:0] right_word = 32'd0;

integer     left_bits  = 0;
integer     right_bits = 0;

event       frame_event;

integer     frames     = 0;
integer     bit_errors = 0;      /* words that were not 32 bits */

reg  [63:0] shift      = 64'd0;
integer     nbits      = 0;
reg         lrck_prev  = 1'b1;
reg         started    = 1'b0;

always @(posedge bclk) begin

    if (lrck !== lrck_prev) begin

        if (started) begin

            /* this bit is the last one of the word before */
            shift = {shift[62:0], data};
            nbits = nbits + 1;

            if (nbits != 32)
                bit_errors = bit_errors + 1;

            if (lrck_prev === 1'b0) begin
                left_word = shift[31:0];
                left_bits = nbits;
            end
            else begin
                right_word = shift[31:0];
                right_bits = nbits;
                frames     = frames + 1;
                -> frame_event;
            end

        end

        started   = 1'b1;
        shift     = 64'd0;
        nbits     = 0;
        lrck_prev = lrck;

    end

    else if (started) begin

        shift = {shift[62:0], data};
        nbits = nbits + 1;

    end

end


/* ------------------------------------------------------------
 * Wire timing
 * ------------------------------------------------------------ */

realtime t_rise      = -1.0;
realtime t_fall      = -1.0;
realtime t_change    = -1.0;

realtime bck_period_min = 1.0e12;
realtime bck_period_max = 0.0;
realtime bck_high_min   = 1.0e12;
realtime bck_high_max   = 0.0;
realtime setup_min      = 1.0e12;
realtime hold_min       = 1.0e12;

integer  bad_edge   = 0;
integer  bck_edges  = 0;

always @(posedge bclk) begin

    if (t_rise >= 0.0) begin
        if (($realtime - t_rise) < bck_period_min) bck_period_min = $realtime - t_rise;
        if (($realtime - t_rise) > bck_period_max) bck_period_max = $realtime - t_rise;
    end

    if ((t_change >= 0.0) && (($realtime - t_change) < setup_min))
        setup_min = $realtime - t_change;

    t_rise    = $realtime;
    bck_edges = bck_edges + 1;

end

always @(negedge bclk) begin

    if ((t_rise >= 0.0) && (bclk === 1'b0)) begin
        if (($realtime - t_rise) < bck_high_min) bck_high_min = $realtime - t_rise;
        if (($realtime - t_rise) > bck_high_max) bck_high_max = $realtime - t_rise;
    end

    t_fall = $realtime;

end

always @(lrck or data) begin

    if ((t_rise >= 0.0) && (($realtime - t_rise) < hold_min))
        hold_min = $realtime - t_rise;

    t_change = $realtime;

    /* the falling edge of BCK belongs to the same clock edge */
    #0.001;

    if (started && ((bclk !== 1'b0) || (($realtime - t_fall) > 0.002)))
        bad_edge = bad_edge + 1;

end


/*
 * Forget the stream (call it just before a reset of the
 * transmitter).  Counters and timing results are kept.
 */
task restart;
    begin
        started   = 1'b0;
        lrck_prev = 1'b1;
        nbits     = 0;
        shift     = 64'd0;
        t_rise    = -1.0;
        t_fall    = -1.0;
        t_change  = -1.0;
    end
endtask

endmodule
