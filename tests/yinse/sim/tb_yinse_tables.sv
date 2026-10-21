`timescale 1ns/1ps
module tb_yinse_tables;
 reg [6:0] note=0;wire [31:0] increment;wire [10:0] length;wire signed [15:0] tuning;wire valid;
 yinse_note_table table_lut(note,increment,length,tuning,valid);
 reg [3:0] slot=0;reg [32:0] phase=0;reg [31:0] inc=0;
 wire [31:0] hphase;wire [7:0] weight;
 yinse_organ_profile organ(slot,phase,inc,hphase,weight);
 integer i;
 initial begin
  for(i=0;i<128;i=i+1)begin note=7'(i);#1;
   if(valid!==(i>=36 && i<=96))$fatal(1,"note table bounds");
   if(valid && (length<2 || length>1024 || increment==0))$fatal(1,"invalid tuning");
  end
  slot=0;phase=33'h080000000;inc=32'd100;#1;if(hphase!=32'h40000000)$fatal(1,"suboctave first half");
  phase=33'h180000000;#1;if(hphase!=32'hc0000000)$fatal(1,"suboctave lost phase bit");
  slot=8;inc=32'h10000000;#1;if(weight!=0)$fatal(1,"Nyquist alias not muted");
  $display("PASS note range, KS delay bounds, suboctave continuity and Nyquist partial rejection");$finish;
 end
endmodule
