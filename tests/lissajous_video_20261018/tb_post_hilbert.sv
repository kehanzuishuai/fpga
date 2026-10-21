`timescale 1ns/1ps
module tb_post_hilbert;
reg clk=0,rst_n=0,pv=0;always#5 clk=~clk;
reg signed[23:0]pcm=0;reg[23:0]stim[0:10239];
wire rv,nv,dm;wire signed[15:0]rw,rx,ry,nx,ny;wire[15:8]nw;wire[31:0]drops;
integer i,seen=0,fo;
GSR GSR(.GSRI(1'b1));
visual_xy_source rtl(clk,rst_n,pv,pcm,1'b0,24'sd0,24'sd0,rv,rw,rx,ry,dm,drops);
post_xy_source net(.clk_12m288(clk),
.n114_32(!rst_n),
.u_synth_top_4_1(pcm[19]),
.u_synth_top_5_1(pcm[18]),
.u_synth_top_6_1(pcm[17]),
.u_synth_top_7_1(pcm[16]),
.u_synth_top_15_1(pcm[8]),
.u_synth_top_14_1(pcm[9]),
.u_synth_top_13_1(pcm[10]),
.u_synth_top_12_1(pcm[11]),
.u_synth_top_11_1(pcm[12]),
.u_synth_top_10_1(pcm[13]),
.u_synth_top_9_1(pcm[14]),
.u_synth_top_8_1(pcm[15]),
.visual_pcm_valid(pv),
.audio_pa_en_d(1'b1),
.left_reg_15_11(pv),
.visual_pcm(pcm[23:20]),
.paired_valid(nv),
.paired_pcm(nw),
.paired_x(nx),
.paired_y(ny));
always@(posedge clk)begin #1;if(rst_n)begin
 if(rv!==nv)$fatal(1,"valid mismatch sample%0d",i);
 if(rv)begin
  if(^{nw,nx,ny}===1'bx)$fatal(1,"unknown gate output%0d",i);
  if({rw[15:8],rx,ry}!=={nw,nx,ny})$fatal(1,"gate mismatch sample%0d X%0d/%0d Y%0d/%0d",i,rx,nx,ry,ny);
  $fdisplay(fo,"%0d %0d %0d",i,nx,ny);seen=seen+1;
 end
end end
initial begin
$readmemh("tests/lissajous_video_20261018/post_stimulus.hex",stim);
fo=$fopen("tests/lissajous_video_20261018/post_output.txt","w");
repeat(4)@(negedge clk);rst_n=1;
for(i=0;i<10240;i=i+1)begin
 @(negedge clk);pcm=stim[i];pv=1;@(negedge clk);pv=0;repeat(254)@(negedge clk);
end
repeat(140)@(negedge clk);
if(seen!=9217 || drops!=0)$fatal(1,"count/drops%0d/%0d",seen,drops);
$fclose(fo);$display("PASS actual integrated synthesized Hilbert9217pairs4sines+actualpianoPCM");$finish;
end
initial begin #30000000;$fatal(1,"timeout");end
endmodule
