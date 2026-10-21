`default_nettype none
// Sliding fixed-length window. Byte/packet timeouts never assume UART read boundaries.
module wifi_packet_rx #(parameter integer CLK_HZ=12288000,
 BYTE_TIMEOUT=CLK_HZ/10,FRAME_TIMEOUT=CLK_HZ)(
 input wire clk,rst_n,byte_valid,byte_error,input wire [7:0] byte_data,
 output reg packet_valid,input wire packet_ready,
 output reg [7:0] packet_seq,packet_cmd,packet_len,
 output reg [47:0] packet_payload,
 output reg [31:0] crc_errors,format_errors,dropped_packets
);
 reg [119:0] history;reg [4:0] count;
 reg [31:0] idle_ticks,frame_ticks;
 wire [127:0] candidate={byte_data,history};
 function automatic [15:0] crc(input [95:0] bytes);
  reg [15:0] c;integer i,j;
  begin c=16'hffff;for(i=0;i<12;i=i+1)begin
   c=c^{bytes[i*8+:8],8'b0};
   for(j=0;j<8;j=j+1)c=c[15]?(c<<1)^16'h1021:c<<1;
  end crc=c;end
 endfunction
 wire header_ok=candidate[15:0]==16'h5aa5;
 wire crc_ok=crc(candidate[111:16])==candidate[127:112];
 wire format_ok=candidate[23:16]==1 && candidate[47:40]<=6 && candidate[111:96]==0;
 integer k;reg padding_ok;
 // Padding bytes outside payload length must be zero.
 always @* begin
  padding_ok=1;
  for(k=0;k<6;k=k+1)if(8'(k)>=candidate[47:40] && candidate[48+k*8+:8]!=0)padding_ok=0;
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  history<=0;count<=0;idle_ticks<=0;frame_ticks<=0;packet_valid<=0;
  packet_seq<=0;packet_cmd<=0;packet_len<=0;packet_payload<=0;
  crc_errors<=0;format_errors<=0;dropped_packets<=0;
 end else begin
  if(packet_valid && packet_ready)packet_valid<=0;
  if(count!=0)begin idle_ticks<=idle_ticks+1'b1;frame_ticks<=frame_ticks+1'b1;end
  if(byte_error || (count!=0 && (idle_ticks>=32'(BYTE_TIMEOUT-1) || frame_ticks>=32'(FRAME_TIMEOUT-1))))begin
   count<=0;history<=0;idle_ticks<=0;frame_ticks<=0;
  end else if(byte_valid)begin
   history<={byte_data,history[119:8]};idle_ticks<=0;
   if(count==0)frame_ticks<=0;
   if(count<15)count<=count+1'b1;
   if(count>=15 && header_ok)begin
    if(!crc_ok)crc_errors<=crc_errors+1'b1;
    else if(!format_ok || !padding_ok)format_errors<=format_errors+1'b1;
    else begin
     count<=0;history<=0;frame_ticks<=0;
     if(!packet_valid || packet_ready)begin
      packet_valid<=1;packet_seq<=candidate[31:24];packet_cmd<=candidate[39:32];
      packet_len<=candidate[47:40];packet_payload<=candidate[95:48];
     end else dropped_packets<=dropped_packets+1'b1;
    end
   end
  end
 end
endmodule
`default_nettype wire
