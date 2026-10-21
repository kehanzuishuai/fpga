`default_nettype none
// DVI-compatible RGB over HDMI connector: no audio/data islands/HDCP.
// OSER10 bit0 first, DDR5x, dedicated differential output primitives.
module visual_dvi_io(input wire pixel_clk,serial_clk,rst_n,
 input wire [9:0] blue,green,red,
 output wire [2:0] d_p,d_n,output wire ck_p,ck_n,input wire reset_clk);
 // Buffer the serializer clock through the global clock selector so fabric
 // the hard IOLOGIC clock has controlled insertion delay. Fabric reset logic
 // uses the separate74.25MHz clock, avoiding371.25MHz fabric pulse limits.
 wire serial_global;
 DCS serial_buffer(.CLKIN0(serial_clk),.CLKIN1(1'b0),.CLKIN2(1'b0),.CLKIN3(1'b0),.CLKSEL(4'b0001),.SELFORCE(1'b1),.CLKOUT(serial_global));
 defparam serial_buffer.DCS_MODE="CLK0";
 wire reset_regional;
 DCS reset_buffer(.CLKIN0(reset_clk),.CLKIN1(1'b0),.CLKIN2(1'b0),.CLKIN3(1'b0),.CLKSEL(4'b0001),.SELFORCE(1'b1),.CLKOUT(reset_regional));
 defparam reset_buffer.DCS_MODE="CLK0";
 wire [2:0] serial_data;
 // The reset DCS uses PTR3[0] regional routing near the serializer IOs.
 // Each release stage adds one pixel period; reset word phase is fixed.
 // Three release stages on the dedicated74.25MHz PLL output. Its phase
 // and duty trim are represented explicitly in integrated.sdc. Local stage
 // placement bounds reset skew; OSER10 recovery/removal remain timed.
 (* async_reg="true",syn_preserve=1,syn_keep=1 *) reg [1:0] reset_release;
 always @(posedge reset_regional or negedge rst_n)
 if(!rst_n)reset_release<=0;else reset_release<={reset_release[0],1'b1};
 genvar i;
 generate for(i=0;i<3;i=i+1)begin:channels
   wire [9:0] word_data;
   // Assert asynchronously; release all channels on the same reset-clock edge.
   // This last stage and the serializer RESET path remain timed.
   (* syn_preserve=1, syn_keep=1 *) reg local_rst_n;
   always @(posedge reset_regional or negedge rst_n)
     if(!rst_n)local_rst_n<=1'b0;
     else local_rst_n<=reset_release[1];
   assign word_data=(i==0)?blue:((i==1)?green:red);
   OSER10 serializer(.Q(serial_data[i]),.D0(word_data[0]),.D1(word_data[1]),
   .D2(word_data[2]),.D3(word_data[3]),.D4(word_data[4]),.D5(word_data[5]),
   .D6(word_data[6]),.D7(word_data[7]),.D8(word_data[8]),.D9(word_data[9]),
   .PCLK(pixel_clk),.FCLK(serial_global),.RESET(~local_rst_n));
   ELVDS_OBUF differential(.I(serial_data[i]),.O(d_p[i]),.OB(d_n[i]));
 end endgenerate
 ELVDS_OBUF clock_differential(.I(pixel_clk),.O(ck_p),.OB(ck_n));
endmodule
`default_nettype wire
