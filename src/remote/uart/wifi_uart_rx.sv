`default_nettype none
// Fractional bit timer, synchronized input, 8N1, centre-of-bit sampling.
module wifi_uart_rx #(parameter integer CLK_HZ=12288000,BAUD=115200)(
 input wire clk,rst_n,rx,output reg [7:0] data,
 output reg valid,framing_error
);
 reg meta,sync;reg [2:0] state;reg [31:0] timer;
 reg [2:0] bit_index;reg [7:0] shift;
 localparam [2:0] IDLE=0,START=1,DATA=2,STOP=3,RECOVER=4;
 localparam [31:0] RATE=32'(BAUD),CLOCK=32'(CLK_HZ);
 initial if(BAUD<1 || CLK_HZ<BAUD*8 || CLK_HZ>1000000000)$fatal(1,"UART parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin meta<=1;sync<=1;end else begin meta<=rx;sync<=meta;end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin state<=IDLE;timer<=0;bit_index<=0;shift<=0;data<=0;valid<=0;framing_error<=0;end
 else begin
  valid<=0;framing_error<=0;
  case(state)
   IDLE:begin timer<=0;if(!sync)state<=START;end
   START:if(timer>=CLOCK-2*RATE)begin
    timer<=0;if(!sync)begin state<=DATA;bit_index<=0;end else state<=IDLE;
   end else timer<=timer+2*RATE;
   DATA:if(timer>=CLOCK-RATE)begin
    timer<=timer+RATE-CLOCK;shift[bit_index]<=sync;
    if(bit_index==7)state<=STOP;else bit_index<=bit_index+1'b1;
   end else timer<=timer+RATE;
   STOP:if(timer>=CLOCK-RATE)begin
    timer<=0;
    if(sync)begin data<=shift;valid<=1;state<=IDLE;end
    else begin framing_error<=1;state<=RECOVER;end
   end else timer<=timer+RATE;
   RECOVER:if(sync)state<=IDLE;
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire
