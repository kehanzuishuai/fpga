`timescale 1ns/1ps
module tb_dvi_vendor;
reg pc=0,sc=0,rst=1,gsr=0;always #20 pc=~pc;always #4 sc=~sc;
GSR GSR(.GSRI(gsr));
reg[9:0]blue=10'h155,green=10'h2aa,red=10'h0f1;
wire[2:0]p,n,rp,rn;wire cp,cn,rcp,rcn;
visual_dvi_io dut(pc,sc,rst,blue,green,red,p,n,cp,cn);
// Compare the old wiring using the SAME effective serializer reset. This
// isolates serializer data behavior from the intentional extra pixel reset.
baseline_visual_dvi_io ref_io(pc,sc,dut.channels[0].local_rst_n,blue,green,red,rp,rn,rcp,rcn);
integer checks=0,nonzero=0,changes=0;reg[2:0]last=0;reg checking=0;
always @(negedge pc)begin blue<=blue*3+1;green<=green*5+3;red<=red*7+9;end
always @(posedge sc or negedge sc)begin
 #0.002;
 if(checking)begin
  if((^p)===1'bx || p!==rp || n!==rn || cp!==rcp || cn!==rcn)$fatal(1,"vendor OSER10 data/reset comparison");
  checks=checks+1;if(p!=0)nonzero=nonzero+1;if(p!=last)changes=changes+1;last=p;
 end
end
initial begin
 #2;rst=0;#10;gsr=1;rst=1;
 repeat(8)@(negedge pc);checking=1;
 repeat(100)@(negedge pc);#7;rst=0;#5;rst=1;
 repeat(100)@(negedge pc);#3;rst=0;#9;rst=1;
 repeat(100)@(negedge pc);
 if(checks<2500 || nonzero<1000 || changes<500)$fatal(1,"vendor serializer coverage");
 $display("PASS real Gowin OSER10/ELVDS models: %0d DDR edge comparisons, nonzero=%0d changes=%0d, dynamic RGB and repeated resets; new data path identical at aligned reset",checks,nonzero,changes);$finish;
end
endmodule
