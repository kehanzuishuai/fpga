`default_nettype none
// Stereo mailbox: the producer changes both channels together and holds them
// until acknowledged. Both domains share reset assertion, release is local.
module wav_remote(
 input wire clk_50m,clk_audio,rst_n,sample_tick,
 input wire spi_sck,spi_cs_n,spi_mosi,output wire spi_miso,
 output reg signed [23:0] left_pcm,right_pcm
);
 reg reset_meta,reset_50_n;
 always @(posedge clk_50m or negedge rst_n)
 if(!rst_n)begin reset_meta<=0;reset_50_n<=0;end
 else begin reset_meta<=1;reset_50_n<=reset_meta;end
 reg frame_toggle;
 always @(posedge clk_audio or negedge rst_n)
 if(!rst_n)frame_toggle<=0;else if(sample_tick)frame_toggle<=~frame_toggle;
 (* async_reg="true" *) reg frame_meta,frame_sync;reg frame_seen;
 wire frame_tick=frame_seen!=frame_sync;
 always @(posedge clk_50m or negedge reset_50_n)
 if(!reset_50_n)begin frame_meta<=0;frame_sync<=0;frame_seen<=0;end
 else begin frame_meta<=frame_toggle;frame_sync<=frame_meta;frame_seen<=frame_sync;end
 wire start,stop,finish,valid,ready;wire [7:0] data,state,error,transport_error;
 wire [31:0] size,played;wire [14:0] buffered;
 wire signed [23:0] l,r;
 wav_spi_stream stream(clk_50m,reset_50_n,spi_sck,spi_cs_n,spi_mosi,spi_miso,
 start,stop,finish,size,valid,ready,data,buffered,state,error,played,transport_error);
 wav_pcm_player player(clk_50m,reset_50_n,start,stop,finish,size,valid,ready,data,
 buffered,frame_tick,l,r,state,error,played);
 reg [47:0] hold_pcm;reg request;reg publish;
 (* async_reg="true" *) reg ack_meta,ack_sync;reg ack;
 (* async_reg="true" *) reg req_meta,req_sync;
 always @(posedge clk_50m or negedge reset_50_n)
 if(!reset_50_n)begin hold_pcm<=0;request<=0;publish<=0;ack_meta<=0;ack_sync<=0;end
 else begin
  ack_meta<=ack;ack_sync<=ack_meta;publish<=frame_tick || start || stop;
  if(publish && request==ack_sync)begin hold_pcm<={r,l};request<=~request;end
 end
 always @(posedge clk_audio or negedge rst_n)
 if(!rst_n)begin req_meta<=0;req_sync<=0;ack<=0;left_pcm<=0;right_pcm<=0;end
 else begin
  req_meta<=request;req_sync<=req_meta;
  if(req_sync!=ack)begin {right_pcm,left_pcm}<=hold_pcm;ack<=req_sync;end
 end
endmodule
`default_nettype wire
