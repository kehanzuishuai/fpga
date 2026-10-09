`timescale 1ns/1ps
// Pin-level slave, not coupled to reader state. Data changes AFTER falling CLK.
module mcp3208_model #(
    parameter integer DOUT_NS=200,
    parameter integer HALF_NS_MIN=250
)(
    input wire rst_n,cs_n,sclk,din,
    input wire [8*12-1:0] analog_codes,
    input wire corrupt_null,
    output reg dout,
    output reg [2:0] decoded_channel,
    output integer completed
);
    integer rises;
    reg [2:0] channel;
    reg [11:0] captured;
    realtime last_din,cs_start,last_edge,cs_end;
    initial begin dout=1'bz; completed=0; rises=0; channel=0; captured=0;
        decoded_channel=0; last_din=-1000;cs_start=0;last_edge=0;cs_end=-1000;end
    always @(din) last_din=$realtime;
    always @(negedge cs_n) if(rst_n) begin
        if($realtime-cs_end<500) $fatal(1,"ADC CS high shorter than500ns");
        if(sclk!==0)$fatal(1,"ADC mode0 idle clock");
        rises=0; channel=0; cs_start=$realtime; last_edge=$realtime;
    end
    always @(posedge sclk) if(!cs_n && rst_n) begin
        if($realtime-last_din<50)$fatal(1,"ADC DIN setup violated");
        if(rises==0 && $realtime-cs_start<100)$fatal(1,"ADC CS setup violated");
        if($realtime-last_edge<HALF_NS_MIN)$fatal(1,"ADC low pulse too short");
        last_edge=$realtime; rises=rises+1;
        case(rises)
            1,2,3,4,5:if(din!==0)$fatal(1,"ADC leading zeros");
            6:if(din!==1)$fatal(1,"ADC missing start");
            7:if(din!==1)$fatal(1,"ADC not single ended");
            8,9,10:channel={channel[1:0],din};
            11:begin captured=analog_codes[12*{29'd0,channel} +: 12]; decoded_channel=channel; end
            default:begin end
        endcase
        if(rises>24)$fatal(1,"ADC unexpected extra clocks");
    end
    always @(negedge sclk) if(!cs_n && rst_n) begin
        if($realtime-last_edge<HALF_NS_MIN)$fatal(1,"ADC high pulse too short");
        last_edge=$realtime;
        if(rises==11)dout<=#DOUT_NS corrupt_null;
        else if(rises>=12 && rises<=23)dout<=#DOUT_NS captured[23-rises];
        else if(rises>=24)dout<=#DOUT_NS 1'b0;
    end
    always @(posedge cs_n) begin
        cs_end=$realtime;
        if(rst_n && rises!=0)begin
            if(rises!=24 || sclk!==0)$fatal(1,"ADC frame not exactly24 complete clocks");
            if($realtime-last_edge<50)$fatal(1,"ADC final DIN hold");
            completed=completed+1;
        end
        dout<=1'bz;
    end
endmodule
