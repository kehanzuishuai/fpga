`timescale 1ns/1ps
module tb_hall_keys;
    parameter integer KEYS=16,FILTER_SHIFT=2,CONFIRM_SAMPLES=2;
    localparam integer KEY_W=(KEYS>1)?$clog2(KEYS):1;
    reg clk=0;always #5 clk=~clk;
    reg rst_n=0,cfg_valid=0,sample_valid=0,sample_good=0;
    reg [KEY_W-1:0] cfg_key=0,sample_key=0;
    reg [11:0] cfg_rest=0,cfg_down=0,sample_raw=0;
    reg [31:0] sample_timestamp=0,cfg_timestamp=0;
    wire cfg_ready,sample_ready,position_valid,position_ready,position_good;
    wire [KEY_W-1:0] position_key,event_key;
    wire [11:0] position;
    wire [31:0] position_timestamp,event_timestamp;
    wire [KEYS-1:0] calibrated,key_down;
    wire event_valid,event_on;
    wire [6:0] event_velocity;
    reg event_ready=0,auto_ready=1;
    hall_position_filter #(.KEYS(KEYS),.FILTER_SHIFT(FILTER_SHIFT)) norm(.*);
    hall_key_events #(.KEYS(KEYS),.CONFIRM_SAMPLES(CONFIRM_SAMPLES),.VELOCITY_STEP_CYCLES(100)) detect(.*);
    integer fd,logfile,rc,kind,ki,rawv,goodv,restv,downv,count=0,positions=0,events=0;
    reg [31:0] stamp;
    reg [31:0] rng=32'haf32719d;
    reg logging=0,stall_p=0,stall_e=0;
    integer cycle=0,accepted_cycle=0,min_latency=1000,max_latency=0;
    reg waiting_position=0;
    reg [KEY_W+44:0] saved_p;
    reg [KEY_W+39:0] saved_e;
    always @(negedge clk) begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        event_ready=auto_ready && rng[0] && rng[3];
    end
    always @(posedge clk) begin
        cycle=cycle+1;
        if(!rst_n) begin stall_p=0;stall_e=0;waiting_position=0;end
        else begin
            if(position_valid && waiting_position) begin
                if(cycle-accepted_cycle>25) $fatal(1,"normalizer exceeded25 cycles");
                if(logging) begin
                    if(cycle-accepted_cycle<min_latency) min_latency=cycle-accepted_cycle;
                    if(cycle-accepted_cycle>max_latency) max_latency=cycle-accepted_cycle;
                end
                waiting_position=0;
            end
            if((cfg_valid && cfg_ready && {1'b0,cfg_key}<KEYS) || (sample_valid && sample_ready && {1'b0,sample_key}<KEYS)) begin
                accepted_cycle=cycle;waiting_position=1;
            end
            if(stall_p && (!position_valid || {position_key,position,position_good,position_timestamp}!==saved_p)) $fatal(1,"position changed under backpressure");
            if(stall_e && (!event_valid || {event_key,event_on,event_velocity,event_timestamp}!==saved_e)) $fatal(1,"event changed under backpressure");
            stall_p=position_valid && !position_ready;stall_e=event_valid && !event_ready;
            saved_p={position_key,position,position_good,position_timestamp};saved_e={event_key,event_on,event_velocity,event_timestamp};
            if(logging && position_valid && position_ready) begin
                $fdisplay(logfile,"P %0d %0d %0d %0d",position_key,position,position_good,position_timestamp);positions=positions+1;
            end
            if(logging && event_valid && event_ready) begin
                $fdisplay(logfile,"E %0d %0d %0d %0d",event_key,event_on,event_velocity,event_timestamp);events=events+1;
            end
        end
    end
    task reset_all;
        begin
            @(negedge clk);rst_n=0;cfg_valid=0;sample_valid=0;
            repeat(3) @(negedge clk);
            rst_n=1;
            @(negedge clk);
            if(calibrated!==0 || key_down!==0 || position_valid || event_valid) $fatal(1,"reset did not clear state");
        end
    endtask
    task prefix_sample(input [11:0] raw);
        begin
            @(negedge clk);sample_key=0;sample_raw=raw;sample_good=1;sample_valid=1;
            do @(posedge clk);while(!sample_ready);
            @(negedge clk);sample_valid=0;
            repeat(30) @(negedge clk);
        end
    endtask
    initial begin
        logfile=$fopen("sim_out_keys/results.txt","w");fd=$fopen("sim_out_keys/vectors.txt","r");
        if(!logfile || !fd) $fatal(1,"fixture open");
        reset_all();
        // Abort a non-endpoint normalization mid-divider, independent of model trace.
        cfg_key=0;cfg_rest=0;cfg_down=4095;cfg_valid=1;
        do @(posedge clk);while(!cfg_ready);
        @(negedge clk);cfg_valid=0;sample_key=0;sample_raw=1234;sample_good=1;sample_valid=1;
        do @(posedge clk);while(!sample_ready);
        @(negedge clk);sample_valid=0;
        repeat(5) @(negedge clk);
        if(position_valid) $fatal(1,"expected divider in flight");
        reset_all();repeat(30) @(negedge clk);
        if(position_valid || event_valid) $fatal(1,"aborted sample escaped reset");
        // Reset a held key with a pending, stalled key-on event.
        cfg_key=0;cfg_rest=0;cfg_down=4095;cfg_valid=1;
        #1;if(sample_ready) $fatal(1,"config did not take priority");
        do @(posedge clk);while(!cfg_ready);
        @(negedge clk);cfg_valid=0;
        prefix_sample(0);auto_ready=0;
        while(!key_down[0]) prefix_sample(4095);
        if(!event_valid || event_ready) $fatal(1,"expected pending event");
        repeat(20) @(negedge clk);
        reset_all();auto_ready=1;repeat(30) @(negedge clk);
        if(event_valid || key_down!==0) $fatal(1,"pending event escaped reset");
        logging=1;
        while(!$feof(fd)) begin
            rc=$fscanf(fd,"%d %d %d %d %d %d %d\n",kind,ki,rawv,stamp,goodv,restv,downv);
            if(rc!=7) $fatal(1,"bad fixture");
            @(negedge clk);
            if(kind==2) begin
                while(!sample_ready || event_valid || position_valid) @(negedge clk);
                reset_all();$fdisplay(logfile,"R");
            end else if(kind==1) begin
                cfg_key=ki[KEY_W-1:0];cfg_rest=restv[11:0];cfg_down=downv[11:0];cfg_timestamp=stamp;cfg_valid=1;
                do @(posedge clk);while(!cfg_ready);
                @(negedge clk);cfg_valid=0;
            end else begin
                sample_key=ki[KEY_W-1:0];sample_raw=rawv[11:0];sample_timestamp=stamp;sample_good=goodv[0];sample_valid=1;
                do @(posedge clk);while(!sample_ready);
                @(negedge clk);sample_valid=0;
            end
            count=count+1;
        end
        while(!sample_ready || event_valid || position_valid) @(negedge clk);
        repeat(10) @(negedge clk);
        $fdisplay(logfile,"L %0d %0d",min_latency,max_latency);
        $fdisplay(logfile,"D %0d",key_down);$fclose(fd);$fclose(logfile);
        $display("PASS Hall key chain: %0d commands,%0d normalized outputs,%0d events; backpressure and in-flight reset",count,positions,events);
        $finish;
    end
    initial begin #50000000;$fatal(1,"timeout");end
endmodule
