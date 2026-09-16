`default_nettype none
module uart_tx #(
  parameter int CLK_HZ=12000000, parameter int BAUD=115200
) (
  input logic clk, input logic rst_n, input logic valid, input logic [7:0] data,
  output logic ready, output logic tx
);
  localparam int DIV_RAW=CLK_HZ/BAUD;
  localparam int DIV=(DIV_RAW<1)?1:DIV_RAW;
  localparam int CW=(DIV<=1)?1:$clog2(DIV);
  localparam integer DIV_LAST_INT=DIV-1;
  localparam logic [CW-1:0] DIV_LAST=DIV_LAST_INT[CW-1:0];
  logic [CW-1:0] count; logic [3:0] bit_idx; logic [9:0] frame; logic busy;
  assign ready=!busy;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin count<='0; bit_idx<='0; frame<=10'h3ff; busy<=0; tx<=1; end
    else if(!busy) begin tx<=1; if(valid) begin frame<={1'b1,data,1'b0}; busy<=1; bit_idx<=0; count<=0; tx<=0; end end
    else if(count==DIV_LAST) begin
      count<=0;
      if(bit_idx==9) begin
        // The complete stop-bit interval has elapsed.  Releasing ready here
        // allows a following byte without shortening the stop bit.
        busy<=0; tx<=1;
      end else begin
        bit_idx<=bit_idx+1'b1; tx<=frame[bit_idx+1];
      end
    end
    else count<=count+1'b1;
  end
endmodule
`default_nettype wire
