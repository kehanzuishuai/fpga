`timescale 1ns/1ps
module tb_i2s;
  localparam integer SAMPLE_W=24;
  localparam integer SLOT_W=32;
  logic clk=0,rst_n=0,bclk,lrclk,sdata;
  logic signed [SAMPLE_W-1:0] left_sample=24'hA5_3C_7E;
  logic signed [SAMPLE_W-1:0] right_sample=24'h5A_C3_81;
  integer slot,bit_pos,cycle_count=0,bclk_edges=0,lr_edges=0;
  integer last_bclk_cycle=0,last_lr_cycle=0,bclk_period_cycles=0,lr_period_cycles=0;
  logic expected;
  always #5 clk=~clk;
  always @(posedge clk)cycle_count<=cycle_count+1;
  always @(posedge bclk)if(rst_n)begin
    if(bclk_edges!=0)bclk_period_cycles=cycle_count-last_bclk_cycle;
    last_bclk_cycle=cycle_count;bclk_edges=bclk_edges+1;
  end
  always @(posedge lrclk)if(rst_n)begin
    if(lr_edges!=0)lr_period_cycles=cycle_count-last_lr_cycle;
    last_lr_cycle=cycle_count;lr_edges=lr_edges+1;
  end
  i2s_tx #(.CLK_HZ(12288000),.SAMPLE_RATE(48000),.SAMPLE_W(SAMPLE_W),.SLOT_W(SLOT_W)) dut(
    .clk,.rst_n,.left_sample,.right_sample,.bclk,.lrclk,.sdata);
  initial begin
    repeat(4) @(posedge clk); rst_n=1;
    for(slot=0;slot<2;slot=slot+1) begin
      for(bit_pos=0;bit_pos<SLOT_W;bit_pos=bit_pos+1) begin
        @(negedge bclk); #1;
        if(lrclk!==slot[0]) $fatal(1,"I2S WS mismatch slot=%0d bit=%0d",slot,bit_pos);
        if(bit_pos==0) expected=1'b0;
        else if(bit_pos<=SAMPLE_W)
          expected=(slot==0)?left_sample[SAMPLE_W-bit_pos]:right_sample[SAMPLE_W-bit_pos];
        else expected=1'b0;
        if(sdata!==expected)
          $fatal(1,"I2S bit mismatch slot=%0d bit=%0d got=%b expected=%b",slot,bit_pos,sdata,expected);
      end
    end
    @(negedge bclk); #1; expected=sdata; @(posedge bclk); #1;
    if(sdata!==expected) $fatal(1,"I2S data changed on rising sampling edge");
    while(lr_edges<2)@(posedge clk);#1;
    if(bclk_period_cycles!=4)$fatal(1,"BCLK period=%0d clocks, expected 4",bclk_period_cycles);
    if(lr_period_cycles!=256)$fatal(1,"LRCLK period=%0d clocks, expected 256",lr_period_cycles);
    if(12288000/bclk_period_cycles!=3072000)$fatal(1,"BCLK frequency mismatch");
    if(12288000/lr_period_cycles!=48000)$fatal(1,"LRCLK frequency mismatch");
    $display("TB_I2S PASS: BCLK=3.072MHz LRCLK=48kHz, Philips delay and 24-bit alignment bit-exact");
    $finish;
  end
endmodule
