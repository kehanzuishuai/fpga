`default_nettype none
// Philips I2S, signed MSB first. All state uses clk; BCLK is only an output.
// sample_valid atomically snapshots BOTH channels from the existing DAC's
// capture boundary. It is not a second synthesizer sample enable.
module pcm5102_i2s_tx #(
    parameter integer CLK_HZ = 12288000,
    parameter integer SAMPLE_RATE = 48000,
    parameter integer SAMPLE_W = 24,
    parameter integer SLOT_W = 32
)(
    input wire clk,
    input wire rst_n,
    input wire sample_valid,
    input wire signed [SAMPLE_W-1:0] left_sample,
    input wire signed [SAMPLE_W-1:0] right_sample,
    output reg bclk,
    output reg lrclk,
    output reg sdata
);
localparam integer HALF_DIV = CLK_HZ / (4 * SAMPLE_RATE * SLOT_W);
localparam integer DIV_W = (HALF_DIV <= 1) ? 1 : $clog2(HALF_DIV);
localparam integer BIT_W = $clog2(2 * SLOT_W);
localparam integer DIV_LAST_INT = HALF_DIV - 1;
localparam integer LEFT_LAST_INT = SLOT_W - 1;
localparam integer FRAME_LAST_INT = 2 * SLOT_W - 1;
localparam [DIV_W-1:0] DIV_LAST = DIV_LAST_INT[DIV_W-1:0];
localparam [BIT_W-1:0] LEFT_LAST = LEFT_LAST_INT[BIT_W-1:0];
localparam [BIT_W-1:0] FRAME_LAST = FRAME_LAST_INT[BIT_W-1:0];
reg [DIV_W-1:0] div_count;
reg [BIT_W-1:0] bit_index;
reg [SLOT_W-1:0] shift_word;
reg [SAMPLE_W-1:0] pending_left, pending_right, frame_right;

`ifndef SYNTHESIS
initial begin
    if (SAMPLE_W < 2 || SLOT_W < SAMPLE_W || SLOT_W < 2 ||
        HALF_DIV < 1 || CLK_HZ % (4*SAMPLE_RATE*SLOT_W) != 0)
        $fatal(1, "PCM5102A requires valid widths and an exact integer BCLK divider");
end
`endif

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pending_left <= {SAMPLE_W{1'b0}};
        pending_right <= {SAMPLE_W{1'b0}};
    end else if (sample_valid) begin
        pending_left <= left_sample;
        pending_right <= right_sample;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_count <= {DIV_W{1'b0}};
        bit_index <= FRAME_LAST;
        shift_word <= {SLOT_W{1'b0}};
        frame_right <= {SAMPLE_W{1'b0}};
        bclk <= 1'b0;
        lrclk <= 1'b1;
        sdata <= 1'b0;
    end else if (div_count == DIV_LAST) begin
        div_count <= {DIV_W{1'b0}};
        bclk <= ~bclk;
        if (bclk) begin
            // Change data/WS on FALLING BCLK, sampled by DAC on rising BCLK.
            // At each WS transition this bit still belongs to the OLD channel.
            sdata <= shift_word[SLOT_W-1];
            if (bit_index == FRAME_LAST) begin
                bit_index <= {BIT_W{1'b0}};
                lrclk <= 1'b0;
                shift_word <= {pending_left, {(SLOT_W-SAMPLE_W){1'b0}}};
                frame_right <= pending_right;
            end else begin
                bit_index <= bit_index + 1'b1;
                if (bit_index == LEFT_LAST) begin
                    lrclk <= 1'b1;
                    shift_word <= {frame_right, {(SLOT_W-SAMPLE_W){1'b0}}};
                end else
                    shift_word <= {shift_word[SLOT_W-2:0], 1'b0};
            end
        end
    end else
        div_count <= div_count + 1'b1;
end
endmodule
`default_nettype wire
