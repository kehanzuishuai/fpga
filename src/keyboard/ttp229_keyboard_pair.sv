`default_nettype none
// Two independent 16-key transports. An error on either reader cannot suppress
// a valid frame from the other. Logical key 0..15 belongs to bank 0, 16..31 to 1.
module ttp229_keyboard_pair #(
 // 12.288MHz: SCL=245.76kHz (<512kHz), idle=10.01us (>=10us).
 // Keep 2.10ms between bursts: above the chip's 2ms serial reset timeout.
 // Retain two-frame confirmation and independent stuck-SDO protection.
 parameter integer HALF_TICKS=25,GAP_TICKS=25805,IDLE_TICKS=123,
 parameter integer PROFILE0=1,PROFILE1=1,RAW_MAP0=0,RAW_MAP1=0,
 parameter [63:0] RAW_INDEX0=64'hfedcba9876543210,
 parameter [63:0] RAW_INDEX1=64'hfedcba9876543210,
 parameter [223:0] NOTES={7'd91,7'd90,7'd89,7'd88,7'd87,7'd86,7'd85,7'd84,
 7'd83,7'd82,7'd81,7'd80,7'd79,7'd78,7'd77,7'd76,
 7'd75,7'd74,7'd73,7'd72,7'd71,7'd70,7'd69,7'd68,
 7'd67,7'd66,7'd65,7'd64,7'd63,7'd62,7'd61,7'd60}
)(
 input wire clk,rst_n,
 output wire scl0,scl1,input wire sdo0,sdo1,
 output wire [31:0] key_state,accepted_raw,raw_frame,reader_state,
 output wire [1:0] accepted_frame,frame_error,reader_busy,mode16_seen,mode8_suspect,
 output wire mapping_error,output wire [63:0] rejected_frames
);
 function automatic integer unique_notes();
  integer a,b;
  begin
   unique_notes=1;
   for(a=0;a<32;a=a+1)for(b=0;b<a;b=b+1)
    if(NOTES[a*7+:7]==NOTES[b*7+:7])unique_notes=0;
  end
 endfunction
 localparam integer NOTES_OK=unique_notes();
 wire [1:0] valid,map_error;
 wire [1:0] scl;wire [1:0] sdo={sdo1,sdo0};
 assign {scl1,scl0}=scl;
 assign mapping_error=(NOTES_OK==0) || (|map_error);
 genvar n;
 generate for(n=0;n<2;n=n+1)begin:G_BANK
  ttp229_reader #(.HALF_TICKS(HALF_TICKS),.GAP_TICKS(GAP_TICKS),
   .IDLE_TICKS(IDLE_TICKS),.ACTIVE_LOW(1),.STRICT_IDLE(1),.CONFIRM(1),
   .MIRROR_GUARD((n==0 ? PROFILE0 : PROFILE1)==0)) reader(
   .clk(clk),.rst_n(rst_n),.ttp229_scl(scl[n]),.ttp229_sdo(sdo[n]),
   .key_state(reader_state[n*16+:16]),.frame_valid(valid[n]),
   .frame_error(frame_error[n]),.reader_busy(reader_busy[n]),
   .raw_frame(raw_frame[n*16+:16]),.mode16_seen(mode16_seen[n]),
   .mode8_suspect(mode8_suspect[n]));
  keyboard_state_mapper #(.KEYS(16),.INDEX_W(4),
   .RAW_MAP_ENABLE(n==0 ? RAW_MAP0 : RAW_MAP1),
   .RAW_INDEX_TABLE(n==0 ? RAW_INDEX0 : RAW_INDEX1),
   .NOTE_TABLE(NOTES[n*112+:112]),.CHECK_NOTE_UNIQUE(1)) mapper(
   .clk(clk),.rst_n(rst_n),.frame_valid(valid[n]),
   .frame_error(frame_error[n] || (valid[n] && !NOTES_OK)),
   .raw_keys(reader_state[n*16+:16]),.key_state(key_state[n*16+:16]),
   .accepted_raw(accepted_raw[n*16+:16]),.accepted_frame(accepted_frame[n]),
   .mapping_error(map_error[n]),.rejected_frames(rejected_frames[n*32+:32]));
 end endgenerate
endmodule
`default_nettype wire
