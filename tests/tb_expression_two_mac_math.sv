module tb_expression_two_mac_math;
 reg [27:0] increment;reg [21:0] ratio;
 reg signed [44:0] low_product,high_product;
 reg [63:0] expected;integer i,j;
 piano_partial_voice dut(.clk(1'b0),.rst_n(1'b0));
 task check;begin
  low_product=$signed({1'b0,increment[25:0]})*$signed({1'b0,ratio[16:0]});
  high_product=$signed({1'b0,increment[25:0]})*$signed({13'd0,ratio[21:17]});
  dut.phase_low=low_product[43:16];dut.mul_p=high_product;
  dut.phase_slot_ratio=ratio;dut.inc_high=increment[27:26];
  expected=increment;expected=expected*ratio;
  #1;if(dut.shared_phase_increment!==expected[43:16])
   $fatal(1,"two-MAC correction inc=%h ratio=%h got=%h expected=%h",increment,ratio,dut.shared_phase_increment,expected[43:16]);
 end endtask
 initial begin
  #1;
  for(i=0;i<28;i=i+1)for(j=0;j<22;j=j+1)begin increment=28'd1<<i;ratio=22'd1<<j;check();increment=~increment;ratio=~ratio;check();end
  for(i=0;i<100000;i=i+1)begin increment=$urandom;ratio=$urandom;check();end
  increment=28'hfffffff;ratio=22'h3fffff;check();ratio=65536;check();ratio=0;check();increment=0;check();
  $display("PASS actual two-MAC datapath: boundary bits and 100000 full-width randomized products");$finish;
 end
endmodule
