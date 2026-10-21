`default_nettype none
module wifi_packet_tx(
 input wire clk,rst_n,response_valid,output wire response_ready,
 input wire [7:0] response_seq,input wire [47:0] response_payload,
 output wire byte_valid,input wire byte_ready,output wire [7:0] byte_data
);
 reg [127:0] shift;reg [4:0] remaining;
 wire [111:0] body={16'b0,response_payload,8'd6,8'h80,response_seq,8'd1,16'h5aa5};
 function automatic [15:0] crc(input [95:0] bytes);
  reg [15:0] c;integer i,j;
  begin c=16'hffff;for(i=0;i<12;i=i+1)begin c=c^{bytes[i*8+:8],8'b0};
   for(j=0;j<8;j=j+1)c=c[15]?(c<<1)^16'h1021:c<<1;
  end crc=c;end
 endfunction
 assign response_ready=remaining==0;
 assign byte_valid=remaining!=0;
 assign byte_data=shift[7:0];
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin shift<=0;remaining<=0;end
 else if(response_valid && response_ready)begin shift<={crc(body[111:16]),body};remaining<=16;end
 else if(byte_valid && byte_ready)begin shift<={8'b0,shift[127:8]};remaining<=remaining-1'b1;end
endmodule
`default_nettype wire
