`timescale 1ns/1ps
module tb_gradient_r6;reg clk=0;always #1 clk=~clk;reg[11:0] x=0;wire[23:0] a,b;old_gradient oldg(clk,x,a);new_gradient newg(clk,x,b);integer i,k,cycle=0;always@(posedge clk)begin #0.1;if(cycle>5 && a!==b)$fatal(1,"gradient differs at%0d",x);cycle=cycle+1;end initial begin for(k=0;k<3;k=k+1)for(i=0;i<4096;i=i+1)begin @(negedge clk);x=k==1?12'($random):12'(i);end repeat(6)@(negedge clk);$display("PASS production-extracted spectrum gradient: exact4-clock RGB for all4096 X plus random transitions");$finish;end endmodule
module old_gradient(input wire clk,input wire[11:0] draw_x,output reg[23:0] spectrum_color4);reg[9:0] gradient_pos1;reg[1:0] gradient_region1,gradient_region2,gradient_region3;reg[6:0] gradient_factor_r1,gradient_factor_g1,gradient_factor_b1;reg[16:0] gradient_r2,gradient_g2,gradient_b2;reg[32:0] gradient_r3,gradient_g3,gradient_b3;localparam[32:0] GRADIENT_RECIP586=((33'd1<<25)+33'd585)/33'd586,GRADIENT_RECIP587=((33'd1<<25)+33'd586)/33'd587;always@(posedge clk)begin
  if(draw_x<666)begin gradient_region1<=0;gradient_pos1<=10'(draw_x-12'd80);end
  else if(draw_x<1253)begin gradient_region1<=1;gradient_pos1<=10'(draw_x-12'd666);end
  else begin gradient_region1<=2;gradient_pos1<=10'(draw_x-12'd1253);end
  gradient_region2<=gradient_region1;
  case(gradient_region1)
   0:begin gradient_r2<=17'(gradient_pos1)*17'd28;gradient_g2<=17'(gradient_pos1)*17'd29;gradient_b2<=17'(gradient_pos1)*17'd46;end
   1:begin gradient_r2<=17'(gradient_pos1)*17'd75;gradient_g2<=17'(gradient_pos1)*17'd9;gradient_b2<=17'(gradient_pos1)*17'd18;end
   default:begin gradient_r2<=17'(gradient_pos1)*17'd7;gradient_g2<=17'(gradient_pos1)*17'd28;gradient_b2<=17'(gradient_pos1)*17'd11;end
  endcase
  gradient_region3<=gradient_region2;
  if(gradient_region2==0)begin gradient_r3<=33'(gradient_r2)*GRADIENT_RECIP586;gradient_g3<=33'(gradient_g2)*GRADIENT_RECIP586;gradient_b3<=33'(gradient_b2)*GRADIENT_RECIP586;end
  else begin gradient_r3<=33'(gradient_r2)*GRADIENT_RECIP587;gradient_g3<=33'(gradient_g2)*GRADIENT_RECIP587;gradient_b3<=33'(gradient_b2)*GRADIENT_RECIP587;end
  case(gradient_region3)
   0:spectrum_color4<={8'(8'd142+8'(gradient_r3>>25)),8'(8'd210+8'(gradient_g3>>25)),8'(8'd249-8'(gradient_b3>>25))};
   1:spectrum_color4<={8'(8'd170+8'(gradient_r3>>25)),8'(8'd239-8'(gradient_g3>>25)),8'(8'd203-8'(gradient_b3>>25))};
   default:spectrum_color4<={8'(8'd245+8'(gradient_r3>>25)),8'(8'd230-8'(gradient_g3>>25)),8'(8'd185+8'(gradient_b3>>25))};
  endcase
end endmodule
module new_gradient(input wire clk,input wire[11:0] draw_x,output reg[23:0] spectrum_color4);reg[9:0] gradient_pos1;reg[1:0] gradient_region1,gradient_region2,gradient_region3;reg[6:0] gradient_factor_r1,gradient_factor_g1,gradient_factor_b1;reg[16:0] gradient_r2,gradient_g2,gradient_b2;reg[32:0] gradient_r3,gradient_g3,gradient_b3;localparam[32:0] GRADIENT_RECIP586=((33'd1<<25)+33'd585)/33'd586,GRADIENT_RECIP587=((33'd1<<25)+33'd586)/33'd587;always@(posedge clk)begin
  if(draw_x<666)begin gradient_region1<=0;gradient_pos1<=10'(draw_x-12'd80);gradient_factor_r1<=28;gradient_factor_g1<=29;gradient_factor_b1<=46;end
  else if(draw_x<1253)begin gradient_region1<=1;gradient_pos1<=10'(draw_x-12'd666);gradient_factor_r1<=75;gradient_factor_g1<=9;gradient_factor_b1<=18;end
  else begin gradient_region1<=2;gradient_pos1<=10'(draw_x-12'd1253);gradient_factor_r1<=7;gradient_factor_g1<=28;gradient_factor_b1<=11;end
  gradient_region2<=gradient_region1;
  gradient_r2<=17'(gradient_pos1)*17'(gradient_factor_r1);gradient_g2<=17'(gradient_pos1)*17'(gradient_factor_g1);gradient_b2<=17'(gradient_pos1)*17'(gradient_factor_b1);
  gradient_region3<=gradient_region2;
  if(gradient_region2==0)begin gradient_r3<=33'(gradient_r2)*GRADIENT_RECIP586;gradient_g3<=33'(gradient_g2)*GRADIENT_RECIP586;gradient_b3<=33'(gradient_b2)*GRADIENT_RECIP586;end
  else begin gradient_r3<=33'(gradient_r2)*GRADIENT_RECIP587;gradient_g3<=33'(gradient_g2)*GRADIENT_RECIP587;gradient_b3<=33'(gradient_b2)*GRADIENT_RECIP587;end
  case(gradient_region3)
   0:spectrum_color4<={8'(8'd142+8'(gradient_r3>>25)),8'(8'd210+8'(gradient_g3>>25)),8'(8'd249-8'(gradient_b3>>25))};
   1:spectrum_color4<={8'(8'd170+8'(gradient_r3>>25)),8'(8'd239-8'(gradient_g3>>25)),8'(8'd203-8'(gradient_b3>>25))};
   default:spectrum_color4<={8'(8'd245+8'(gradient_r3>>25)),8'(8'd230-8'(gradient_g3>>25)),8'(8'd185+8'(gradient_b3>>25))};
  endcase
end endmodule
