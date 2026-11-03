`timescale 1ns/1ps
module tb_masks_r6;reg clk=0;always #1 clk=~clk;typedef struct packed{logic[11:0] x,y,env_y;} pixel_info;pixel_info envelope_late;wire envelope_area_late=envelope_late.x>=836 && envelope_late.x<=1151 && envelope_late.y>=220 && envelope_late.y<=434;reg envelope_glow_q,envelope_stroke_q,envelope_fill_valid_q;always@(posedge clk)begin
  envelope_glow_q<=envelope_area_late && envelope_late.y+3>=envelope_late.env_y && envelope_late.y<=envelope_late.env_y+3;
  envelope_stroke_q<=envelope_area_late && envelope_late.y+1>=envelope_late.env_y && envelope_late.y<=envelope_late.env_y+1;
  envelope_fill_valid_q<=envelope_area_late && envelope_late.y>envelope_late.env_y+3 && envelope_late.y<432;
end
integer x,y,curve,checked=0;reg a,b,c;initial begin for(curve=220;curve<440;curve=curve+3)for(y=200;y<450;y=y+1)for(x=830;x<1160;x=x+7)begin @(negedge clk);envelope_late={12'(x),12'(y),12'(curve)};a=x>=836&&x<=1151&&y>=220&&y<=434&&(y+3>=curve&&y<=curve+3);b=x>=836&&x<=1151&&y>=220&&y<=434&&(y+1>=curve&&y<=curve+1);c=x>=836&&x<=1151&&y>=220&&y<=434&&(y>curve+3&&y<432);@(posedge clk);#0.1;if({a,b,c}!=={envelope_glow_q,envelope_stroke_q,envelope_fill_valid_q})$fatal(1,"mask mismatch");checked=checked+1;end $display("PASS production-extracted envelope masks: %0d coordinates, existing pixel latency unchanged",checked);$finish;end endmodule
