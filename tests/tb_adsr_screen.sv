`timescale 1ns/1ps
module tb_adsr_screen;
 GSR GSR(.GSRI(1'b1));
 reg clk=0;always #5 clk=~clk;reg rst=0;reg [11:0] x=0,y=0;reg de=0,hs=1,vs=1,blank=0;
 reg [511:0] status=0;wire [7:0] r,g,b;wire ode,ohs,ovs;
 visual_renderer dut(.clk(clk),.rst_n(rst),.x(x),.y(y),.de(de),.hs(hs),.vs(vs),.blank_start(blank),
 .wave_pending(1'b0),.spec_pending(1'b0),.wave_data(49'd0),.spec_data(37'd0),.wave_addr(),.spec_addr(),.wave_release(),.spec_release(),
 .red(r),.green(g),.blue(b),.out_de(ode),.out_hs(ohs),.out_vs(ovs),.status_live(1'b1),.status_data(status));
 reg [11:0] xp[0:43],yp[0:43];reg [43:0] dp=0;
 reg [23:0] pixels[0:160129];integer i,j,xx,yy,idx,seen=0,f,px,py;
 always @(posedge clk)begin
  xp[0]<=x;yp[0]<=y;dp<={dp[42:0],de};
  for(integer k=1;k<44;k=k+1)begin xp[k]<=xp[k-1];yp[k]<=yp[k-1];end
  #0.2;
  if(ode && dp[43] && xp[43]>=770 && xp[43]<1440 && yp[43]>=220 && yp[43]<459)begin
   if(^{r,g,b}===1'bx)$fatal(1,"unknown ADSR RGB");
   pixels[(yp[43]-220)*670+xp[43]-770]={r,g,b};seen=seen+1;
  end
 end
 initial begin
  status[6:0]=7'h7f;status[10:8]=2;status[17:11]=69;status[50+17]=1;status[454:450]=17;status[455]=1;status[511:509]=4;
  for(i=0;i<32;i=i+1)status[82+i*7+:7]=7'(60+i);
  for(i=0;i<16;i=i+1)begin
   if(i<3)status[306+i*8+:8]=8'(i*127);
   else if(i<6)status[306+i*8+:8]=8'(254-(i-2)*32);
   else if(i<11)status[306+i*8+:8]=158;
   else status[306+i*8+:8]=8'(158-(i-10)*30);
  end
  $display("screen simulation startup");$fflush();repeat(10)@(negedge clk);$display("reset clocks completed");$fflush();rst=1;blank=1;@(negedge clk);blank=0;
  for(yy=220;yy<459;yy=yy+1)begin
   for(xx=0;xx<1440;xx=xx+1)begin if(xx==101)xx=770;@(negedge clk);x=12'(xx);y=12'(yy);de=xx<1920;hs=xx<2008;end
   if(yy%5==0)begin $display("screen row %0d",yy);$fflush();end
  end
  @(negedge clk);de=0;repeat(100)@(negedge clk);
  if(seen!=670*239)$fatal(1,"screen coverage %d",seen);
  f=$fopen("tests/out/adsr_screen.ppm","wb");$fwrite(f,"P6\n670 239\n255\n");
  for(i=0;i<670*239;i=i+1)$fwrite(f,"%c%c%c",pixels[i][23:16],pixels[i][15:8],pixels[i][7:0]);$fclose(f);
  $display("PASS actual RTL ADSR panel raster 670x239, valid RGB, fixed overall44-clock pixel latency; synthetic envelope test vector");$finish;
 end
 initial begin #10000000;$fatal(1,"screen timeout");end
endmodule
