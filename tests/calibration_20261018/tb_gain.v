`timescale 1ns/1ps
module tb_gain;
reg clk=0,rst_n=0,start=0,done=0;always #5 clk=~clk;
reg[6:0] note=0;reg signed[23:0] raw=0;wire signed[23:0] y;
piano_note_gain u(clk,rst_n,start,note,done,raw,y);
integer fi,rc,n,x,expected,count=0;reg[15:0] old_gain;
initial begin
 repeat(4)@(negedge clk);rst_n=1;raw=100000;@(negedge clk);
 if(y!==24'sd100000)$fatal(1,"reset unity");
 fi=$fopen("tests/calibration_20261018/gain_vectors.txt","r");
 while(!$feof(fi))begin
  rc=$fscanf(fi,"%d %d %d",n,x,expected);
  if(rc==3)begin
   old_gain=u.active_gain;note=n;start=1;@(negedge clk);start=0;
   if(u.active_gain!==old_gain)$fatal(1,"steal changed old gain before load");
   repeat(3)@(negedge clk);
   if(u.active_gain!==old_gain)$fatal(1,"pending gain leaked");
   raw=0;done=1;@(negedge clk);done=0;raw=x;#1;
   if(y!==expected)$fatal(1,"gain mismatch note%0d raw%0d expected%0d got%0d",n,x,expected,y);
   count=count+1;
  end
 end
 rst_n=0;@(negedge clk);rst_n=1;raw=-999;#1;
 if(y!==-24'sd999)$fatal(1,"reset lost unity");
 $display("PASS gain signed rounding/saturation/unity/retarget commit/reset: %0d vectors",count);$finish;
end
endmodule
