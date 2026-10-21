`default_nettype none
// Stable bundled-data mailbox: no audio backpressure. Pixel updates at vblank.
module piano_status_cdc #(parameter W=58)(
 input wire audio_clk,audio_rst_n,update,input wire [W-1:0] audio_data,
 input wire pixel_clk,pixel_rst_n,frame_start,output reg [W-1:0] pixel_data
);
 reg [W-1:0] hold_data;reg request,ack;
 (* async_reg="true" *) reg ack_meta,ack_sync,request_meta,request_sync;
 always @(posedge audio_clk or negedge audio_rst_n)
 if(!audio_rst_n)begin hold_data<=0;request<=0;ack_meta<=0;ack_sync<=0;end
 else begin
  ack_meta<=ack;ack_sync<=ack_meta;
  if(update && request==ack_sync)begin hold_data<=audio_data;request<=~request;end
 end
 always @(posedge pixel_clk or negedge pixel_rst_n)
 if(!pixel_rst_n)begin request_meta<=0;request_sync<=0;ack<=0;pixel_data<=0;end
 else begin
  request_meta<=request;request_sync<=request_meta;
  if(frame_start && request_sync!=ack)begin pixel_data<=hold_data;ack<=request_sync;end
 end
endmodule
`default_nettype wire
