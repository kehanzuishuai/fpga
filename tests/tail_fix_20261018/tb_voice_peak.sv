`timescale 1ns/1ps
module tb_voice_peak;
reg clk=0,rst_n=0,tick=0;always #5 clk=~clk;
reg[31:0]active=0;reg signed[23:0]audio=0;
wire[5:0]count;wire[23:0]peak;wire strobe;wire signed[23:0]pcm;
audio_telemetry dut(clk,rst_n,tick,active,audio,count,peak,strobe,pcm);
integer fd;
task samples(input integer n);
 integer i;begin for(i=0;i<n;i=i+1)begin @(negedge clk);tick=1;@(negedge clk);tick=0;end end
endtask
initial begin
 fd=$fopen("tests/tail_fix_20261018/VOICE_PEAK_DEFINITION.csv","w");
 $fdisplay(fd,"case,active_bitmap,pcm,VOICE,PEAK");
 #1;rst_n=1;#1;rst_n=0;repeat(2)@(negedge clk);rst_n=1;
 active=32'h80000000;audio=12345;
 samples(2399);if(count!=1 || peak!=0)$fatal(1,"PEAK published before 2400 samples");
 $fdisplay(fd,"before_window,80000000,12345,%0d,%0d",count,peak);
 samples(1);if(count!=1 || peak!=12345)$fatal(1,"window peak missing");
 $fdisplay(fd,"completed_window,80000000,12345,%0d,%0d",count,peak);
 audio=0;samples(2400);if(count!=1 || peak!=0)$fatal(1,"VOICE incorrectly depends on PCM amplitude");
 $fdisplay(fd,"active_silent,80000000,0,%0d,%0d",count,peak);
 active=0;audio=-6789;samples(2400);if(count!=0 || peak!=6789)$fatal(1,"PEAK incorrectly depends on active bitmap");
 $fdisplay(fd,"inactive_nonzero_audio,00000000,-6789,%0d,%0d",count,peak);
 active=32'hffffffff;#1;if(count!=32)$fatal(1,"32 Voice count truncated");
 $fdisplay(fd,"all32_active,ffffffff,-6789,%0d,%0d",count,peak);
 $fclose(fd);$display("PASS VOICE counts active bitmap independently of amplitude; PEAK is 2400-sample completed window; count32 correct");$finish;
end
endmodule
