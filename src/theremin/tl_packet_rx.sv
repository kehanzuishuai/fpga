`default_nettype none
// Sliding 16-byte window: embedded headers, truncation and byte loss recover
// without trusting a header that happens to occur inside a valid payload.
module tl_packet_rx #(parameter integer CLK_HZ=12288000,INTERBYTE_MS=2,FRAME_MS=5)(
 input wire clk,rst_n,byte_valid,input wire [7:0] byte_data,input wire byte_error,
 output reg packet_valid,output reg [7:0] sequence_id,flags,
 output reg [31:0] frequency_mhz,output reg [15:0] amplitude,timestamp_ms,
 output reg [31:0] crc_errors,format_errors
);
 reg [119:0] window;reg [4:0] count;reg [31:0] age,frame_age;
 wire [127:0] candidate={window,byte_data};
 localparam [31:0] LAST=32'((CLK_HZ/1000)*INTERBYTE_MS-1);
 localparam [31:0] FRAME_LAST=32'((CLK_HZ/1000)*FRAME_MS-1);
 function automatic [15:0] crc12(input [95:0] bytes);
  reg [15:0] c;integer i,j;
  begin c=16'hffff;
   for(i=11;i>=0;i=i-1)begin
    c=c^{bytes[i*8 +: 8],8'b0};
    for(j=0;j<8;j=j+1)c=c[15]?(c<<1)^16'h1021:c<<1;
   end
   crc12=c;
  end
 endfunction
 wire header=candidate[127:112]==16'ha55a;
 wire crc_ok=crc12(candidate[111:16])=={candidate[7:0],candidate[15:8]};
 wire format_ok=candidate[111:104]==1 && candidate[39:32]==0 && candidate[95:93]==0;
 initial if(CLK_HZ<1000 || INTERBYTE_MS<1 || FRAME_MS<INTERBYTE_MS)$fatal(1,"packet timing parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  window<=0;count<=0;age<=0;frame_age<=0;packet_valid<=0;sequence_id<=0;flags<=0;
  frequency_mhz<=0;amplitude<=0;timestamp_ms<=0;crc_errors<=0;format_errors<=0;
 end else begin
  packet_valid<=0;
  if(count==0)frame_age<=0;else if(frame_age<FRAME_LAST)frame_age<=frame_age+1'b1;
  if(byte_error || (count!=0 && frame_age==FRAME_LAST))begin count<=0;window<=0;age<=0;frame_age<=0;end
  else if(byte_valid)begin
   age<=0;window<=candidate[119:0];
   if(count<15)count<=count+1'b1;
   if(count>=15 && header)begin
    if(!crc_ok)crc_errors<=crc_errors+1'b1;
    else if(!format_ok)format_errors<=format_errors+1'b1;
    else begin
     sequence_id<=candidate[103:96];flags<=candidate[95:88];
     frequency_mhz<={candidate[63:56],candidate[71:64],candidate[79:72],candidate[87:80]};
     amplitude<={candidate[47:40],candidate[55:48]};
     timestamp_ms<={candidate[23:16],candidate[31:24]};packet_valid<=1;
     count<=0;window<=0;
    end
   end
  end else if(count!=0)begin
   if(age==LAST)begin count<=0;window<=0;age<=0;end else age<=age+1'b1;
  end
 end
endmodule
`default_nettype wire
