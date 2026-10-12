

module audio_telemetry #(
    parameter VOICES      = 32,
    parameter SAMPLE_W    = 24,
    parameter DECIMATE    = 48,
    parameter COUNT_W     = 6,
    parameter PEAK_WINDOW = 2400
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,
    input      [VOICES-1:0]            active_voices,
    input signed [SAMPLE_W-1:0]        audio,
    output reg [COUNT_W-1:0]           active_voice_count,
    output reg [SAMPLE_W-1:0]          audio_peak,
    output reg                         pcm_strobe,
    output reg signed [SAMPLE_W-1:0]   pcm_sample
);

function integer clog2;
    input integer value;
    integer temp;
    begin
        temp = value - 1;
        clog2 = 0;
        while (temp > 0) begin
            temp = temp >> 1;
            clog2 = clog2 + 1;
        end
    end
endfunction

localparam DW  = (DECIMATE <= 1) ? 1 : clog2(DECIMATE);
localparam PCW = (PEAK_WINDOW <= 1) ? 1 : clog2(PEAK_WINDOW);

localparam [DW-1:0]  DECIM_LAST = DECIMATE - 1;
localparam [PCW-1:0] PEAK_LAST  = PEAK_WINDOW - 1;

reg [DW-1:0] decim_count;
reg [PCW-1:0] peak_count;
reg [SAMPLE_W-1:0] peak_work;
reg [SAMPLE_W-1:0] abs_audio;

integer i;

always @(*) begin
    active_voice_count = {COUNT_W{1'b0}};
    for (i = 0; i < VOICES; i = i + 1)
        active_voice_count = active_voice_count + active_voices[i];

    if (audio[SAMPLE_W-1])
        abs_audio = -audio;
    else
        abs_audio = audio;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        audio_peak  <= {SAMPLE_W{1'b0}};
        peak_work   <= {SAMPLE_W{1'b0}};
        peak_count  <= {PCW{1'b0}};
        decim_count <= {DW{1'b0}};
        pcm_strobe  <= 1'b0;
        pcm_sample  <= {SAMPLE_W{1'b0}};
    end
    else begin
        pcm_strobe <= 1'b0;

        if (sample_tick) begin
            /* Windowed peak: publish one completed window, then restart. */
            if (peak_count == PEAK_LAST) begin
                if (abs_audio > peak_work)
                    audio_peak <= abs_audio;
                else
                    audio_peak <= peak_work;

                peak_work  <= {SAMPLE_W{1'b0}};
                peak_count <= {PCW{1'b0}};
            end
            else begin
                if (abs_audio > peak_work)
                    peak_work <= abs_audio;
                peak_count <= peak_count + 1'b1;
            end

            if (decim_count == DECIM_LAST) begin
                decim_count <= {DW{1'b0}};
                pcm_strobe  <= 1'b1;
                pcm_sample  <= audio;
            end
            else begin
                decim_count <= decim_count + 1'b1;
            end
        end
    end
end

endmodule


