`timescale 1ns/1ps
module tb_waveform_lut;
  logic [31:0] phase;
  logic signed [23:0] sine,square,saw,triangle;
  integer fd,k;
  waveform_set dut(.phase,.sine,.square,.saw,.triangle);
  initial begin
    fd=$fopen("sim_out/waveform_lut.csv","w");
    if(fd==0) $fatal(1,"cannot create waveform LUT capture");
    $fwrite(fd,"index,sine,square,saw,triangle\n");
    for(k=0;k<256;k=k+1) begin phase=k<<24; #1; $fwrite(fd,"%0d,%0d,%0d,%0d,%0d\n",k,sine,square,saw,triangle); end
    $fclose(fd);
    phase=32'h4000_0000; #1; if(sine!==24'sd8388352) $fatal(1,"sine +peak scaling failed");
    phase=32'h8000_0000; #1; if(sine!==0) $fatal(1,"sine pi crossing failed");
    phase=32'hC000_0000; #1; if(sine!==-24'sd8388352) $fatal(1,"sine -peak scaling failed");
    $display("TB_WAVEFORM_LUT PASS: quarter-wave endpoints and 256-sample capture");
    $finish;
  end
endmodule
