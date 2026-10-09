`default_nettype none
// Two ADCs share mode-0 SCLK/DIN/CS; their DOUT pins remain separate.
// DS21298E fig6-1: 24 clocks, null on rise12, B11..B0 on rises13..24.
module mcp3208_dual_reader #(
    parameter integer CLK_HZ = 50000000,
    parameter integer SPI_HZ = 1000000,
    parameter integer CS_HIGH_NS = 1000,
    parameter integer DOUT_DELAY_NS = 200
)(
    input wire clk, rst_n,
    input wire request_valid,
    output wire request_ready,
    input wire [2:0] request_channel,
    output reg result_valid,
    input wire result_ready,
    output reg [2:0] result_channel,
    output reg [11:0] result_adc0, result_adc1,
    output reg [1:0] result_error,
    output wire busy,
    output reg adc_cs_n, adc_sclk, adc_din,
    input wire adc0_dout, adc1_dout
);
    localparam integer HALF = (CLK_HZ + 2*SPI_HZ-1)/(2*SPI_HZ);
    localparam integer GAP = integer'((64'(CLK_HZ)*64'(CS_HIGH_NS)+999999999)/1000000000);
    localparam integer DELAY_CYCLES = integer'((64'(CLK_HZ)*64'(DOUT_DELAY_NS)+999999999)/1000000000);
    localparam integer HW = (HALF>1)?$clog2(HALF):1;
    localparam integer GW = (GAP>1)?$clog2(GAP+1):1;
    localparam integer HALF_LAST=HALF-1;
    localparam [HW-1:0] HALF_LIMIT=HALF_LAST[HW-1:0];
    localparam [GW-1:0] GAP_LOAD=GAP[GW-1:0];
    localparam [1:0] IDLE=0, SHIFT=1, HOLD_CS=2;
    reg [1:0] state;
    reg [HW-1:0] half_count;
    reg [GW-1:0] gap_count;
    reg [4:0] bit_index;
    reg [22:0] tx_shift; // first leading zero is already on DIN at CS assertion
    reg [11:0] rx0, rx1;
    reg [1:0] error_work;
    reg [2:0] channel_work;
    // Timing checks below require enough low/high time for this two-flop path.
    (* ASYNC_REG = "TRUE" *) reg [1:0] miso_meta, miso_sync;
    assign busy = state != IDLE;
    assign request_ready = (state==IDLE) && !result_valid && (gap_count==0);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin miso_meta<=0; miso_sync<=0; end
        else begin miso_meta<={adc1_dout,adc0_dout}; miso_sync<=miso_meta; end
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state<=IDLE; half_count<=0; gap_count<=GAP_LOAD;
            bit_index<=0; tx_shift<=0; rx0<=0; rx1<=0; error_work<=0; channel_work<=0;
            result_valid<=0; result_channel<=0; result_adc0<=0; result_adc1<=0; result_error<=0;
            adc_cs_n<=1; adc_sclk<=0; adc_din<=0;
        end else begin
            if(result_valid && result_ready) result_valid<=0;
            case(state)
                IDLE: begin
                    if(gap_count!=0) gap_count<=gap_count-1'b1;
                    if(request_valid && request_ready) begin
                        channel_work<=request_channel;
                        tx_shift<={4'b0000,1'b1,1'b1,request_channel,14'b0};
                        rx0<=0; rx1<=0; error_work<=0; bit_index<=0; half_count<=0;
                        adc_cs_n<=0; adc_din<=0; state<=SHIFT;
                    end
                end
                SHIFT: begin
                    if(half_count==HALF_LIMIT) begin
                        half_count<=0;
                        if(!adc_sclk) begin
                            adc_sclk<=1;
                            if(bit_index==5'd11) error_work<=miso_sync; // null must be zero
                            if(bit_index>=5'd12) begin
                                rx0<={rx0[10:0],miso_sync[0]};
                                rx1<={rx1[10:0],miso_sync[1]};
                            end
                        end else begin
                            adc_sclk<=0;
                            if(bit_index==5'd23) begin state<=HOLD_CS; adc_din<=0; end
                            else begin
                                bit_index<=bit_index+1'b1;
                                tx_shift<={tx_shift[21:0],1'b0}; adc_din<=tx_shift[22];
                            end
                        end
                    end else half_count<=half_count+1'b1;
                end
                HOLD_CS: begin
                    if(half_count==HALF_LIMIT) begin
                        adc_cs_n<=1; half_count<=0; gap_count<=GAP_LOAD; state<=IDLE;
                        result_channel<=channel_work; result_adc0<=rx0; result_adc1<=rx1;
                        result_error<=error_work; result_valid<=1;
                    end else half_count<=half_count+1'b1;
                end
                default: begin state<=IDLE; adc_cs_n<=1; adc_sclk<=0; adc_din<=0; end
            endcase
        end
    end
`ifndef SYNTHESIS
    initial begin
        if(CLK_HZ<=0 || SPI_HZ<10000 || SPI_HZ>1000000 || CS_HIGH_NS<500 || DOUT_DELAY_NS<200)
            $fatal(1,"MCP3208 conservative2.7..3.3V profile:10k..1MHz, CS high>=500ns, tDO>=200ns");
        if(HALF<DELAY_CYCLES+3 || 64'(HALF)*1000000000 < 64'(CLK_HZ)*250)
            $fatal(1,"MCP3208 divider lacks output-delay/synchronizer or250ns pulse margin");
        if(64'(CLK_HZ)<64'(2*HALF)*10000)
            $fatal(1,"MCP3208 rounded divider below10kHz conversion clock");
    end
`endif
endmodule
`default_nettype wire
