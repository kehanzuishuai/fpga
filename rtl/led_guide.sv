`default_nettype none
module led_guide #(
  parameter int CLK_HZ=12000000, parameter int LED_COUNT=12, parameter int ADDR_W=5
) (
  input logic clk, input logic rst_n, input logic enable,
  input logic note_played, input logic [6:0] played_note,
  output logic [LED_COUNT-1:0] leds, output logic [6:0] target_note, output logic hit
);
  logic [ADDR_W-1:0] address; logic [15:0] duration_ms; logic valid;
  localparam int MS_DIV=(CLK_HZ/1000<1)?1:CLK_HZ/1000;
  localparam int CW=(MS_DIV<=1)?1:$clog2(MS_DIV);
  logic [CW-1:0] clk_count; logic [15:0] elapsed_ms;
  score_rom #(.ADDR_W(ADDR_W)) u_score(.address,.note(target_note),.duration_ms,.valid);
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin address<='0; clk_count<='0; elapsed_ms<='0; hit<=0; end
    else begin
      hit<=enable && note_played && played_note==target_note;
      if(!enable) begin address<='0; clk_count<='0; elapsed_ms<='0; end
      else if(hit) begin address<=address+1'b1; elapsed_ms<=0; end
      else if(clk_count==MS_DIV-1) begin clk_count<=0; if(elapsed_ms>=duration_ms) begin address<=address+1'b1; elapsed_ms<=0; end else elapsed_ms<=elapsed_ms+1'b1; end
      else clk_count<=clk_count+1'b1;
    end
  end
  always @* begin leds='0; if(enable && valid) leds[target_note % LED_COUNT]=1'b1; end
endmodule
`default_nettype wire
