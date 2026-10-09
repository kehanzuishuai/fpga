`default_nettype none
// One shared iterative normalizer; calibration and Q4 IIR history remain per key.
// cfg has priority over samples. Both interfaces must hold valid/data until ready.
module hall_position_filter #(
    parameter integer KEYS=16,
    parameter integer KEY_W=(KEYS>1)?$clog2(KEYS):1,
    parameter integer FILTER_SHIFT=2,
    parameter integer MIN_SPAN=64
)(
    input wire clk,rst_n,
    input wire cfg_valid,
    output wire cfg_ready,
    input wire [KEY_W-1:0] cfg_key,
    input wire [11:0] cfg_rest,cfg_down,
    input wire [31:0] cfg_timestamp,
    input wire sample_valid,
    output wire sample_ready,
    input wire [KEY_W-1:0] sample_key,
    input wire [11:0] sample_raw,
    input wire sample_good,
    input wire [31:0] sample_timestamp,
    output reg position_valid,
    input wire position_ready,
    output reg [KEY_W-1:0] position_key,
    output reg [11:0] position,
    output reg position_good,
    output reg [31:0] position_timestamp,
    output reg [KEYS-1:0] calibrated
);
    reg [KEYS*12-1:0] rest;
    reg [KEYS*12-1:0] down;
    reg [KEYS*16-1:0] filtered;
    reg [KEYS-1:0] initialized;
    reg busy;
    reg [4:0] bits_left;
    reg [23:0] quotient;
    reg [12:0] remainder,divisor;
    wire available=!busy && (!position_valid || position_ready);
    assign cfg_ready=available;
    assign sample_ready=available && !cfg_valid;
    wire cfg_range={{(32-KEY_W){1'b0}},cfg_key}<KEYS;
    wire sample_range={{(32-KEY_W){1'b0}},sample_key}<KEYS;
    wire [11:0] cfg_span=(cfg_down>=cfg_rest)?cfg_down-cfg_rest:cfg_rest-cfg_down;
    localparam integer RAW_IW=$clog2(KEYS*12),FILTER_IW=$clog2(KEYS*16);
    wire [RAW_IW-1:0] sample12=({{(RAW_IW-KEY_W){1'b0}},sample_key}<<3)+({{(RAW_IW-KEY_W){1'b0}},sample_key}<<2);
    wire [RAW_IW-1:0] cfg12=({{(RAW_IW-KEY_W){1'b0}},cfg_key}<<3)+({{(RAW_IW-KEY_W){1'b0}},cfg_key}<<2);
    wire [FILTER_IW-1:0] sample16={{(FILTER_IW-KEY_W){1'b0}},sample_key}<<4;
    wire [15:0] raw_q4={sample_raw,4'b0000};
    wire signed [16:0] difference=$signed({1'b0,raw_q4})-$signed({1'b0,filtered[sample16 +: 16]});
    wire signed [16:0] filtered_next=$signed({1'b0,filtered[sample16 +: 16]})+(difference>>>FILTER_SHIFT);
    wire [15:0] chosen_q4=(!initialized[sample_key] || FILTER_SHIFT==0)?raw_q4:filtered_next[15:0];
    wire [11:0] chosen_raw=chosen_q4[15:4];
    wire rising=down[sample12 +: 12]>=rest[sample12 +: 12];
    wire [11:0] span=rising?down[sample12 +: 12]-rest[sample12 +: 12]:rest[sample12 +: 12]-down[sample12 +: 12];
    wire below=rising?(chosen_raw<=rest[sample12 +: 12]):(chosen_raw>=rest[sample12 +: 12]);
    wire above=rising?(chosen_raw>=down[sample12 +: 12]):(chosen_raw<=down[sample12 +: 12]);
    wire [11:0] delta=rising?chosen_raw-rest[sample12 +: 12]:rest[sample12 +: 12]-chosen_raw;
    // delta*4095 = (delta<<12)-delta, no multiplier/divider inference.
    wire [23:0] numerator={delta,12'd0}-{12'd0,delta};
    wire [12:0] shifted_remainder={remainder[11:0],quotient[23]};
    wire subtract=shifted_remainder>=divisor;
    wire [12:0] next_remainder=subtract?shifted_remainder-divisor:shifted_remainder;
    wire [23:0] next_quotient={quotient[22:0],subtract};
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            position_valid<=0;position_key<=0;position<=0;position_good<=0;position_timestamp<=0;
            calibrated<=0;initialized<=0;busy<=0;bits_left<=0;quotient<=0;remainder<=0;divisor<=0;
            rest<=0;down<=0;filtered<=0;
        end else begin
            if(position_valid && position_ready) position_valid<=0;
            if(busy) begin
                quotient<=next_quotient;remainder<=next_remainder;bits_left<=bits_left-1'b1;
                if(bits_left==1) begin
                    busy<=0;position<=next_quotient[11:0];position_valid<=1;
                end
            end else if(cfg_valid && cfg_ready) begin
                if(cfg_range) begin
                    rest[cfg12 +: 12]<=cfg_rest;down[cfg12 +: 12]<=cfg_down;
                    calibrated[cfg_key]<=cfg_span>=12'(MIN_SPAN);initialized[cfg_key]<=0;
                    // Configuration always invalidates/rearms downstream key state.
                    position_key<=cfg_key;position<=0;position_good<=0;position_timestamp<=cfg_timestamp;position_valid<=1;
                end
            end else if(sample_valid && sample_ready && sample_range) begin
                position_key<=sample_key;position_timestamp<=sample_timestamp;position<=0;
                position_good<=sample_good && calibrated[sample_key];
                if(!sample_good || !calibrated[sample_key]) begin
                    initialized[sample_key]<=0;position_valid<=1;
                end else begin
                    filtered[sample16 +: 16]<=chosen_q4;initialized[sample_key]<=1;
                    if(below || above) begin position<=above?12'd4095:12'd0;position_valid<=1;end
                    else begin
                        quotient<=numerator;remainder<=0;divisor<={1'b0,span};bits_left<=24;busy<=1;
                    end
                end
            end
        end
    end
`ifndef SYNTHESIS
    initial if(KEYS<1 || KEYS>32 || KEY_W<1 || KEY_W>5 || (2**KEY_W)<KEYS || FILTER_SHIFT<0 || FILTER_SHIFT>4 || MIN_SPAN<1 || MIN_SPAN>4095)
        $fatal(1,"hall_position_filter invalid parameters");
    // Convex Q4 IIR result must remain within ADC rails.
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin end
        else begin
            if(sample_valid && sample_ready && sample_range && initialized[sample_key] && filtered_next[16])
                $fatal(1,"filter range");
            if(busy && remainder[12]) $fatal(1,"divider remainder range");
        end
    end
`endif
endmodule
`default_nettype wire
