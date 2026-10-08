module saturator #(
    parameter IN_W  = 29,
    parameter OUT_W = 24
)(
    input  signed [IN_W-1:0]  in,
    output reg signed [OUT_W-1:0] out
);

reg signed [IN_W-1:0] max_v;
reg signed [IN_W-1:0] min_v;

always @(*) begin

    /* OUT_W 位有符号数最大值 */
    max_v = {
        {(IN_W-OUT_W){1'b0}},
        1'b0,
        {(OUT_W-1){1'b1}}
    };

    /* OUT_W 位有符号数最小值 */
    min_v = {
        {(IN_W-OUT_W){1'b1}},
        1'b1,
        {(OUT_W-1){1'b0}}
    };

    if (in > max_v)
        out = {1'b0, {(OUT_W-1){1'b1}}};

    else if (in < min_v)
        out = {1'b1, {(OUT_W-1){1'b0}}};

    else
        out = in[OUT_W-1:0];

end

endmodule
