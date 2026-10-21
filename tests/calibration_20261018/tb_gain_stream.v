`timescale 1ns/1ps
module tb_gain_stream;
reg clk=0,rst_n=0,start=0,done=0;always #5 clk=~clk;
reg [6:0] note=0;reg signed[23:0] raw=0;wire signed[23:0] calibrated;
piano_note_gain u(clk,rst_n,start,note,done,raw,calibrated);
reg[2047:0] input_name,output_name;integer fi,fo,n,i,value,rc,midi;
initial begin
 if(!$value$plusargs("input=%s",input_name))$fatal(1,"input");
 if(!$value$plusargs("output=%s",output_name))$fatal(1,"output");
 if(!$value$plusargs("samples=%d",n))$fatal(1,"samples");
 if(!$value$plusargs("note=%d",midi))$fatal(1,"note");
 fi=$fopen(input_name,"r");fo=$fopen(output_name,"w");if(!fi||!fo)$fatal(1,"file");
 repeat(5)@(negedge clk);rst_n=1;note=midi;start=1;
 @(negedge clk);start=0;done=1;@(negedge clk);done=0;
 for(i=0;i<n;i=i+1)begin
  rc=$fscanf(fi,"%d",value);if(rc!=1)$fatal(1,"read");raw=value;#1;
  if(^calibrated===1'bx)$fatal(1,"unknown");$fdisplay(fo,"%0d",calibrated);@(negedge clk);
 end
 $fclose(fi);$fclose(fo);$display("PASS raw -> actual gain RTL %0d samples",n);$finish;
end
endmodule
