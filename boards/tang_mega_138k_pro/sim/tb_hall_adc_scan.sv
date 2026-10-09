`timescale 1ns/1ps
module tb_hall_adc_scan;
    parameter integer CLK_HZ=50000000;
    parameter integer SPI_HZ=1000000;
    parameter integer CHANNELS=8;
    parameter integer KEY_RATE_HZ=2000;
    localparam integer STALE=CLK_HZ/1000;
    localparam integer AW=$clog2(STALE+1);
    localparam integer PERIOD=(CLK_HZ+KEY_RATE_HZ*CHANNELS-1)/(KEY_RATE_HZ*CHANNELS);
    reg clk=0,rst_n=0,enable=0;
    always #(500000000.0/CLK_HZ)clk=~clk;
    wire cs,sclk,din,miso0,miso1,busy,pv,done;
    wire [2:0] ch,c0,c1;
    wire [1:0] error,sticky;
    wire [2*CHANNELS*12-1:0] values;
    wire [2*CHANNELS-1:0] seen,updated,stale;
    wire [2*CHANNELS*AW-1:0] age;
    wire [2*CHANNELS*32-1:0] stamps;
    wire [31:0] timestamp,scans;
    reg [95:0] codes0=0,codes1=0;
    reg bad0=0,bad1=0;
    integer completed0,completed1;
    hall_adc_scan #(.CLK_HZ(CLK_HZ),.SPI_HZ(SPI_HZ),.CHANNELS(CHANNELS),
        .KEY_RATE_HZ(KEY_RATE_HZ),.STALE_CYCLES(STALE)) dut(
        .clk(clk),.rst_n(rst_n),.enable(enable),.adc_cs_n(cs),.adc_sclk(sclk),.adc_din(din),
        .adc0_dout(miso0),.adc1_dout(miso1),.key_values(values),.key_seen(seen),.key_updated(updated),
        .key_stale(stale),.key_age_cycles(age),.key_timestamp(stamps),.timestamp(timestamp),
        .protocol_error_sticky(sticky),.pair_valid(pv),.pair_channel(ch),.pair_error(error),
        .busy(busy),.scan_done(done),.scan_count(scans));
    mcp3208_model m0(rst_n,cs,sclk,din,codes0,bad0,miso0,c0,completed0);
    mcp3208_model m1(rst_n,cs,sclk,din,codes1,bad1,miso1,c1,completed1);
    reg [11:0] ref_values[0:2*CHANNELS-1];
    integer ref_age[0:2*CHANNELS-1];
    reg [31:0] ref_stamp[0:2*CHANNELS-1],ref_time=0;
    reg [2*CHANNELS-1:0] ref_seen=0,ref_updated=0;
    reg [1:0] ref_error=0;
    integer i,index,expected_channel=0,pairs=0,frames=0,cycles=0,last_launch=-1;
    reg expected_done;
    always @(posedge clk)begin
        if(!rst_n)begin
            ref_seen=0;ref_updated=0;ref_error=0;ref_time=0;
            expected_channel=0;frames=0;last_launch=-1;expected_done=0;
            for(i=0;i<2*CHANNELS;i=i+1)begin ref_values[i]=0;ref_age[i]=0;ref_stamp[i]=0;end
        end else begin
            cycles=cycles+1;
            if(dut.request_valid && dut.request_ready)begin
                if(last_launch!=-1 && cycles-last_launch!=PERIOD)$fatal(1,"scan launch cadence");
                last_launch=cycles;
            end
            if(!enable)last_launch=-1;
            expected_done=0;ref_updated=0;
            for(i=0;i<2*CHANNELS;i=i+1)if(ref_age[i]<STALE)ref_age[i]=ref_age[i]+1;
            if(pv)begin
                if(ch!==3'(expected_channel) || c0!==ch || c1!==ch || error!=={bad1,bad0})
                    $fatal(1,"scan sequence/protocol flag mismatch");
                if(dut.pair_adc0!==m0.captured || dut.pair_adc1!==m1.captured)
                    $fatal(1,"independent ADC payload mismatch");
                for(index=0;index<2;index=index+1)begin
                    i=index*CHANNELS+expected_channel;
                    if(!error[index])begin
                        ref_values[i]=(index==0)?m0.captured:m1.captured;
                        ref_seen[i]=1;ref_updated[i]=1;ref_age[i]=0;ref_stamp[i]=ref_time;
                    end
                end
                ref_error=ref_error | error;pairs=pairs+1;
                if(expected_channel==CHANNELS-1)begin expected_channel=0;frames=frames+1;expected_done=1;end
                else expected_channel=expected_channel+1;
            end
            ref_time=ref_time+1;
        end
        #1;
        if(seen!==ref_seen || updated!==ref_updated || sticky!==ref_error || timestamp!==ref_time)
            $fatal(1,"scan metadata/timestamp mismatch");
        if(done!==expected_done || scans!==32'(frames))$fatal(1,"scan completion count");
        for(i=0;i<2*CHANNELS;i=i+1)begin
            if(values[12*i +: 12]!==ref_values[i] || age[AW*i +: AW]!==ref_age[i][AW-1:0] ||
                stamps[32*i +: 32]!==ref_stamp[i] || stale[i]!==(!ref_seen[i] || ref_age[i]>=STALE))
                $fatal(1,"key storage/age/freshness mismatch key%0d",i);
        end
    end
    integer launch_number=0;
    // Stable within each transaction, inject malformed null on one lane only.
    always @(negedge cs)if(rst_n)begin
        launch_number=launch_number+1;bad0=(launch_number%13)==4;bad1=(launch_number%17)==8;
    end
    integer k;
    task reset_scan;
        begin @(negedge clk);rst_n=0;enable=0;repeat(4)@(negedge clk);rst_n=1;end
    endtask
    task run_frames(input integer count);
        integer target;
        begin target=scans+count;enable=1;
        while(scans<target)@(negedge clk);end
    endtask
    initial begin
        for(k=0;k<8;k=k+1)begin codes0[12*k +: 12]=12'(k*511);codes1[12*k +: 12]=12'(4095-k*473);end
        reset_scan();#1;if(stale!=={(2*CHANNELS){1'b1}})$fatal(1,"unseen keys should be stale");
        run_frames(5);
        @(negedge clk);codes0={8{12'hfff}};codes1=0;
        run_frames(4);
        if(sticky==0)$fatal(1,"null error test not exercised");
        // Disable mid-conversion: finish exactly this pair, then stop safely.
        @(negedge cs);repeat(14)@(posedge sclk);@(negedge clk);enable=0;
        while(busy || pv)@(negedge clk);
        repeat(STALE+3)@(negedge clk);
        if(stale!=={(2*CHANNELS){1'b1}})$fatal(1,"stale timer not saturated");
        run_frames(3);
        @(negedge cs);repeat(16)@(posedge sclk);reset_scan();
        run_frames(4);enable=0;while(busy || pv)@(negedge clk);
        $display("PASS %0d-key scan/store: %0d pairs, exact%0d-cycle cadence, independent lanes,update masks,timestamps,age saturation,null errors,pause/resume,reset",2*CHANNELS,pairs,PERIOD);$finish;
    end
    initial begin #30000000;$fatal(1,"scan timeout");end
endmodule
