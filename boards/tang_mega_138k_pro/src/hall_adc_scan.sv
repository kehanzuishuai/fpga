`default_nettype none
// Standalone front end. All logic uses clk; adc_sclk is an output, not an RTL clock.
module hall_adc_scan #(
    parameter integer CLK_HZ=50000000,
    parameter integer SPI_HZ=1000000,
    parameter integer CHANNELS=8,
    parameter integer KEY_RATE_HZ=2000,
    parameter integer CS_HIGH_NS=1000,
    parameter integer STALE_CYCLES=CLK_HZ/100,
    parameter integer AGE_W=(STALE_CYCLES>0)?$clog2(STALE_CYCLES+1):1
)(
    input wire clk, rst_n, enable,
    output wire adc_cs_n, adc_sclk, adc_din,
    input wire adc0_dout, adc1_dout,
    output wire [2*CHANNELS*12-1:0] key_values,
    output wire [2*CHANNELS-1:0] key_seen, key_updated, key_stale,
    output wire [2*CHANNELS*AGE_W-1:0] key_age_cycles,
    output wire [2*CHANNELS*32-1:0] key_timestamp,
    output wire [31:0] timestamp,
    output wire [1:0] protocol_error_sticky,
    output wire pair_valid,
    output wire [2:0] pair_channel,
    output wire [1:0] pair_error,
    output wire busy,
    output reg scan_done,
    output reg [31:0] scan_count
);
    localparam integer PERIOD=(CLK_HZ+KEY_RATE_HZ*CHANNELS-1)/(KEY_RATE_HZ*CHANNELS);
    localparam integer CW=(PERIOD>1)?$clog2(PERIOD):1;
    localparam integer PERIOD_LAST=PERIOD-1;
    localparam [CW-1:0] PERIOD_LIMIT=PERIOD_LAST[CW-1:0];
    localparam integer HALF=(CLK_HZ+2*SPI_HZ-1)/(2*SPI_HZ);
    localparam integer GAP=integer'((64'(CLK_HZ)*64'(CS_HIGH_NS)+999999999)/1000000000);
    reg [CW-1:0] cadence;
    reg [2:0] next_channel;
    wire request_ready;
    wire request_valid=enable && cadence==0;
    wire [11:0] pair_adc0,pair_adc1;
    mcp3208_dual_reader #(.CLK_HZ(CLK_HZ),.SPI_HZ(SPI_HZ),.CS_HIGH_NS(CS_HIGH_NS)) reader(
        .clk(clk),.rst_n(rst_n),.request_valid(request_valid),.request_ready(request_ready),
        .request_channel(next_channel),.result_valid(pair_valid),.result_ready(1'b1),
        .result_channel(pair_channel),.result_adc0(pair_adc0),.result_adc1(pair_adc1),
        .result_error(pair_error),.busy(busy),.adc_cs_n(adc_cs_n),.adc_sclk(adc_sclk),
        .adc_din(adc_din),.adc0_dout(adc0_dout),.adc1_dout(adc1_dout));
    hall_scan_store #(.CHANNELS(CHANNELS),.STALE_CYCLES(STALE_CYCLES),.AGE_W(AGE_W)) store(
        .clk(clk),.rst_n(rst_n),.pair_valid(pair_valid),.pair_channel(pair_channel),
        .pair_adc0(pair_adc0),.pair_adc1(pair_adc1),.pair_error(pair_error),
        .key_values(key_values),.key_seen(key_seen),.key_updated(key_updated),.key_stale(key_stale),
        .key_age_cycles(key_age_cycles),.key_timestamp(key_timestamp),.timestamp(timestamp),
        .protocol_error_sticky(protocol_error_sticky));
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin cadence<=0; next_channel<=0; scan_done<=0; scan_count<=0; end
        else begin
            scan_done<=0;
            if(cadence!=0) cadence<=cadence-1'b1;
            else if(request_valid && request_ready) cadence<=PERIOD_LIMIT;
            if(pair_valid) begin
                if(pair_channel==3'(CHANNELS-1)) begin
                    next_channel<=0; scan_done<=1; scan_count<=scan_count+1'b1;
                end else next_channel<=pair_channel+1'b1;
            end
        end
    end
`ifndef SYNTHESIS
    initial begin
        if(CHANNELS<1 || CHANNELS>8 || KEY_RATE_HZ<1 || PERIOD<49*HALF+GAP+5)
            $fatal(1,"hall_adc_scan requested cadence cannot fit one ADC transaction");
    end
`endif
endmodule
`default_nettype wire
