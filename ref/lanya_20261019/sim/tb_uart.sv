`timescale 1ns/1ps
module tb_uart;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0,rx=1,valid=0;reg [7:0] data=0;
 wire [7:0] received;wire got,err,ready,tx;
 integer count=0,errors=0,i,n,p;reg [7:0] expected;
 wifi_uart_rx #(.CLK_HZ(12288000),.BAUD(115200)) dut(.clk(clk),.rst_n(rst_n),.rx(rx),.data(received),.valid(got),.framing_error(err));
 wire [7:0] loop_data;wire loop_got,loop_err;
 wifi_uart_tx #(.CLK_HZ(12288000),.BAUD(115200)) sender(.clk(clk),.rst_n(rst_n),.valid(valid),.data(data),.ready(ready),.tx(tx));
 wifi_uart_rx #(.CLK_HZ(12288000),.BAUD(115200)) receiver(.clk(clk),.rst_n(rst_n),.rx(tx),.data(loop_data),.valid(loop_got),.framing_error(loop_err));
 always @(posedge clk)begin
 if(got)begin if(received!==expected)$fatal(1,"RX value");count=count+1;end
 if(err)errors=errors+1;
 if(loop_err)$fatal(1,"loop frame error");
 end
 task byte_send(input [7:0] x,input integer period,input bit stop_good);
 begin expected=x;@(negedge clk);rx=0;repeat(period)@(negedge clk);
 for(i=0;i<8;i=i+1)begin rx=x[i];repeat(period)@(negedge clk);end
 rx=stop_good;repeat(period)@(negedge clk);rx=1;repeat(period)@(negedge clk);end endtask
 initial begin
 repeat(4)@(negedge clk);rst_n=1;
 for(p=104;p<=110;p=p+1)begin byte_send(0,p,1);byte_send(8'ha5,p,1);byte_send(8'h5a,p,1);byte_send(255,p,1);end
 if(count!=28)$fatal(1,"baud tolerance");
 @(negedge clk);rx=0;repeat(10)@(negedge clk);rx=1;repeat(300)@(negedge clk);if(count!=28)$fatal(1,"false start");
 byte_send(8'h33,107,0);if(errors!=1||count!=28)$fatal(1,"bad stop");
 @(negedge clk);rx=0;repeat(3000)@(negedge clk);rx=1;repeat(200)@(negedge clk);
 byte_send(8'h69,107,1);if(count!=29)$fatal(1,"break recovery");
 for(n=0;n<256;n=n+1)begin
 @(negedge clk);while(!ready)@(negedge clk);valid=1;data=8'(n);@(negedge clk);valid=0;
 wait(loop_got);#1;if(loop_data!=8'(n))$fatal(1,"TX/RX loopback %d",n);
 end
 $display("PASS UART: +/-3 percent bit periods, false start, bad stop, break recovery, 256 TX/RX bytes");$finish;
 end
 initial begin #10000000;$fatal(1,"watchdog");end
endmodule
