`timescale 1ns/1fs
module tb_serializer_reset;
reg pc=0,sc=0,rc=0,rst=0;always#1.3468 sc=~sc;
// PLL phase0 outputs have coincident rising edges despite different periods.
initial begin #1.3468;pc=1;forever #6.734 pc=~pc;end
// PLL output2:185.625MHz, actual production coarse/fine/rising-edge trim.
initial begin #3.972050000000;rc=1;forever begin #6.634000000000;rc=0;#6.834000000000;rc=1;end end
reg[9:0]b=10'h123,g=10'h2d3,r=10'h37a;wire[2:0]a,z,an,zn;wire ca,cz,can,czn;
integer test=0,k,checks=0,fo;reg check_enable=0;
GSR GSR(.GSRI(1'b1));
visual_dvi_io n(pc,sc,rst,b,g,r,a,an,ca,can,rc);
original_dvi_io o(pc,sc,rst,b,g,r,z,zn,cz,czn);
always@(posedge pc)begin b<={b[8:0],b[9]^b[6]};g<=g+10'd37;r<=r^b;end
always@(sc)begin #0.001;if(check_enable)begin
 $fdisplay(fo,"%0d,%0d,%0d",test,a,z);
 if(^a===1'bx)$fatal(1,"unknown serialized data");checks=checks+1;
end end
initial begin
fo=$fopen("tests/display_upgrade_20261018/serializer_trace.csv","w");
repeat(4)@(posedge pc);
for(test=0;test<100;test=test+1)begin
 check_enable=0;#0.413;rst=0;repeat(3+test%3)@(posedge pc);
 // Production video_rst_n is released by the pixel-domain synchronizer.
 @(posedge pc);rst<=1;
 repeat(16)@(posedge pc);check_enable=1;repeat(24+test%2)@(posedge pc);
end
$fclose(fo);$display("Captured %0d fast-clock edges100relocks vendorOSER10/DCS",checks);$finish;
end endmodule
