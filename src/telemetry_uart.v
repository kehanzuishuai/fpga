
module telemetry_uart #(
    parameter CLK_HZ        = 12000000,
    parameter BAUD          = 115200,
    parameter VOICE_COUNT_W = 6,
    parameter SAMPLE_W      = 24
)(
    input                              clk,
    input                              rst_n,
    input                              report_strobe,
    input      [VOICE_COUNT_W-1:0]     active_voice_count,
    input      [SAMPLE_W-1:0]          audio_peak,
    input signed [SAMPLE_W-1:0]        pcm_sample,
    output                             tx,
    output                             busy
);

wire tx_ready;
reg  tx_valid;
reg  [7:0] tx_data;
reg  [3:0] index;
reg  [7:0] checksum;
reg  [7:0] active_count_byte;

/* Frame snapshot registers: one report = one consistent time snapshot. */
reg [7:0]  active_latched;
reg [23:0] peak_latched;
reg [23:0] pcm_latched;

always @(*) begin
    active_count_byte = {{(8-VOICE_COUNT_W){1'b0}}, active_voice_count};
end

uart_tx #(
    .CLK_HZ(CLK_HZ),
    .BAUD  (BAUD)
) u_tx (
    .clk   (clk),
    .rst_n (rst_n),
    .valid (tx_valid),
    .data  (tx_data),
    .ready (tx_ready),
    .tx    (tx)
);

assign busy = (index != 4'd0) || tx_valid || !tx_ready;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        index          <= 4'd0;
        tx_valid       <= 1'b0;
        tx_data        <= 8'd0;
        checksum       <= 8'd0;
        active_latched <= 8'd0;
        peak_latched   <= 24'd0;
        pcm_latched    <= 24'd0;
    end
    else begin
        if ((index == 4'd0) && report_strobe) begin
            active_latched <= active_count_byte;
            peak_latched   <= audio_peak[23:0];
            pcm_latched    <= pcm_sample[23:0];

            checksum <= 8'hA5 ^
                        8'h01 ^
                        active_count_byte ^
                        audio_peak[23:16] ^
                        audio_peak[15:8] ^
                        audio_peak[7:0] ^
                        pcm_sample[23:16] ^
                        pcm_sample[15:8] ^
                        pcm_sample[7:0];

            index <= 4'd1;
        end

        if (!tx_valid && (index != 4'd0)) begin
            tx_valid <= 1'b1;
            case (index)
                4'd1: tx_data <= 8'hA5;
                4'd2: tx_data <= 8'h01;
                4'd3: tx_data <= active_latched;
                4'd4: tx_data <= peak_latched[23:16];
                4'd5: tx_data <= peak_latched[15:8];
                4'd6: tx_data <= peak_latched[7:0];
                4'd7: tx_data <= pcm_latched[23:16];
                4'd8: tx_data <= pcm_latched[15:8];
                4'd9: tx_data <= pcm_latched[7:0];
                default: tx_data <= checksum;
            endcase
        end
        else if (tx_valid && tx_ready) begin
            tx_valid <= 1'b0;
            if (index == 4'd10)
                index <= 4'd0;
            else
                index <= index + 1'b1;
        end
    end
end

endmodule
