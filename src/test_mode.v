

module test_mode #(
    parameter VOICES = 32,
    parameter IDX_W  = 5
)(
    input                  enable,
    input  [IDX_W-1:0]     index,

    output reg             force_start,
    output reg [6:0]       midi_note
);

reg [6:0] index_extended;

always @(*) begin

    force_start = enable;

    index_extended = 7'd0;
    index_extended[IDX_W-1:0] = index;

    /*
     * 每个测试音相差两个半音
     *
     * index = 0 -> MIDI 36
     * index = 1 -> MIDI 38
     * index = 2 -> MIDI 40
     */
    midi_note = 7'd36 + (index_extended << 1);

end

endmodule
