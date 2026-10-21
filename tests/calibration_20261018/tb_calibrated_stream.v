`timescale 1ns/1ps
module tb_calibrated_stream;
reg clk=0,rst_n=0,start=0,done=0,valid=0;always #5 clk=~clk;
reg[6:0] note=0;reg signed[23:0] raw=0;
wire signed[23:0] cal;wire signed[39:0] main_product=cal * 16'sd32767;
wire signed[28:0] main_gain=main_product >>> 15;
wire ov;wire signed[23:0] fx;
piano_note_gain u_gain(clk,rst_n,start,note,done,raw,cal);
piano_fx u_fx(.clk(clk),.rst_n(rst_n),.in_valid(valid),.in_sample(main_gain),
 .soundboard_enable(1'b1),.reverb_enable(1'b1),.eq_preset(2'd0),.limiter_soft(1'b1),.out_valid(ov),.out_sample(fx));
reg[2047:0] input_name,output_name;integer fi,fo,n,i,value,rc,outputs=0,midi;
always @(posedge clk) if(rst_n && ov)begin
 if(^fx===1'bx)$fatal(1,"FX X");$fdisplay(fo,"%0d",fx);outputs=outputs+1;
end
initial begin
 if(!$value$plusargs("input=%s",input_name))$fatal(1,"input");
 if(!$value$plusargs("output=%s",output_name))$fatal(1,"output");
 if(!$value$plusargs("samples=%d",n))$fatal(1,"samples");
 if(!$value$plusargs("note=%d",midi))$fatal(1,"note");
 fi=$fopen(input_name,"r");fo=$fopen(output_name,"w");if(!fi||!fo)$fatal(1,"file");
 repeat(10)@(negedge clk);rst_n=1;repeat(2100)@(negedge clk);
 note=midi;start=1;@(negedge clk);start=0;done=1;@(negedge clk);done=0;
 for(i=0;i<n;i=i+1)begin
  rc=$fscanf(fi,"%d",value);if(rc!=1)$fatal(1,"read");raw=value;
  @(negedge clk);valid=1;@(negedge clk);valid=0;repeat(30)@(negedge clk);
 end
 repeat(50)@(negedge clk);if(outputs!=n)$fatal(1,"outputs %0d/%0d",outputs,n);
 $fclose(fi);$fclose(fo);$display("PASS calibrated gain+FX stream MIDI%0d %0d samples",midi,outputs);$finish;
end
endmodule
