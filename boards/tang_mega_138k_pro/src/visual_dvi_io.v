`default_nettype none
// DVI-compatible RGB over HDMI connector: no audio/data islands/HDCP.
// OSER10 bit0 first, DDR5x, dedicated differential output primitives.
module visual_dvi_io(input wire pixel_clk,serial_clk,rst_n,
 input wire [9:0] blue,green,red,
 output wire [2:0] d_p,d_n,output wire ck_p,ck_n);
 wire [2:0] serial_data;
 genvar i;
 generate for(i=0;i<3;i=i+1)begin:channels
   wire [9:0] word_data;
   assign word_data=(i==0)?blue:((i==1)?green:red);
   OSER10 serializer(.Q(serial_data[i]),.D0(word_data[0]),.D1(word_data[1]),
   .D2(word_data[2]),.D3(word_data[3]),.D4(word_data[4]),.D5(word_data[5]),
   .D6(word_data[6]),.D7(word_data[7]),.D8(word_data[8]),.D9(word_data[9]),
   .PCLK(pixel_clk),.FCLK(serial_clk),.RESET(~rst_n));
   ELVDS_OBUF differential(.I(serial_data[i]),.O(d_p[i]),.OB(d_n[i]));
 end endgenerate
 ELVDS_OBUF clock_differential(.I(pixel_clk),.O(ck_p),.OB(ck_n));
endmodule
`default_nettype wire
