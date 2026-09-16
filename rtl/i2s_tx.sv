`default_nettype none
module i2s_tx #(
  parameter int CLK_HZ=12288000, parameter int SAMPLE_RATE=48000,
  parameter int SAMPLE_W=24, parameter int SLOT_W=32
) (
  input logic clk, input logic rst_n,
  input logic signed [SAMPLE_W-1:0] left_sample, right_sample,
  output logic bclk, output logic lrclk, output logic sdata
);
  // BCLK = SAMPLE_RATE * 2 channels * SLOT_W.  Because bclk toggles once
  // per divider expiry, the divider is the BCLK half-period in clk cycles.
  localparam int HALF_DIV_RAW=CLK_HZ/(SAMPLE_RATE*4*SLOT_W);
  localparam int DIV=(HALF_DIV_RAW<1)?1:HALF_DIV_RAW;
  localparam int DW=(DIV<=1)?1:$clog2(DIV), BW=(SLOT_W<=2)?1:$clog2(SLOT_W);
  localparam integer DIV_LAST_INT=DIV-1,SLOT_LAST_INT=SLOT_W-1;
  localparam logic [DW-1:0] DIV_LAST=DIV_LAST_INT[DW-1:0];
  localparam logic [BW-1:0] SLOT_LAST=SLOT_LAST_INT[BW-1:0];
  logic [DW-1:0] div_count; logic [BW-1:0] bit_in_slot; logic channel;
  logic [SLOT_W-1:0] shift_reg;
  function automatic [SLOT_W-1:0] slot_word(input logic signed [SAMPLE_W-1:0] x);
    // Philips I2S is MSB first.  In a wider slot the unused low bits are zero;
    // sign extension ahead of the sample would delay/corrupt the real MSB.
    slot_word={x,{(SLOT_W-SAMPLE_W){1'b0}}};
  endfunction
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin div_count<='0; bclk<=0; lrclk<=0; sdata<=0; bit_in_slot<='0; channel<=0; shift_reg<='0; end
    else if(div_count==DIV_LAST) begin
      div_count<='0; bclk<=~bclk;
      // bclk still contains its pre-toggle value in this clocked block.  A
      // previous value of one therefore identifies the actual falling edge.
      if(bclk) begin
        if(bit_in_slot==0) begin
          lrclk<=channel; sdata<=0; shift_reg<=channel?slot_word(right_sample):slot_word(left_sample); bit_in_slot<=1;
        end else begin
          sdata<=shift_reg[SLOT_W-1]; shift_reg<={shift_reg[SLOT_W-2:0],1'b0};
          if(bit_in_slot==SLOT_LAST) begin bit_in_slot<='0; channel<=~channel; end else bit_in_slot<=bit_in_slot+1'b1;
        end
      end
    end else div_count<=div_count+1'b1;
  end
endmodule
`default_nettype wire
