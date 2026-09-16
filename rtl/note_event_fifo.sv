`default_nettype none
// One event per cycle, parameterized ring buffer. Keeps rapid note gestures
// lossless until the allocator consumes them; no board clock assumptions.
module note_event_fifo #(
  parameter int DEPTH=16, parameter int ADDR_W=$clog2(DEPTH)
) (
  input logic clk, input logic rst_n,
  input logic in_valid, output logic in_ready, input logic in_note_on,
  input logic [6:0] in_note, input logic [7:0] in_velocity,
  input logic [1:0] in_waveform, input logic [9:0] in_morph,
  output logic out_valid, input logic out_ready, output logic out_note_on,
  output logic [6:0] out_note, output logic [7:0] out_velocity,
  output logic [1:0] out_waveform, output logic [9:0] out_morph,
  output logic [ADDR_W:0] level
);
  logic [ADDR_W-1:0] wr_ptr,rd_ptr;
  localparam logic [ADDR_W:0] DEPTH_LEVEL=DEPTH[ADDR_W:0];
  localparam integer LAST_ADDR_INT=DEPTH-1;
  localparam logic [ADDR_W-1:0] LAST_ADDR=LAST_ADDR_INT[ADDR_W-1:0];
  // Packed storage is intentional: the FIFO is shallow control/event state,
  // not a vendor RAM.  This gives portable asynchronous head visibility and
  // avoids tool-dependent memory-to-register rewriting.
  logic [DEPTH-1:0] note_on_mem;
  logic [DEPTH*7-1:0] note_mem; logic [DEPTH*8-1:0] velocity_mem;
  logic [DEPTH*2-1:0] waveform_mem; logic [DEPTH*10-1:0] morph_mem;
  assign in_ready=(level<DEPTH_LEVEL); assign out_valid=(level!='0);
  assign out_note_on=note_on_mem[rd_ptr];
  assign out_note=note_mem[rd_ptr*7 +: 7]; assign out_velocity=velocity_mem[rd_ptr*8 +: 8];
  assign out_waveform=waveform_mem[rd_ptr*2 +: 2]; assign out_morph=morph_mem[rd_ptr*10 +: 10];
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wr_ptr<='0; rd_ptr<='0; level<='0; note_on_mem<='0; note_mem<='0;
      velocity_mem<='0; waveform_mem<='0; morph_mem<='0;
    end
    else begin
      case ({in_valid&&in_ready,out_valid&&out_ready})
        2'b10: level<=level+1'b1;
        2'b01: level<=level-1'b1;
        default: level<=level;
      endcase
      if(in_valid&&in_ready) begin
        note_on_mem[wr_ptr]<=in_note_on; note_mem[wr_ptr*7 +: 7]<=in_note;
        velocity_mem[wr_ptr*8 +: 8]<=in_velocity; waveform_mem[wr_ptr*2 +: 2]<=in_waveform;
        morph_mem[wr_ptr*10 +: 10]<=in_morph;
        wr_ptr<=(wr_ptr==LAST_ADDR)?'0:wr_ptr+1'b1;
      end
      if(out_valid&&out_ready) rd_ptr<=(rd_ptr==LAST_ADDR)?'0:rd_ptr+1'b1;
    end
  end
endmodule
`default_nettype wire
