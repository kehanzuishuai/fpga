`timescale 1ns/1ps
module tb_visual_readout;
 reg clk=0,rst_n=0,blank=0;
 always #5 clk=~clk;
 wire [8:0] wa;wire [8:0] sa;wire wr,sr;
 reg [36:0] data=0;
 reg [36:0] input_power[0:511];
 wire [7:0]r,g,b;wire de,hs,vs;
 visual_renderer #(.LOGN(10)) dut(clk,rst_n,10'd0,10'd0,1'b0,1'b1,1'b1,blank,
 1'b0,1'b1,24'd0,data,wa,sa,wr,sr,r,g,b,de,hs,vs);
 always @(posedge clk)data<=input_power[sa];
 reg [9:0]x=0,y=0;reg valid=1;reg [15:0]hz=0;wire ink;
 visual_labels labels(x,y,valid,hz,ink);
 wire ink96;
 visual_labels #(.SAMPLE_RATE(96000)) labels96(x,y,valid,hz,ink96);
 integer i,count;
 task snapshot;
 begin @(negedge clk);blank=1;@(negedge clk);blank=0;
 wait(sr);@(negedge clk);end endtask
 initial begin
 for(i=0;i<512;i=i+1)input_power[i]=0;
 #1;rst_n=1;#1;rst_n=0;repeat(3)@(negedge clk);rst_n=1;
 // DC deliberately strongest: readout excludes it. Near-equal powers map to
 // the same display height; selection must use full power, not bar height.
 input_power[0]=37'd9999999;input_power[37]=37'd100000;
 input_power[38]=37'd100001;snapshot();
 if(!dut.peak_valid || dut.peak_hz!=1781)$fatal(1,"full-precision peak/DC exclusion failed %0d",dut.peak_hz);
 for(i=0;i<512;i=i+1)input_power[i]=0;
 input_power[511]=37'd4000;snapshot();
 if(!dut.peak_valid || dut.peak_hz!=23953)$fatal(1,"last-bin peak failed");
 for(i=0;i<512;i=i+1)input_power[i]=0;
 snapshot();if(dut.peak_valid || dut.peak_hz!=0)$fatal(1,"silence peak stale");
 hz=16'd24000;#1;if(labels.digits!=20'h24000)$fatal(1,"BCD24000");
 hz=16'd65535;#1;if(labels.digits!=20'h65535)$fatal(1,"BCD65535");
 hz=0;#1;if(labels.digits!=0)$fatal(1,"BCDzero");
 if(labels96.MID_BCD!=20'h24000 || labels96.MAX_BCD!=20'h48000 || labels96.SPAN_BCD!=20'h00533)
   $fatal(1,"96k parameter-derived labels");
 x=160;y=8;#1;if(labels.ch!=8'd49)$fatal(1,"waveform span tens digit");
 x=208;y=8;#1;if(labels.ch!=8'd54)$fatal(1,"waveform span fractional digit");
 x=128;y=8;#1;if(labels.ch!=8'd78 || !ink)$fatal(1,"SPAN N glyph missing");
 valid=0;x=144;y=200;#1;if(labels.ch!=8'd45)$fatal(1,"invalid peak label");
 count=0;
 for(i=0;i<12*16;i=i+1)begin x=10'(64+i);y=200;#1;if(ink)count=count+1;end
 if(count==0)$fatal(1,"labels invisible");
 x=292;y=456;#1;if(labels.ch!=8'd49)$fatal(1,"frequency midpoint label");
 x=520;y=456;#1;if(labels.ch!=8'd50)$fatal(1,"frequency endpoint label");
 $display("PASS full-power peak,DC exclusion,last bin,silence,BCD and parameter-derived instrument labels");$finish;
 end
 initial begin #2000000;$fatal(1,"readout timeout");end
endmodule
