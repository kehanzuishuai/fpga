`default_nettype none
// Reader already confirms each press with two serial frames. Preserve that
// attack latency; require a longer, independent release confirmation per key.
module keyboard_key_debounce #(
 parameter integer KEYS=16,RELEASE_FRAMES=6,
 parameter integer COUNT_W=(RELEASE_FRAMES<2)?1:$clog2(RELEASE_FRAMES)
)(
 input wire clk,rst_n,frame_valid,frame_error,
 input wire [KEYS-1:0] sampled_keys,
 output reg [KEYS-1:0] key_state,
 output reg accepted_frame
);
 reg [COUNT_W-1:0] released[0:KEYS-1];
 integer k;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  key_state<=0;accepted_frame<=0;
  for(k=0;k<KEYS;k=k+1)released[k]<=0;
 end else begin
  accepted_frame<=0;
  if(frame_error)begin
   // An invalid frame is not evidence that a key was released. It also
   // breaks the consecutive-valid-frame release confirmation.
   for(k=0;k<KEYS;k=k+1)released[k]<=0;
  end else if(frame_valid)begin
   accepted_frame<=1;
   for(k=0;k<KEYS;k=k+1)begin
    if(sampled_keys[k])begin
     key_state[k]<=1;released[k]<=0;
    end else if(key_state[k])begin
     if(released[k]>=COUNT_W'(RELEASE_FRAMES-1))begin
      key_state[k]<=0;released[k]<=0;
     end else released[k]<=released[k]+1'b1;
    end else released[k]<=0;
   end
  end
 end
`ifndef SYNTHESIS
 initial if(KEYS<1||RELEASE_FRAMES<1)$fatal(1,"keyboard debounce parameters");
`endif
endmodule
`default_nettype wire
