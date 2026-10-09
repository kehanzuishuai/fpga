`default_nettype none
// Standalone key actions, not wired to note FIFO. timestamp uses input sample time.
module hall_key_events #(
    parameter integer KEYS=16,
    parameter integer KEY_W=(KEYS>1)?$clog2(KEYS):1,
    parameter integer START_POSITION=256,
    parameter integer ON_POSITION=2048,
    parameter integer OFF_POSITION=512,
    parameter integer CONFIRM_SAMPLES=2,
    parameter integer VELOCITY_STEP_CYCLES=50000,
    parameter integer COUNT_W=(CONFIRM_SAMPLES>1)?$clog2(CONFIRM_SAMPLES+1):1
)(
    input wire clk,rst_n,
    input wire position_valid,
    output wire position_ready,
    input wire [KEY_W-1:0] position_key,
    input wire [11:0] position,
    input wire position_good,
    input wire [31:0] position_timestamp,
    output reg event_valid,
    input wire event_ready,
    output reg [KEY_W-1:0] event_key,
    output reg event_on,
    output reg [6:0] event_velocity,
    output reg [31:0] event_timestamp,
    output reg [KEYS-1:0] key_down
);
    reg [KEYS-1:0] armed,travelling,slow_travel;
    reg [KEYS*32-1:0] start_time;
    reg [KEYS*COUNT_W-1:0] confirm;
    reg [KEYS*7-1:0] candidate_velocity;
    localparam integer LAST_INTEGER=CONFIRM_SAMPLES-1;
    localparam [COUNT_W-1:0] CONF_LAST=LAST_INTEGER[COUNT_W-1:0];
    assign position_ready=!event_valid || event_ready;
    wire in_range={{(32-KEY_W){1'b0}},position_key}<KEYS;
    localparam integer TIME_IW=$clog2(KEYS*32),VEL_IW=$clog2(KEYS*7);
    localparam integer COUNT_IW=(KEYS*COUNT_W>1)?$clog2(KEYS*COUNT_W):1;
    wire [TIME_IW-1:0] key32={{(TIME_IW-KEY_W){1'b0}},position_key}<<5;
    wire [VEL_IW-1:0] key7=({{(VEL_IW-KEY_W){1'b0}},position_key}<<3)-{{(VEL_IW-KEY_W){1'b0}},position_key};
    function automatic [COUNT_IW-1:0] count_offset(input [KEY_W-1:0] key);
        integer j;
        begin
            count_offset=0;
            for(j=0;j<COUNT_W;j=j+1) count_offset=count_offset+{{(COUNT_IW-KEY_W){1'b0}},key};
        end
    endfunction
    wire [COUNT_IW-1:0] key_count=count_offset(position_key);
    wire [31:0] elapsed=position_timestamp-start_time[key32 +: 32];
    function automatic [6:0] speed_velocity(input [31:0] ticks);
        begin
            if(ticks<=32'(VELOCITY_STEP_CYCLES)) speed_velocity=127;
            else if(ticks<=32'(VELOCITY_STEP_CYCLES*2)) speed_velocity=112;
            else if(ticks<=32'(VELOCITY_STEP_CYCLES*4)) speed_velocity=96;
            else if(ticks<=32'(VELOCITY_STEP_CYCLES*8)) speed_velocity=80;
            else if(ticks<=32'(VELOCITY_STEP_CYCLES*16)) speed_velocity=64;
            else if(ticks<=32'(VELOCITY_STEP_CYCLES*32)) speed_velocity=48;
            else if(ticks<=32'(VELOCITY_STEP_CYCLES*64)) speed_velocity=32;
            else if(ticks<=32'(VELOCITY_STEP_CYCLES*128)) speed_velocity=16;
            else speed_velocity=1;
        end
    endfunction
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            event_valid<=0;event_key<=0;event_on<=0;event_velocity<=0;event_timestamp<=0;
            armed<=0;travelling<=0;slow_travel<=0;key_down<=0;
            start_time<=0;confirm<=0;candidate_velocity<=0;
        end else begin
            if(event_valid && event_ready) event_valid<=0;
            if(position_valid && position_ready && in_range) begin
                if(!position_good) begin
                    armed[position_key]<=0;travelling[position_key]<=0;slow_travel[position_key]<=0;confirm[key_count +: COUNT_W]<=0;
                    if(key_down[position_key]) begin
                        key_down[position_key]<=0;event_valid<=1;event_key<=position_key;
                        event_on<=0;event_velocity<=0;event_timestamp<=position_timestamp;
                    end
                end else if(!armed[position_key]) begin
                    if(position<=12'(OFF_POSITION)) armed[position_key]<=1;
                end else if(key_down[position_key]) begin
                    if(position<=12'(OFF_POSITION)) begin
                        if(confirm[key_count +: COUNT_W]==CONF_LAST) begin
                            key_down[position_key]<=0;confirm[key_count +: COUNT_W]<=0;travelling[position_key]<=0;
                            event_valid<=1;event_key<=position_key;event_on<=0;event_velocity<=0;event_timestamp<=position_timestamp;
                        end else confirm[key_count +: COUNT_W]<=confirm[key_count +: COUNT_W]+1'b1;
                    end else confirm[key_count +: COUNT_W]<=0;
                end else begin
                    if(position<=12'(START_POSITION)) begin travelling[position_key]<=0;slow_travel[position_key]<=0;end
                    else if(!travelling[position_key]) begin travelling[position_key]<=1;slow_travel[position_key]<=0;start_time[key32 +: 32]<=position_timestamp;end
                    else if(elapsed>32'(VELOCITY_STEP_CYCLES*128)) slow_travel[position_key]<=1;
                    if(position>=12'(ON_POSITION)) begin
                        if(confirm[key_count +: COUNT_W]==CONF_LAST) begin
                            key_down[position_key]<=1;confirm[key_count +: COUNT_W]<=0;
                            event_valid<=1;event_key<=position_key;event_on<=1;event_timestamp<=position_timestamp;
                            event_velocity<=(CONFIRM_SAMPLES==1)?(travelling[position_key]?(slow_travel[position_key]?7'd1:speed_velocity(elapsed)):7'd127):candidate_velocity[key7 +: 7];
                        end else begin
                            if(confirm[key_count +: COUNT_W]==0) candidate_velocity[key7 +: 7]<=travelling[position_key]?(slow_travel[position_key]?7'd1:speed_velocity(elapsed)):7'd127;
                            confirm[key_count +: COUNT_W]<=confirm[key_count +: COUNT_W]+1'b1;
                        end
                    end else confirm[key_count +: COUNT_W]<=0;
                end
            end
        end
    end
`ifndef SYNTHESIS
    initial if(KEYS<1 || KEYS>32 || KEY_W<1 || KEY_W>5 || (2**KEY_W)<KEYS || START_POSITION<0 || START_POSITION>=OFF_POSITION || OFF_POSITION>=ON_POSITION || ON_POSITION>4095 || CONFIRM_SAMPLES<1 || CONFIRM_SAMPLES>16 || COUNT_W>5 || COUNT_W<$clog2(CONFIRM_SAMPLES+1) || VELOCITY_STEP_CYCLES<1 || VELOCITY_STEP_CYCLES>16777215)
        $fatal(1,"hall_key_events invalid parameters");
`endif
endmodule
`default_nettype wire
