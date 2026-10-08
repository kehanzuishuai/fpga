`timescale 1ns/1ps
// Independent wire receiver: never inspects serializer counters or shift regs.
module i2s_checker #(parameter W=24, SLOT=32, HALF=2)(
 input clk,rst_n,valid,input [W-1:0] left,right,
 input bclk,ws,data,output integer frames,output integer nonzero_frames
);
 reg [W-1:0] pending_l,pending_r,frame_r;
 reg [W-1:0] preedge_l,preedge_r,latched_l,latched_r;
 reg [SLOT-1:0] expected;
 reg prev_ws,started;
 integer bits_since_ws,cycles,last_edge,last_left;
 reg previous_bclk,previous_data,previous_ws;
 always @(posedge clk) begin
   if (!rst_n) begin
     pending_l<=0; pending_r<=0; cycles=0; last_edge=0;
     previous_bclk=0; previous_data=0; previous_ws=1;
   end else begin
     cycles=cycles+1;
     preedge_l=pending_l;preedge_r=pending_r;
     if(valid) begin pending_l<=left; pending_r<=right; end
     #0.001;
     if(bclk!=previous_bclk) begin
       if(cycles-last_edge!=HALF) $fatal(1,"BCLK half-period %0d",cycles-last_edge);
       last_edge=cycles;
     end
     if((data!=previous_data || ws!=previous_ws) && !(previous_bclk && !bclk))
       $fatal(1,"DATA/WS changed outside falling BCLK");
     previous_bclk=bclk; previous_data=data; previous_ws=ws;
   end
 end
 // Snapshot at the WS falling boundary, using values BEFORE that clk edge.
 // A simultaneous valid transaction becomes eligible for the NEXT frame.
 always @(negedge ws) if(rst_n) begin latched_l=preedge_l;latched_r=preedge_r;end
 always @(negedge rst_n) begin
   expected=0;prev_ws=1;started=0;frames=0;nonzero_frames=0;
   bits_since_ws=0;last_left=0;frame_r=0;
 end
 always @(posedge bclk) if(rst_n) begin
   if(ws!=prev_ws) begin
     if(started) begin
       if(bits_since_ws!=SLOT) $fatal(1,"WS slot length %0d",bits_since_ws);
       if(data!==expected[SLOT-1]) $fatal(1,"I2S old-channel last bit mismatch");
     end
     started=1; bits_since_ws=1;
     if(!ws) begin
       if(frames && cycles-last_left!=4*HALF*SLOT) $fatal(1,"LRCLK period");
       last_left=cycles;frames=frames+1;
       if(latched_l!=0 || latched_r!=0) nonzero_frames=nonzero_frames+1;
       expected={latched_l,{(SLOT-W){1'b0}}};frame_r=latched_r;
     end else expected={frame_r,{(SLOT-W){1'b0}}};
   end else if(started) begin
     bits_since_ws=bits_since_ws+1;
     if(data!==expected[SLOT-1]) $fatal(1,"I2S bit mismatch frame=%0d bit=%0d",frames,bits_since_ws);
     expected={expected[SLOT-2:0],1'b0};
   end
   prev_ws=ws;
 end
endmodule

module tx_case #(parameter W=24,SLOT=32)(output reg done);
 localparam HALF=12288000/(4*48000*SLOT);
 reg clk=0,rst_n=0,valid=0;
 reg [W-1:0] left=0,right=0;
 wire bclk,ws,data;wire [31:0] frames,nonzero_frames;
 always #40.690104167 clk=~clk;
 pcm5102_i2s_tx #(.SAMPLE_W(W),.SLOT_W(SLOT)) dut(clk,rst_n,valid,left,right,bclk,ws,data);
 i2s_checker #(.W(W),.SLOT(SLOT),.HALF(HALF)) check(clk,rst_n,valid,left,right,bclk,ws,data,frames,nonzero_frames);
 integer n; reg [31:0] random_state=32'h12345678;
 initial begin
   done=0; #1;rst_n=1;#1;rst_n=0;repeat(5) @(negedge clk);rst_n=1;
   for(n=0;n<16000;n=n+1) begin
     @(negedge clk);
     random_state=(random_state<<1)^((random_state[31])?32'h04c11db7:32'd0);
     valid=(n%37==0);
     case(n%8)
       0: begin left=0;right={W{1'b1}};end
       1: begin left={1'b1,{(W-1){1'b0}}};right={1'b0,{(W-1){1'b1}}};end
       2: begin left=1;right=2;end
       default: begin left=random_state[W-1:0];right=~random_state[W-1:0];end
     endcase
   end
   if(frames<50 || nonzero_frames<40) $fatal(1,"insufficient frames");
   // Asynchronous reset in a partially transmitted frame, then restart.
   #7;rst_n=0;#1;if(bclk!==0 || ws!==1 || data!==0) $fatal(1,"reset outputs");
   repeat(5) @(negedge clk);rst_n=1;valid=1;left=1;right={W{1'b1}};
   repeat(1300) @(negedge clk);
   $display("PASS I2S %0d-bit/%0d-slot: edges, stereo atomic snapshot, padding, reset",W,SLOT);
   done=1;
 end
endmodule

module tb_pcm5102a;
 wire a,b,c;
 tx_case #(.W(24),.SLOT(32)) x(a);
 tx_case #(.W(16),.SLOT(16)) y(b);
 tx_case #(.W(32),.SLOT(32)) z(c);
 initial begin wait(a&&b&&c); $display("PASS nominal 24/32 BCLK=3072000 Hz LRCLK=48000 Hz (measured 4/256 input clocks)");$finish;end
 initial begin #3000000;$fatal(1,"timeout");end
endmodule
