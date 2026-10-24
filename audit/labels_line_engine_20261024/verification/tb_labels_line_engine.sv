`timescale 1ns/1ps
// Labels fed by draw_x/draw_y (original) versus labels fed by stage_x/stage_y
// with their private x/y register: outputs must match on every clock.
module tb_labels_line_engine;
 reg clk=0;always #1 clk=~clk;
 reg [11:0] stage_x=0,stage_y=0,draw_x=0,draw_y=0;reg peak_valid=0;reg [15:0] peak_hz=0;
 reg xy_direct=0,xy_signal=0,xy_mixed=0;reg signed [5:0] xy_shift=0;
 reg status_live=1;reg [511:0] status_data=0;reg [1:0] spectrum_range=0;
 wire ink_o,ink_n;wire [23:0] color_o,color_n;wire [1:0] cov_o,cov_n;
 pre_visual_labels o(.x_early(stage_x),.y_early(stage_y),.peak_valid(peak_valid),.peak_hz(peak_hz),.xy_direct(xy_direct),.xy_signal(xy_signal),.xy_mixed(xy_mixed),.xy_shift(xy_shift),
  .ink(ink_o),.status_live(status_live),.status_data(status_data),.color(color_o),.coverage(cov_o),.spectrum_range(spectrum_range),.clk(clk));
 visual_labels n(.x_early(stage_x),.y_early(stage_y),.peak_valid(peak_valid),.peak_hz(peak_hz),.xy_direct(xy_direct),.xy_signal(xy_signal),.xy_mixed(xy_mixed),.xy_shift(xy_shift),
  .ink(ink_n),.status_live(status_live),.status_data(status_data),.color(color_n),.coverage(cov_n),.spectrum_range(spectrum_range),.clk(clk));
 integer cycle=0,checked=0,inked=0,errors=0,seed=20261024,i,lines=0;
 task automatic randomize_status;begin
  for(i=0;i<16;i=i+1)status_data[i*32+:32]=$random(seed);
  if($random(seed)&1)begin status_data[0]=1;status_data[1]=1;status_data[2]=1;status_data[3]=1;status_data[4]=1;status_data[5]=1;
   status_data[11+:7]=36+($unsigned($random(seed))%61);status_data[8+:3]=$unsigned($random(seed))%5;
   status_data[455]=1;status_data[456+:2]=$unsigned($random(seed))%3;end
  status_live=($random(seed)&7)!=0;peak_valid=$random(seed);peak_hz=$unsigned($random(seed))%24001;
  {xy_direct,xy_signal,xy_mixed}=$random(seed);xy_shift=$random(seed);
 end endtask
 // Raster counter feeds stage_x; draw_x is its one-clock register, as in the renderer.
 reg [11:0] rx=0,ry=0;
 always @(posedge clk)begin
  stage_x<=rx;stage_y<=ry;draw_x<=stage_x;draw_y<=stage_y;cycle<=cycle+1;
  if(cycle>200)begin checked=checked+1;
   if({ink_n,color_n,cov_n}!=={ink_o,color_o,cov_o})begin errors=errors+1;if(errors<8)$display("MISMATCH cycle%0d draw %0d,%0d",cycle,draw_x,draw_y);end
   if(ink_o)inked=inked+1;end
  if(rx==2199)begin rx<=0;ry<=ry==1124?0:ry+1;lines=lines+1;randomize_status();if(lines%64==0)spectrum_range<=$random(seed);end
  else begin rx<=rx+1;if(($random(seed)&255)==0)randomize_status();end
 end
 initial begin randomize_status();wait(cycle==2200*1125+400);
  $display("checked %0d clocks, ink pixels %0d, mismatches %0d",checked,inked,errors);
  if(errors==0 && inked>1000)$display("PASS labels line_engine: equal on every clock over a full frame");else $display("FAIL");$finish;end
endmodule
