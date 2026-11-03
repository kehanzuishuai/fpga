module tb_expression_pitch;
reg clk=0;always #5 clk=~clk;reg rst_n=0,tick=0,start=0;reg [6:0] glide=0;reg [21:0] seed=65536;reg signed [7:0] lfo=0;wire [21:0] ratio;
expression_pitch_state dut(clk,rst_n,tick,start,glide,seed,lfo,ratio);
integer i,prior;
task frame;begin @(negedge clk);tick=1;@(negedge clk);tick=0;end endtask
task launch(input integer value);begin @(negedge clk);seed=value;start=1;@(negedge clk);start=0;end endtask
initial begin #12;rst_n=1;frame();if(ratio!==65536)$fatal(1,"bypass");
 glide=1;launch(32768);prior=ratio;for(i=0;i<2000;i=i+1)begin frame();if(ratio<prior || ratio>65536)$fatal(1,"upward glide");prior=ratio;end
 if(ratio!=65536)$fatal(1,"up not converged");launch(131072);prior=ratio;
 for(i=0;i<2000;i=i+1)begin frame();if(ratio>prior || ratio<65536)$fatal(1,"downward glide");prior=ratio;end
 if(ratio!=65536)$fatal(1,"down not converged");
 lfo=64;#1;if(ratio!=67584)$fatal(1,"positive depth %d",ratio);lfo=-64;#1;if(ratio!=63488)$fatal(1,"negative depth %d",ratio);
 lfo=0;glide=0;launch(2097152);frame();if(ratio!==65536)$fatal(1,"zero bypass");
 $display("PASS up/down convergence, no overshoot, positive/negative vibrato, exact zero bypass");$finish;end
endmodule
