module tb_expression_scale;
reg [27:0] increment;reg [21:0] ratio;wire [27:0] scaled,shared_scaled;reg [63:0] expected;integer i,j;
expression_phase_scale dut(increment,ratio,scaled);
wire signed [44:0] low_product=$signed({1'b0,increment[25:0]})*$signed({1'b0,ratio[16:0]});
expression_phase_correction shared_dut(increment,ratio,low_product,shared_scaled);
task check;begin #1;expected=increment;expected=expected*ratio;if(scaled!==expected[43:16] || shared_scaled!==expected[43:16])$fatal(1,"scale mismatch inc=%h ratio=%h got=%h shared=%h expected=%h",increment,ratio,scaled,shared_scaled,expected[43:16]);end endtask
initial begin
 for(i=0;i<28;i=i+1)for(j=0;j<22;j=j+1)begin increment=28'd1<<i;ratio=22'd1<<j;check();increment=~increment;ratio=~ratio;check();end
 for(i=0;i<100000;i=i+1)begin increment=$urandom;ratio=$urandom;check();end
 increment=28'hfffffff;ratio=22'h3fffff;check();ratio=65536;check();ratio=0;check();increment=0;check();
 $display("PASS compact and shared-MAC phase correction: unsigned boundary bits and 100000 randomized full-width products");$finish;end
endmodule
