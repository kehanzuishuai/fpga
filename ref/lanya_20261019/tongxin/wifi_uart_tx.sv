`default_nettype none
module wifi_uart_tx #(parameter integer CLK_HZ=12288000,BAUD=115200)(
 input wire clk,rst_n,valid,input wire [7:0] data,
 output wire ready,output reg tx
);
 reg busy;reg [3:0] index;reg [8:0] bits;
 reg [31:0] timer;
 localparam [31:0] RATE=32'(BAUD),CLOCK=32'(CLK_HZ);
 assign ready=!busy;
 initial if(BAUD<1 || CLK_HZ<BAUD*8)$fatal(1,"UART parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin busy<=0;index<=0;bits<=9'h1ff;timer<=0;tx<=1;end
 else if(!busy)begin
  tx<=1;timer<=0;
  if(valid)begin bits<={1'b1,data};tx<=0;busy<=1;index<=0;end
 end else if(timer>=CLOCK-RATE)begin
  timer<=timer+RATE-CLOCK;
  if(index==9)begin busy<=0;tx<=1;end
  else begin index<=index+1'b1;bits<={1'b1,bits[8:1]};tx<=bits[0];end
 end else timer<=timer+RATE;
endmodule
`default_nettype wire
