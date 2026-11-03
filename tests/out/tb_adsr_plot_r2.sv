`timescale 1ns/1ps
module tb_adsr_plot;
 reg clk=0;always #1 clk=~clk;reg [11:0] x=0;reg [127:0] history=0;wire [11:0] y;
 visual_adsr_plot dut(clk,x,history,y);
 integer expected[0:12000];reg valid[0:12000];integer cycles=0,pat,i,j,idx,frac,ha,hb,answer,file;
 task pixel(input integer px);
 begin
  @(negedge clk);x=12'(px);valid[cycles]=(px>=836 && px<=1151);
  idx=(px-836)/21;frac=(px-836)%21;if(px==1151)begin idx=14;frac=21;end
  if(valid[cycles])begin ha=(32'(history[idx*8+:8])*200)/255;hb=(32'(history[(idx+1)*8+:8])*200)/255;expected[cycles]=432-(ha*(21-frac)+hb*frac)/21;end
  @(posedge clk);#0.1;
  if(cycles>=7 && valid[cycles-7])begin
   if(y!==expected[cycles-7])$fatal(1,"plot align/value cycle%0d y%0d expected%0d",cycles,y,expected[cycles-7]);
   if(pat==2)$fdisplay(file,"%0d,%0d",836+(cycles-7)%321,y);
  end
  cycles=cycles+1;
 end endtask
 initial begin
  file=$fopen("tests/out/adsr_curve.csv","w");
  for(i=0;i<256;i=i+1)if(dut.height(8'(i))!=(i*200)/255)$fatal(1,"height");
  for(i=0;i<=4200;i=i+1)if((i*3121)>>16 != i/21)$fatal(1,"reciprocal");
  for(pat=0;pat<24;pat=pat+1)begin
   for(i=0;i<16;i=i+1)case(pat)
    0:history[i*8+:8]=0;1:history[i*8+:8]=255;
    2:history[i*8+:8]=(i<3)?8'(i*85):(i<8)?8'(255-(i-3)*20):8'(155-(i-8)*20);
    default:history[i*8+:8]=$random;
   endcase
   for(j=836;j<=1151;j=j+1)pixel(j);
   repeat(8)pixel(0);
  end
  $fclose(file);$display("PASS ADSR plot: all256 height values,4201 exact reciprocal values,24x316 raster positions, endpoints and8-clock descriptor alignment");$finish;
 end
endmodule
