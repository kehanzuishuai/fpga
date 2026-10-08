`timescale 1ns/1ps
module tb_dual_dac;
 reg clk=0,rst_n=0;
 always #40.690104167 clk=~clk;
 reg [23:0] left=0,right=0;
 wire old_b,old_w,old_d,tick,capture,new_b,new_w,new_d;
 wire [31:0] frames,nonzero_frames;
 i2s_tx old_tx(.clk(clk),.rst_n(rst_n),.left_sample(left),.right_sample(right),
 .i2s_bclk(old_b),.i2s_lrck(old_w),.i2s_data(old_d),.sample_tick(tick),.frame_capture(capture));
 pcm5102_i2s_tx new_tx(clk,rst_n,capture,left,right,new_b,new_w,new_d);
 i2s_checker checker1(clk,rst_n,capture,left,right,new_b,new_w,new_d,frames,nonzero_frames);
 integer cycles=0,ticks=0,captures=0,last_tick=0,last_capture=0;
 integer pos=0;reg [15:0] old_left=0,old_right=0;reg old_started=0;
 reg expected_old;
 always @(posedge clk) if(rst_n) begin
   cycles=cycles+1;
   if(capture) begin
     if(captures && cycles-last_capture!=256) $fatal(1,"capture rate");
     captures=captures+1;last_capture=cycles;
     old_left=left[23:8];old_right=right[23:8];old_started=1;pos=0;
   end
   #0.001;
   if(tick) begin
     if(ticks && cycles-last_tick!=256) $fatal(1,"sample_tick doubled/changed");
     ticks=ticks+1;last_tick=cycles;
   end
 end
 always @(posedge old_b) if(rst_n && old_started) begin
   if(old_w!==(pos<16)) $fatal(1,"PT8211 WS changed");
   expected_old=(pos<16)?old_left[15-pos]:old_right[31-pos];
   if(old_d!==expected_old) $fatal(1,"PT8211 bit %0d",pos);
   pos=pos+1;
 end
 integer n;
 initial begin
   #1;rst_n=1;#1;rst_n=0;repeat(5) @(negedge clk);rst_n=1;
   for(n=0;n<30000;n=n+1) begin
     @(negedge clk);left=left+24'h013579;right=right-24'h024681;
   end
   if(frames<100 || captures<100 || ticks<100) $fatal(1,"insufficient dual frames");
   $display("PASS dual DAC: %0d captures, %0d ticks, %0d I2S frames; PT8211 high16 bits match same PCM",captures,ticks,frames);
   $finish;
 end
endmodule
