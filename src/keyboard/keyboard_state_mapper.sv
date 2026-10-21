`default_nettype none
// Transport-independent complete-frame admission and raw-bit permutation.
// KEY_RAW_INDEX_TABLE[key*INDEX_W+:INDEX_W] selects the raw bit for a key.
// No event/audio backpressure. Invalid frames hold the last accepted state.
module keyboard_state_mapper #(
 parameter integer KEYS=16, INDEX_W=4, RAW_MAP_ENABLE=0,
 parameter [KEYS*INDEX_W-1:0] RAW_INDEX_TABLE=0,
 parameter [KEYS*7-1:0] NOTE_TABLE=0,
 parameter integer CHECK_NOTE_UNIQUE=0
)(
 input wire clk,rst_n,frame_valid,frame_error,
 input wire [KEYS-1:0] raw_keys,
 output reg [KEYS-1:0] key_state,accepted_raw,
 output reg accepted_frame,
 output wire mapping_error,
 output reg [31:0] rejected_frames
);
 function automatic integer raw_index(input integer key);
  raw_index=RAW_MAP_ENABLE ? int'(RAW_INDEX_TABLE[key*INDEX_W+:INDEX_W]) : key;
 endfunction
 function automatic integer valid_configuration();
  integer a,b;
  begin
   valid_configuration=1;
   for(a=0;a<KEYS;a=a+1)begin
    if(raw_index(a)>=KEYS)valid_configuration=0;
    for(b=0;b<a;b=b+1)begin
     if(raw_index(a)==raw_index(b))valid_configuration=0;
     if(CHECK_NOTE_UNIQUE && NOTE_TABLE[a*7+:7]==NOTE_TABLE[b*7+:7])
      valid_configuration=0;
    end
   end
  end
 endfunction
 localparam integer MAP_OK=valid_configuration();
 assign mapping_error=(MAP_OK==0);
 wire [KEYS-1:0] mapped;
 genvar k;
 generate for(k=0;k<KEYS;k=k+1)begin:G_KEY
  localparam integer BIT_INDEX=raw_index(k);
  if(BIT_INDEX<KEYS)assign mapped[k]=raw_keys[BIT_INDEX];
  else assign mapped[k]=1'b0;
 end endgenerate
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin key_state<=0;accepted_raw<=0;accepted_frame<=0;rejected_frames<=0;end
 else begin
  accepted_frame<=0;
  if(frame_error || (frame_valid && mapping_error))rejected_frames<=rejected_frames+1'b1;
  if(frame_valid && !frame_error && !mapping_error)begin
   key_state<=mapped;accepted_raw<=raw_keys;accepted_frame<=1;
  end
 end
`ifndef SYNTHESIS
 initial if(KEYS<1 || KEYS>(1<<INDEX_W))$fatal(1,"keyboard_state_mapper index width invalid");
`endif
endmodule
`default_nettype wire
