`timescale 1ns/1ps
module tb_mcp3208_dual_reader;
    parameter integer CLK_HZ=50000000;
    parameter integer SPI_HZ=1000000;
    localparam integer HALF=(CLK_HZ+2*SPI_HZ-1)/(2*SPI_HZ);
    reg clk=0,rst_n=0,req=0,ready=0;
    always #(500000000.0/CLK_HZ)clk=~clk;
    reg [2:0] ch=0;
    wire request_ready,valid,busy,cs,sclk,din;
    wire [2:0] result_ch,c0,c1;
    wire [11:0] d0,d1;
    wire [1:0] err;
    wire miso0,miso1;
    reg [95:0] codes0=0,codes1=0;
    reg bad0=0,bad1=0;
    integer complete0,complete1,checked=0,t,k,j;
    reg [11:0] expected0,expected1;
    reg [1:0] expected_error;
    reg [28:0] held;
    integer system_cycles=0,last_spi_edge=-1,spi_edges=0;
    always @(posedge clk)system_cycles=system_cycles+1;
    always @(negedge cs)if(rst_n)last_spi_edge=system_cycles;
    always @(sclk)if(rst_n && !cs)begin
        if(last_spi_edge>=0 && system_cycles-last_spi_edge!=HALF)$fatal(1,"measured SPI half-period mismatch");
        last_spi_edge=system_cycles;spi_edges=spi_edges+1;
    end
    mcp3208_dual_reader #(.CLK_HZ(CLK_HZ),.SPI_HZ(SPI_HZ)) dut(
        clk,rst_n,req,request_ready,ch,valid,ready,result_ch,d0,d1,err,busy,cs,sclk,din,miso0,miso1);
    mcp3208_model m0(rst_n,cs,sclk,din,codes0,bad0,miso0,c0,complete0);
    mcp3208_model m1(rst_n,cs,sclk,din,codes1,bad1,miso1,c1,complete1);
    task reset_reader;
        begin @(negedge clk);rst_n=0;req=0;ready=0;
        #1;if(cs!==1 || sclk!==0 || valid!==0)$fatal(1,"reset outputs");
        repeat(5)@(negedge clk);rst_n=1;end
    endtask
    task transfer(input integer number);
        begin
            @(negedge clk);
            for(k=0;k<8;k=k+1)begin
                codes0[12*k +: 12]=12'((number*193+k*517)^32'h123);
                codes1[12*k +: 12]=12'((number*307+k*29)^32'hab5);
            end
            // Include exact rail and bit-order boundary values, which are legal.
            if(number<12)begin codes0[12*(number%8) +: 12]=(12'd1<<number);
                codes1[12*(number%8) +: 12]=~(12'd1<<number);end
            if(number==12)begin codes0=0;codes1={8{12'hfff}};end
            ch=3'(number%8);bad0=(number%13)==11;bad1=(number%17)==15;
            expected0=codes0[12*{29'd0,ch} +: 12];expected1=codes1[12*{29'd0,ch} +: 12];
            expected_error={bad1,bad0};req=1;
            while(!request_ready)@(negedge clk);
            @(negedge clk);req=0;
            // Change request payload while busy: it must not change this frame.
            ch=~ch;req=1;
            while(!valid)begin @(negedge clk);if(request_ready)$fatal(1,"accepted request while busy");end
            req=0;
            if(result_ch!==3'(number%8) || d0!==expected0 || d1!==expected1 || err!==expected_error)
                $fatal(1,"reader data channel/null mismatch n=%0d ch=%0d d0=%h/%h d1=%h/%h err=%b/%b",number,result_ch,d0,expected0,d1,expected1,err,expected_error);
            held={result_ch,d0,d1,err};
            repeat(number%9+2)begin @(negedge clk);
                if(!valid || request_ready || !cs || sclk || held!=={result_ch,d0,d1,err})$fatal(1,"result backpressure lost data");end
            ready=1;@(negedge clk);ready=0;if(valid)$fatal(1,"result handshake");
            checked=checked+1;
        end
    endtask
    initial begin
        reset_reader();for(t=0;t<160;t=t+1)transfer(t);
        if(complete0!=160 || complete1!=160)$fatal(1,"frame count");
        // Abort during leading zeros, command, null, payload and final hold.
        for(j=0;j<5;j=j+1)begin
            @(negedge clk);req=1;ch=3'(j);while(!request_ready)@(negedge clk);
            @(negedge clk);req=0;
            repeat((j==4)?24:(j*5+1))@(posedge sclk);
            @(negedge clk);reset_reader();transfer(170+j);
        end
        if(spi_edges<48*checked)$fatal(1,"SPI cadence test not exercised");
        $display("PASS dual MCP3208 reader: %0d data frames, measured%0d-cycle half-period,delayed MISO,24bit command/data,rails,null errors,backpressure,busy requests,reset",checked,HALF);$finish;
    end
    initial begin #20000000;$fatal(1,"reader timeout");end
endmodule
