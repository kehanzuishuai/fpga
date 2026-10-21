`timescale 1ns/1ps
// A/B experiment: identical wires, one receiver uses its documented reset API.
module tb_checker_reset;
reg clk=0,rst_n=0;always #40.69 clk=~clk;
reg [7:0] div=0;wire tick=(div==200);reg signed [23:0] audio=0;
always @(posedge clk) if(!rst_n)begin div<=0;audio<=0;end
else begin div<=div+1'b1;if(tick)audio<=audio+24'sd12345;end
wire bc,lr,da;
pcm5102_i2s_tx tx(clk,rst_n,tick,audio,audio,bc,lr,da);
pcm5102_frame_check missing_restart(clk,rst_n,tick,audio,audio,bc,lr,da);
pcm5102_frame_check correct_restart(clk,rst_n,tick,audio,audio,bc,lr,da);
initial begin
 #1;rst_n=1;#1;rst_n=0;#1000;rst_n=1;
 repeat(20)@(negedge lr);repeat(70)@(negedge clk);
 correct_restart.restart;rst_n=0;repeat(10)@(negedge clk);rst_n=1;
 repeat(20)@(negedge lr);@(negedge clk);
 $display("MISSING restart: data=%0d pad=%0d length=%0d delay=%0d frames=%0d",missing_restart.errors,missing_restart.pad_errors,missing_restart.len_errors,missing_restart.delay_errors,missing_restart.frames_ok);
 $display("CORRECT restart: data=%0d pad=%0d length=%0d delay=%0d frames=%0d",correct_restart.errors,correct_restart.pad_errors,correct_restart.len_errors,correct_restart.delay_errors,correct_restart.frames_ok);
 if(missing_restart.len_errors==0)$fatal(1,"did not reproduce partial frame across reset");
 if(correct_restart.errors || correct_restart.pad_errors || correct_restart.len_errors || correct_restart.delay_errors || correct_restart.frames_ok<30)$fatal(1,"correct restart still failed");
 $display("PASS isolated receiver reset A/B; data and timing checks retained");$finish;
end
endmodule
