`timescale 1ns/1ps

/* ============================================================
 * TTP229-BSF 2-wire serial behavioural model (simulation only)
 *
 * Based on the Tontek TTP229-BSF specification V1.1:
 *
 *   TP2 (KYSEL) open  -> 8 key mode  (KEY16 = 0, module default)
 *   TP2 to VSS        -> 16 key mode (KEY16 = 1)
 *   TP3/TP4 open      -> single key  (MULTI = 0, module default)
 *   TP3/TP4 to VSS    -> multi key   (MULTI = 1)
 *   TP1 open          -> SCL/SDO active low (the only mode modelled)
 *
 *   DV    = 93 us  data-valid pulse on SDO after a key change
 *   Tout  = 2 ms   no SCL edge -> interface returns to stand-by
 *   F_SCL = 1 kHz .. 512 kHz
 *
 * Data bit Dn is driven on the (n+1)-th falling edge of SCL and
 * held until the next falling edge.  Active low: pressed = 0.
 *
 * ASSUMPTION (not stated in the specification): in 8 key mode the
 * bit counter wraps after D7, so a host that sends 16 clocks reads
 * D0..D7 twice.  This matches the "upper 8 bits repeat the lower
 * 8 bits" symptom seen on the board; it has to be confirmed there.
 * ============================================================ */

module ttp229_bfm #(
    parameter KEY16   = 1,
    parameter MULTI   = 1,
    parameter DV_EN   = 1,
    parameter DV_NS   = 93000,
    parameter TOUT_NS = 2000000
)(
    input  wire [15:0] touch,
    input  wire        scl,
    output reg         sdo
);

localparam NBITS = (KEY16 != 0) ? 16 : 8;

reg [15:0] keys;
reg [15:0] keys_latched;
reg [15:0] single_mask;
integer    bit_cnt;
integer    k;
reg        in_burst;
reg        dv_active;
time       last_edge;

initial begin
    sdo          = 1'b1;
    keys         = 16'd0;
    keys_latched = 16'd0;
    single_mask  = 16'd0;
    bit_cnt      = 0;
    in_burst     = 1'b0;
    dv_active    = 1'b0;
    last_edge    = 0;
end

/* ------------------------------------------------------------
 * Key detection: 8/16 key mask, single/multi key
 * ------------------------------------------------------------ */

reg [15:0] masked;

always @(*) begin
    masked = (KEY16 != 0) ? touch : {8'h00, touch[7:0]};
end

always @(masked) begin
    if (MULTI != 0) begin
        keys = masked;
    end
    else begin
        /* Single key: keep the key already reported while it is
         * still touched, otherwise report the lowest touched pad. */
        if ((single_mask & masked) == 16'd0) begin
            single_mask = 16'd0;
            for (k = 15; k >= 0; k = k - 1)
                if (masked[k])
                    single_mask = 16'd1 << k;
        end
        keys = single_mask & masked;
    end
end

/* ------------------------------------------------------------
 * DV pulse on key change while the interface is idle
 * ------------------------------------------------------------ */

always @(keys) begin
    if ((DV_EN != 0) && !in_burst && ($time > 0)) begin
        dv_active = 1'b1;
        sdo       = 1'b0;
        #(DV_NS);
        if (dv_active) begin
            dv_active = 1'b0;
            if (!in_burst)
                sdo = 1'b1;
        end
    end
end

/* ------------------------------------------------------------
 * Serial shift
 * ------------------------------------------------------------ */

always @(negedge scl) begin
    last_edge = $time;

    if (!in_burst) begin
        in_burst     = 1'b1;
        dv_active    = 1'b0;
        keys_latched = keys;
        bit_cnt      = 0;
    end

    sdo = ~keys_latched[bit_cnt];

    if (bit_cnt == NBITS - 1)
        bit_cnt = 0;
    else
        bit_cnt = bit_cnt + 1;
end

always @(posedge scl) begin
    last_edge = $time;
end

/* Timeout: SCL quiet for Tout -> stand-by, SDO idle high */
always begin
    #(50000);
    if (in_burst && (($time - last_edge) >= TOUT_NS)) begin
        in_burst = 1'b0;
        bit_cnt  = 0;
        if (!dv_active)
            sdo = 1'b1;
    end
end

endmodule
