`default_nettype none
// Source must hold/update the entire audio-domain bundle only when ready.
// Publish once at the pixel frame boundary, never sample a live multibit bus.
module visual_status_cdc(
 input wire source_clk,source_rst_n,update,input wire [511:0] status,
 output wire ready,input wire pixel_clk,pixel_rst_n,frame_start,
 output reg valid,output reg [511:0] snapshot
);
 reg [511:0] held;reg request,ack;reg [5:0] age;
 (* async_reg="true" *)reg ack1,ack2,req1,req2;
 assign ready=request==ack2;
 always @(posedge source_clk or negedge source_rst_n)
 if(!source_rst_n)begin held<=0;request<=0;ack1<=0;ack2<=0;end
 else begin ack1<=ack;ack2<=ack1;if(update && ready)begin held<=status;request<=~request;end end
 always @(posedge pixel_clk or negedge pixel_rst_n)
 if(!pixel_rst_n)begin req1<=0;req2<=0;ack<=0;valid<=0;snapshot<=0;age<=0;end
 else begin
  req1<=request;req2<=req1;
  if(frame_start && req2!=ack)begin snapshot<=held;valid<=1;ack<=req2;age<=0;end
  else if(frame_start)begin if(age<60)age<=age+1'b1;if(age>=59)valid<=0;end
 end
endmodule
`default_nettype wire
