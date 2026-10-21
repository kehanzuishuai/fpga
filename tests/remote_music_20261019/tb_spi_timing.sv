`timescale 1ns/1ps
module tb_spi_timing;
 reg clk=0,rst_n=0,sck=0,cs=1,mosi=0;always #10 clk=~clk;
 wire miso,start,stop,finish,valid;wire [31:0] size;wire [7:0] data,transport;
 wire [14:0] buffered;
 reg [7:0] player_state=0,player_error=0;
 reg [31:0] frames=0;
 wav_spi_stream dut(clk,rst_n,sck,cs,mosi,miso,start,stop,finish,size,
  valid,1'b1,data,buffered,player_state,player_error,frames,transport);
 reg changing=0;
 always @(negedge clk)if(changing)begin
  frames=frames+32'h1020305;player_state=frames[7:0];player_error=~frames[7:0];
 end
 function automatic [15:0] crc_byte(input [15:0] c,input [7:0] b);
  reg [15:0] x;integer k;
  begin x=c^{b,8'd0};for(k=0;k<8;k=k+1)x=x[15]?(x<<1)^16'h1021:x<<1;crc_byte=x;end
 endfunction
 task automatic spi_byte(input [7:0] tx,output reg [7:0] rx);
  integer n;begin rx=0;for(n=7;n>=0;n=n-1)begin
   mosi=tx[n];#125;rx={rx[6:0],miso};sck=1;#125;sck=0;
  end end
 endtask
 reg [7:0] response[0:23];reg [191:0] snapshot;reg [15:0] crc;
 integer i,j;
 initial begin
  repeat(5)@(negedge clk);rst_n=1;changing=1;#1000;
  for(j=0;j<8;j=j+1)begin
   cs=0;#1000;snapshot=dut.status_hold;
   for(i=0;i<24;i=i+1)spi_byte(i==0?8'h57:i==1?8'h41:i==2?8'd1:8'd0,response[i]);
   #500;cs=1;#1000;
   crc=16'hffff;
   for(i=0;i<22;i=i+1)crc=crc_byte(crc,response[i]);
   if({response[23],response[22]}!==crc)$fatal(1,"two-stage CRC/body mismatch");
   for(i=0;i<24;i=i+1)if(response[i]!==snapshot[8*i+:8])$fatal(1,"status changed within CS");
   if(response[0]!=8'h57 || response[1]!=8'h41 || response[2]!=1)$fatal(1,"header");
   if(response[9]!==response[16] || response[10]!==~response[16])$fatal(1,"incoherent body snapshot");
   if({response[7],response[6]}!=16384 || buffered!=0 || transport!=0)$fatal(1,"idle capacity/status");
  end
  $display("PASS SPI timing pipeline: 8 real 4MHz status transactions, independent CRC, moving fields coherent, CS snapshot stable");$finish;
 end
 initial begin #1000000;$fatal(1,"SPI timing timeout");end
endmodule
