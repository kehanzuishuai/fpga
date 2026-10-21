`default_nettype none
// Exact quarter-wave factorization of the original 256 signed Q1.15 words.
// No interpolation, new rounding, or sample latency is introduced.
module yinse_sine_rom(input wire [7:0] address,output wire signed [15:0] sample);
 wire [5:0] index=address[6] ? -address[5:0] : address[5:0];
 reg [14:0] rom[0:63];
 initial begin
  rom[6'd0]=15'h0000;
  rom[6'd1]=15'h0324;
  rom[6'd2]=15'h0648;
  rom[6'd3]=15'h096a;
  rom[6'd4]=15'h0c8c;
  rom[6'd5]=15'h0fab;
  rom[6'd6]=15'h12c8;
  rom[6'd7]=15'h15e2;
  rom[6'd8]=15'h18f9;
  rom[6'd9]=15'h1c0b;
  rom[6'd10]=15'h1f1a;
  rom[6'd11]=15'h2223;
  rom[6'd12]=15'h2528;
  rom[6'd13]=15'h2826;
  rom[6'd14]=15'h2b1f;
  rom[6'd15]=15'h2e11;
  rom[6'd16]=15'h30fb;
  rom[6'd17]=15'h33df;
  rom[6'd18]=15'h36ba;
  rom[6'd19]=15'h398c;
  rom[6'd20]=15'h3c56;
  rom[6'd21]=15'h3f17;
  rom[6'd22]=15'h41ce;
  rom[6'd23]=15'h447a;
  rom[6'd24]=15'h471c;
  rom[6'd25]=15'h49b4;
  rom[6'd26]=15'h4c3f;
  rom[6'd27]=15'h4ebf;
  rom[6'd28]=15'h5133;
  rom[6'd29]=15'h539b;
  rom[6'd30]=15'h55f5;
  rom[6'd31]=15'h5842;
  rom[6'd32]=15'h5a82;
  rom[6'd33]=15'h5cb3;
  rom[6'd34]=15'h5ed7;
  rom[6'd35]=15'h60eb;
  rom[6'd36]=15'h62f1;
  rom[6'd37]=15'h64e8;
  rom[6'd38]=15'h66cf;
  rom[6'd39]=15'h68a6;
  rom[6'd40]=15'h6a6d;
  rom[6'd41]=15'h6c23;
  rom[6'd42]=15'h6dc9;
  rom[6'd43]=15'h6f5e;
  rom[6'd44]=15'h70e2;
  rom[6'd45]=15'h7254;
  rom[6'd46]=15'h73b5;
  rom[6'd47]=15'h7504;
  rom[6'd48]=15'h7641;
  rom[6'd49]=15'h776b;
  rom[6'd50]=15'h7884;
  rom[6'd51]=15'h7989;
  rom[6'd52]=15'h7a7c;
  rom[6'd53]=15'h7b5c;
  rom[6'd54]=15'h7c29;
  rom[6'd55]=15'h7ce3;
  rom[6'd56]=15'h7d89;
  rom[6'd57]=15'h7e1d;
  rom[6'd58]=15'h7e9c;
  rom[6'd59]=15'h7f09;
  rom[6'd60]=15'h7f61;
  rom[6'd61]=15'h7fa6;
  rom[6'd62]=15'h7fd8;
  rom[6'd63]=15'h7ff5;
 end
 wire [15:0] magnitude=(address[6] && address[5:0]==0)?16'd32767:{1'b0,rom[index]};
 assign sample=address[7] ? -$signed(magnitude) : $signed(magnitude);
endmodule
`default_nettype wire
