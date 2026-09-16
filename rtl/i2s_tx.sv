`default_nettype none
module i2s_tx #(
  parameter int CLK_HZ=12288000, parameter int SAMPLE_RATE=48000,
  parameter int SAMPLE_W=24, parameter int SLOT_W=32
) (
  input logic clk, input logic rst_n,
  input logic signed [SAMPLE_W-1:0] left_sample, right_sample,
  output logic bclk, output logic lrclk, output logic sdata
);
  localparam int DIV_RAW=CLK_HZ/(SAMPLE_RATE*2*SLOT_W);
  localparam int DIV=(DIV_RAW<1)?1:DIV_RAW;
  localparam int DIV_W=(DIV<=1)?1:$clog2(DIV);
  localparam int BIT_W=$clog2(2*SLOT_W);
  logic [DIV_W-1:0] div_count;
  logic [BIT_W-1:0] bit_count;
  logic [2*SLOT_W-1:0] shift_reg;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin div_count<='0; bclk<=0; lrclk<=0; sdata<=0; bit_count<='0; shift_reg<='0; end
    else if(div_count==DIV-1) begin
      div_count<='0; bclk<=~bclk;
      if(!bclk) begin // data changes on falling edge; receiver samples rising
        if(bit_count==0) begin
          shift_reg <= {{(SLOT_W-SAMPLE_W){left_sample[SAMPLE_W-1]}},left_sample,{(SLOT_W-SAMPLE_W){right_sample[SAMPLE_W-1]}},right_sample};
          lrclk<=0; sdata<=0; bit_count<=1; // I2S one-bit delay after WS transition
        end else begin
          sdata<=shift_reg[2*SLOT_W-1]; shift_reg<={shift_reg[2*SLOT_W-2:0],1'b0};
          if(bit_count==SLOT_W) lrclk<=1;
          if(bit_count==2*SLOT_W-1) bit_count<=0; else bit_count<=bit_count+1'b1;
        end
      end
    end else div_count<=div_count+1'b1;
  end
endmodule
`default_nettype wire
