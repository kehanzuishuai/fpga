`timescale 1ns/1ps
module tb_packet;
 reg clk=0;always #5 clk=~clk;
 reg rst_n=0,bv=0,be=0,ready=1;reg [7:0] bd=0;
 wire valid;wire [7:0] seq,cmd,len;wire [47:0] payload;wire [31:0] ce,fe,de;
 integer accepted=0,i,j;reg [127:0] frame;
 wifi_packet_rx #(.CLK_HZ(1000),.BYTE_TIMEOUT(30),.FRAME_TIMEOUT(300)) dut(
 .clk(clk),.rst_n(rst_n),.byte_valid(bv),.byte_error(be),.byte_data(bd),
 .packet_valid(valid),.packet_ready(ready),.packet_seq(seq),.packet_cmd(cmd),.packet_len(len),.packet_payload(payload),
 .crc_errors(ce),.format_errors(fe),.dropped_packets(de));
 always @(posedge clk)if(valid&&ready)accepted=accepted+1;
 function [15:0] crc(input [95:0] bytes);
  reg [15:0] c;integer a,b;begin c=16'hffff;for(a=0;a<12;a=a+1)begin c=c^{bytes[a*8+:8],8'b0};
  for(b=0;b<8;b=b+1)c=c[15]?(c<<1)^16'h1021:c<<1;end crc=c;end
 endfunction
 task make(input [7:0] s,c,l,input [47:0] p);
 begin frame={16'b0,16'b0,p,l,c,s,8'd1,16'h5aa5};frame[127:112]=crc(frame[111:16]);end endtask
 task byte_send(input [7:0] x);begin @(negedge clk);bv=1;bd=x;@(negedge clk);bv=0;end endtask
 task send;begin for(i=0;i<16;i=i+1)byte_send(frame[i*8+:8]);repeat(3)@(negedge clk);end endtask
 initial begin
 repeat(3)@(negedge clk);rst_n=1;
 make(1,16,1,2);send();if(accepted!=1)$fatal(1,"good frame");
 make(2,18,2,16'h5aa5);send();if(accepted!=2)$fatal(1,"embedded header");
 frame[120]=~frame[120];send();if(ce!=1||accepted!=2)$fatal(1,"crc");
 make(3,1,0,1);send();if(fe!=1)$fatal(1,"padding");
 make(3,1,7,0);send();if(fe!=2)$fatal(1,"length");
 make(3,1,0,0);frame[16+:8]=2;frame[127:112]=crc(frame[111:16]);send();if(fe!=3)$fatal(1,"version");
 make(3,1,0,0);frame[96]=1;frame[127:112]=crc(frame[111:16]);send();if(fe!=4)$fatal(1,"reserved");
 make(4,1,0,0);for(i=0;i<8;i=i+1)byte_send(frame[i*8+:8]);repeat(35)@(negedge clk);
 for(i=8;i<16;i=i+1)byte_send(frame[i*8+:8]);if(accepted!=2)$fatal(1,"timeout accepted");
 repeat(35)@(negedge clk);make(5,1,0,0);send();if(accepted!=3)$fatal(1,"timeout recovery");
 byte_send(8'ha5);@(negedge clk);be=1;@(negedge clk);be=0;make(6,1,0,0);send();if(accepted!=4)$fatal(1,"framing recovery");
 ready=0;make(7,1,0,0);send();make(8,1,0,0);send();if(de!=1||seq!=7)$fatal(1,"overflow packet atomicity");
 ready=1;repeat(3)@(negedge clk);
 // Slow drip exceeds total timeout while every byte remains within byte timeout.
 repeat(35)@(negedge clk);make(9,1,0,0);
 for(j=0;j<16;j=j+1)begin byte_send(frame[j*8+:8]);repeat(22)@(negedge clk);end
 if(accepted!=5)$fatal(1,"total deadline");
 repeat(35)@(negedge clk);make(10,1,0,0);send();if(accepted!=6)$fatal(1,"recovery");
 $display("PASS parser: CRC, padding, header in payload, format, byte/frame deadline, UART error, held output and packet drops");$finish;
 end
 initial begin #1000000;$fatal(1,"watchdog");end
endmodule
