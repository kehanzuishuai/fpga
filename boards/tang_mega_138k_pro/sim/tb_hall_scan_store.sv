`timescale 1ns/1ps
module tb_hall_scan_store;
    parameter integer STALE_CYCLES=17;
    localparam integer AW=$clog2(STALE_CYCLES+1);
    reg clk=0,rst_n=0,pv=0;
    always #10 clk=~clk;
    reg [2:0] channel=0;
    reg [11:0] a0=0,a1=0;
    reg [1:0] error=0;
    wire [71:0] values;
    wire [5:0] seen,updated,stale;
    wire [6*AW-1:0] ages;
    wire [191:0] stamps;
    wire [31:0] time_now;
    wire [1:0] sticky;
    hall_scan_store #(.CHANNELS(3),.STALE_CYCLES(STALE_CYCLES)) dut(
        clk,rst_n,pv,channel,a0,a1,error,values,seen,updated,stale,ages,stamps,time_now,sticky);
    reg [11:0] expected_values[0:5];
    reg [31:0] expected_stamps[0:5];
    integer expected_age[0:5];
    reg [5:0] expected_seen=0,expected_updated=0;
    reg [1:0] expected_error=0;
    reg [31:0] expected_time=0;
    integer k,j,n;
    always @(posedge clk)begin
        if(!rst_n)begin
            expected_seen=0;expected_updated=0;expected_error=0;expected_time=0;
            for(k=0;k<6;k=k+1)begin expected_values[k]=0;expected_stamps[k]=0;expected_age[k]=0;end
        end else begin
            expected_updated=0;
            for(k=0;k<6;k=k+1)if(expected_age[k]<STALE_CYCLES)expected_age[k]=expected_age[k]+1;
            if(pv)begin
                expected_error=expected_error | error;
                for(j=0;j<2;j=j+1)if(!error[j] && channel<3)begin
                    k=3*j+{29'd0,channel};expected_values[k]=(j==0)?a0:a1;
                    expected_stamps[k]=expected_time;expected_age[k]=0;
                    expected_seen[k]=1;expected_updated[k]=1;
                end
            end
            expected_time=expected_time+1;
        end
        #1;
        if(time_now!==expected_time || seen!==expected_seen || updated!==expected_updated || sticky!==expected_error)
            $fatal(1,"standalone store metadata mismatch");
        for(k=0;k<6;k=k+1)begin
            if(values[12*k +: 12]!==expected_values[k] || stamps[32*k +: 32]!==expected_stamps[k] ||
               ages[AW*k +: AW]!==expected_age[k][AW-1:0] || stale[k]!==(!expected_seen[k] || expected_age[k]>=STALE_CYCLES))
                $fatal(1,"standalone store mismatch key%0d",k);
        end
    end
    initial begin
        repeat(3)@(negedge clk);rst_n=1;
        for(n=0;n<10000;n=n+1)begin
            @(negedge clk);channel=3'(n%8);pv=(n%9)!=2;
            a0=12'(n*123);a1=~(12'd1<<(n%12));error=2'(n%7);
            if(n==4999)rst_n=0;if(n==5002)rst_n=1;
        end
        @(negedge clk);pv=0;repeat(STALE_CYCLES+2)@(negedge clk);
        $display("PASS raw store10000cycles: invalid channels ignored,error-lane retention,consecutive updates,stale%0d threshold/saturation and reset",STALE_CYCLES);$finish;
    end
endmodule
