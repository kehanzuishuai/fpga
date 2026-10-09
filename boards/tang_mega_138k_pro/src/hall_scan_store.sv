`default_nettype none
// Raw voltages only: no calibration, filtering, key/velocity or note decisions.
// Key0..CHANNELS-1=ADC0, keyCHANNELS..2*CHANNELS-1=ADC1.
module hall_scan_store #(
    parameter integer CHANNELS=8,
    parameter integer STALE_CYCLES=500000,
    parameter integer AGE_W=(STALE_CYCLES>0)?$clog2(STALE_CYCLES+1):1
)(
    input wire clk, rst_n,
    input wire pair_valid,
    input wire [2:0] pair_channel,
    input wire [11:0] pair_adc0, pair_adc1,
    input wire [1:0] pair_error,
    output reg [2*CHANNELS*12-1:0] key_values,
    output reg [2*CHANNELS-1:0] key_seen, key_updated,
    output wire [2*CHANNELS-1:0] key_stale,
    output reg [2*CHANNELS*AGE_W-1:0] key_age_cycles,
    output reg [2*CHANNELS*32-1:0] key_timestamp,
    output reg [31:0] timestamp,
    output reg [1:0] protocol_error_sticky
);
    integer i;
    localparam [AGE_W-1:0] STALE_LIMIT=STALE_CYCLES[AGE_W-1:0];
    localparam integer INDEX_W=$clog2(2*CHANNELS);
    localparam [INDEX_W-1:0] ADC1_BASE=CHANNELS[INDEX_W-1:0];
    wire [INDEX_W-1:0] key0_index,key1_index;
    wire channel_in_range;
    genvar k;
    generate
        if(INDEX_W>=3)begin: wide_key_index
            assign key0_index={{(INDEX_W-3){1'b0}},pair_channel};
        end else begin: narrow_key_index
            assign key0_index=pair_channel[INDEX_W-1:0];
        end
        if(CHANNELS==8)begin: full_channel_range
            assign channel_in_range=1'b1;
        end else begin: limited_channel_range
            assign channel_in_range={1'b0,pair_channel}<4'(CHANNELS);
        end
    endgenerate
    assign key1_index=key0_index+ADC1_BASE;
    generate for(k=0;k<2*CHANNELS;k=k+1) begin: stale_flags
        assign key_stale[k]=!key_seen[k] || key_age_cycles[k*AGE_W +: AGE_W]>=STALE_LIMIT;
    end endgenerate
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            key_values<=0; key_seen<=0; key_updated<=0; key_age_cycles<=0;
            key_timestamp<=0; timestamp<=0; protocol_error_sticky<=0;
        end else begin
            timestamp<=timestamp+1'b1; key_updated<=0;
            for(i=0;i<2*CHANNELS;i=i+1) begin
                if(key_age_cycles[i*AGE_W +: AGE_W]<STALE_LIMIT)
                    key_age_cycles[i*AGE_W +: AGE_W]<=key_age_cycles[i*AGE_W +: AGE_W]+1'b1;
            end
            if(pair_valid) begin
                protocol_error_sticky<=protocol_error_sticky | pair_error;
                if(channel_in_range) begin
                    if(!pair_error[0]) begin
                        key_values[12*{29'd0,pair_channel} +: 12]<=pair_adc0;
                        key_seen[key0_index]<=1; key_updated[key0_index]<=1;
                        key_age_cycles[AGE_W*{29'd0,pair_channel} +: AGE_W]<=0;
                        key_timestamp[32*{29'd0,pair_channel} +: 32]<=timestamp;
                    end
                    if(!pair_error[1]) begin
                        key_values[12*(CHANNELS+{29'd0,pair_channel}) +: 12]<=pair_adc1;
                        key_seen[key1_index]<=1; key_updated[key1_index]<=1;
                        key_age_cycles[AGE_W*(CHANNELS+{29'd0,pair_channel}) +: AGE_W]<=0;
                        key_timestamp[32*(CHANNELS+{29'd0,pair_channel}) +: 32]<=timestamp;
                    end
                end
            end
        end
    end
`ifndef SYNTHESIS
    initial if(CHANNELS<1 || CHANNELS>8 || STALE_CYCLES<1 || AGE_W>32 || AGE_W<$clog2(STALE_CYCLES+1))
        $fatal(1,"hall_scan_store invalid dimensions");
`endif
endmodule
`default_nettype wire
