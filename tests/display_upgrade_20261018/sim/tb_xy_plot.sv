`timescale 1ns/1ps
module tb_xy_plot;
 reg clk=0,rst_n=0,start=0;always #5 clk=~clk;
 wire [8:0] addr,copy_index;reg [48:0] sample=0;wire release_frame,busy,copy_valid,pixel,signal_ok,mode,mixed;
 wire signed [5:0] shift;
 reg [13:0] pixel_addr=0;reg [48:0] stimulus[0:5119];
 integer scenario=0,cycles,i,f;
 visual_xy_plot dut(clk,rst_n,start,addr,sample,release_frame,busy,copy_valid,copy_index,pixel_addr,pixel,signal_ok,mode,mixed,shift);
 always @(posedge clk)sample<=stimulus[scenario*512+{23'b0,addr}];
 initial begin
 $readmemh("sim_out_visual/xy_plot.hex",stimulus);f=$fopen("sim_out_visual/xy_maps.txt","w");
 repeat(4)@(negedge clk);rst_n=1;
 for(scenario=0;scenario<10;scenario=scenario+1)begin
  @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
  while(busy)begin @(negedge clk);cycles=cycles+1;if(cycles>90000)$fatal(1,"vblank budget");end
  if(scenario==3 || scenario==4 || scenario==8)begin if(signal_ok)$fatal(1,"DC/silence/mixed amplified");end
  else if(!signal_ok)$fatal(1,"real signal suppressed %d",scenario);
  $fdisplay(f,"FRAME %0d %0d %0d %0d %0d %0d",scenario,signal_ok,mode,mixed,shift,cycles);
  for(i=0;i<16384;i=i+1)begin pixel_addr=14'(i);@(negedge clk);$fwrite(f,"%0d",pixel);end
  $fwrite(f,"\n");
  // No new snapshot: committed bitmap must be preserved (old code erased it).
  if(scenario==0)begin
   for(i=0;i<16384;i=i+1)if(dut.bitmap[i]===1'bx)$fatal(1,"bitmap uninitialized");
   repeat(500)@(negedge clk);if(!signal_ok)$fatal(1,"idle erase");
  end
 end
 rst_n=0;#1;if(signal_ok!==0||busy!==0)$fatal(1,"reset");
 $fclose(f);$display("PASS XY bitmap: circle/line/ratio/low-level/high-frequency/DC/silence/mixed/extremes; connected segments within vblank");$finish;
 end
 initial begin #30000000;$fatal(1,"plot timeout");end
endmodule
