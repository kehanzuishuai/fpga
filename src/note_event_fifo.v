
module note_event_fifo #(
    parameter DEPTH  = 16,
    parameter ADDR_W = 4
)(
    input                     clk,
    input                     rst_n,

    input                     in_valid,
    output                    in_ready,
    input                     in_note_on,
    input      [6:0]          in_note,
    input      [7:0]          in_velocity,
    input      [1:0]          in_waveform,

    output                    out_valid,
    input                     out_ready,
    output                    out_note_on,
    output     [6:0]          out_note,
    output     [7:0]          out_velocity,
    output     [1:0]          out_waveform,

    output reg [ADDR_W:0]     level
);

reg [ADDR_W-1:0] wr_ptr;
reg [ADDR_W-1:0] rd_ptr;

localparam [ADDR_W:0]   DEPTH_LEVEL = DEPTH;
localparam [ADDR_W-1:0] LAST_ADDR   = DEPTH - 1;

reg [DEPTH-1:0]    note_on_mem;
reg [DEPTH*7-1:0]  note_mem;
reg [DEPTH*8-1:0]  velocity_mem;
reg [DEPTH*2-1:0]  waveform_mem;

assign in_ready  = (level < DEPTH_LEVEL);
assign out_valid = (level != {(ADDR_W+1){1'b0}});

assign out_note_on  = note_on_mem[rd_ptr];
assign out_note     = note_mem[rd_ptr*7 +: 7];
assign out_velocity = velocity_mem[rd_ptr*8 +: 8];
assign out_waveform = waveform_mem[rd_ptr*2 +: 2];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr       <= {ADDR_W{1'b0}};
        rd_ptr       <= {ADDR_W{1'b0}};
        level        <= {(ADDR_W+1){1'b0}};
        note_on_mem  <= {DEPTH{1'b0}};
        note_mem     <= {(DEPTH*7){1'b0}};
        velocity_mem <= {(DEPTH*8){1'b0}};
        waveform_mem <= {(DEPTH*2){1'b0}};
    end
    else begin
        case ({(in_valid && in_ready), (out_valid && out_ready)})
            2'b10: level <= level + 1'b1;
            2'b01: level <= level - 1'b1;
            default: level <= level;
        endcase

        if (in_valid && in_ready) begin
            note_on_mem[wr_ptr]          <= in_note_on;
            note_mem[wr_ptr*7 +: 7]      <= in_note;
            velocity_mem[wr_ptr*8 +: 8]  <= in_velocity;
            waveform_mem[wr_ptr*2 +: 2]  <= in_waveform;

            if (wr_ptr == LAST_ADDR)
                wr_ptr <= {ADDR_W{1'b0}};
            else
                wr_ptr <= wr_ptr + 1'b1;
        end

        if (out_valid && out_ready) begin
            if (rd_ptr == LAST_ADDR)
                rd_ptr <= {ADDR_W{1'b0}};
            else
                rd_ptr <= rd_ptr + 1'b1;
        end
    end
end

endmodule
