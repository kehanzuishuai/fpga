`timescale 1ns/1ps
// Boundary probe models verify wiring/reset only. Physical timing is checked by
// Gowin against the real OSER10 primitive; this is not an OSER10 bitstream model.
module OSER10(output wire Q,input wire D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,PCLK,FCLK,RESET);
assign Q=RESET?1'b0:D0;
endmodule
module ELVDS_OBUF(input wire I,output wire O,OB);assign O=I;assign OB=~I;endmodule
module tb_dvi_local_reset;
reg pc=0,sc=0,rst=0;always #20 pc=~pc;always #4 sc=~sc;
reg[9:0]blue=10'h155,green=10'h2aa,red=10'h0f1;
wire[2:0]p,n;wire cp,cn;
visual_dvi_io d(pc,sc,rst,blue,green,red,p,n,cp,cn);
wire[2:0]r={d.channels[2].serializer.RESET,d.channels[1].serializer.RESET,d.channels[0].serializer.RESET};
integer checks=0;
genvar ch;
generate for(ch=0;ch<3;ch=ch+1)begin:CHECK_BITS
 wire[9:0]got={d.channels[ch].serializer.D9,d.channels[ch].serializer.D8,
 d.channels[ch].serializer.D7,d.channels[ch].serializer.D6,d.channels[ch].serializer.D5,
 d.channels[ch].serializer.D4,d.channels[ch].serializer.D3,d.channels[ch].serializer.D2,
 d.channels[ch].serializer.D1,d.channels[ch].serializer.D0};
 wire[9:0]wanted=(ch==0)?blue:((ch==1)?green:red);
 always @(negedge sc)if(got!==wanted)$fatal(1,"channel bit wiring %0d",ch);
end endgenerate
task pulse(input integer offset);
begin
 @(negedge pc);#(offset);rst=0;#0.001;
 if(r!==3'b111 || p!==0 || n!==7)$fatal(1,"reset must assert asynchronously on all channels");
 #3;rst=1;#0.001;
 if(r!==3'b111)$fatal(1,"reset released away from pixel edge");
 @(posedge pc);#0.001;if(r!==0)$fatal(1,"reset did not release together at pixel edge");
 if(p!=={red[0],green[0],blue[0]} || n!==~p || cp!==pc || cn!==~pc)$fatal(1,"DVI channel/clock wiring");
 checks=checks+1;
end endtask
initial begin
 #1;rst=1;#1;rst=0;#0.001;if(r!==7)$fatal(1,"initial reset");
 pulse(1);pulse(5);pulse(9);pulse(13);
 repeat(5)@(negedge pc);
 $display("PASS real visual_dvi_io local reset: %0d asynchronous assertions / synchronous releases, channel bit wiring and differential clock",checks);$finish;
end
endmodule
