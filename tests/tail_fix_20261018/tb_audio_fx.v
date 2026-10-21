`timescale 1ns/1ps
module tb_audio_fx;
reg clk=0,rst_n=0,v=0;always #5 clk=~clk;
reg signed [28:0] x=0;wire ov;wire signed [23:0] y;
piano_fx u(.clk(clk),.rst_n(rst_n),.in_valid(v),.in_sample(x),.soundboard_enable(1'b1),.reverb_enable(1'b1),.eq_preset(2'd0),.limiter_soft(1'b1),.out_valid(ov),.out_sample(y));
reg [2047:0] input_name,output_name;integer fi,fo,n,i,value,rc,outputs=0;
always @(posedge clk) if(rst_n && ov)begin if(^y===1'bx)$fatal(1,"FX X");$fdisplay(fo,"%0d",y);outputs=outputs+1;end
initial begin
if(!$value$plusargs("input=%s",input_name))$fatal(1,"input");if(!$value$plusargs("output=%s",output_name))$fatal(1,"output");if(!$value$plusargs("samples=%d",n))$fatal(1,"samples");
fi=$fopen(input_name,"r");fo=$fopen(output_name,"w");if(!fi||!fo)$fatal(1,"file");repeat(10)@(negedge clk);rst_n=1;repeat(2100)@(negedge clk);
for(i=0;i<n;i=i+1)begin rc=$fscanf(fi,"%d",value);if(rc!=1)$fatal(1,"read");x=value;v=1;@(negedge clk);v=0;repeat(31)@(negedge clk);end
repeat(50)@(negedge clk);if(outputs!=n)$fatal(1,"FX outputs %0d/%0d",outputs,n);$fclose(fi);$fclose(fo);$display("PASS FX stream %0d samples",outputs);$finish;end
endmodule
