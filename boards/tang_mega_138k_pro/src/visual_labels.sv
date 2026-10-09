`default_nettype none
// Small instrument labels, not a framebuffer/UI. Double-dabble avoids runtime /10.
module visual_labels #(parameter SAMPLE_RATE=48000)(
 input wire [9:0] x,y,input wire peak_valid,input wire [15:0] peak_hz,
 output reg ink
);
 localparam integer SPAN_CENTIMS=(512*100000+SAMPLE_RATE/2)/SAMPLE_RATE;
 function [19:0] bcd5;
 input [15:0] value;reg [35:0] work;integer i,j;
 begin
   work={20'd0,value};
   for(i=0;i<16;i=i+1)begin
     for(j=0;j<5;j=j+1)if(work[16+4*j+:4]>=5)work[16+4*j+:4]=work[16+4*j+:4]+4'd3;
     work=work<<1;
   end
   bcd5=work[35:16];
 end endfunction
 wire [19:0] digits=bcd5(peak_hz);
 localparam [19:0] MID_BCD=bcd5(16'(SAMPLE_RATE/4));
 localparam [19:0] MAX_BCD=bcd5(16'(SAMPLE_RATE/2));
 localparam [19:0] SPAN_BCD=bcd5(16'(SPAN_CENTIMS));
 function [34:0] glyph;
 input [7:0] ch;
 begin case(ch)
    8'd48:glyph=35'h3a33ae62e;
    8'd49:glyph=35'h11842108e;
    8'd50:glyph=35'h3a211111f;
    8'd51:glyph=35'h78217043e;
    8'd52:glyph=35'h8ca97c42;
    8'd53:glyph=35'h7e10f043e;
    8'd54:glyph=35'h3a10f462e;
    8'd55:glyph=35'h7c2222108;
    8'd56:glyph=35'h3a317462e;
    8'd57:glyph=35'h3a317842e;
    8'd65:glyph=35'h3a31fc631;
    8'd69:glyph=35'h7e10f421f;
    8'd70:glyph=35'h7e10f4210;
    8'd71:glyph=35'h3a30bc62e;
    8'd72:glyph=35'h4631fc631;
    8'd75:glyph=35'h4654c5251;
    8'd76:glyph=35'h42108421f;
    8'd77:glyph=35'h4775ac631;
    8'd78:glyph=35'h4739ace71;
    8'd79:glyph=35'h3a318c62e;
    8'd80:glyph=35'h7a31f4210;
    8'd82:glyph=35'h7a31f5251;
    8'd83:glyph=35'h3e107043e;
    8'd86:glyph=35'h46318c544;
    8'd87:glyph=35'h4631ad6aa;
    8'd88:glyph=35'h462a22a31;
    8'd89:glyph=35'h462a21084;
    8'd90:glyph=35'h7c222221f;
    8'd43:glyph=35'h84f9080;
    8'd45:glyph=35'hf8000;
    8'd46:glyph=35'hc6;
    default:glyph=0;
 endcase end endfunction
 function [7:0] digit;
 input [19:0] value;input integer position;
 begin digit=8'd48+{4'd0,value[4*(4-position)+:4]};end
 endfunction
 reg [7:0] ch;reg [34:0] bits;
 integer pos,col,row;
 always @(*)begin
   ch=8'd32;pos=0;col=0;row=0;
   if(y>=8 && y<22 && x<288)begin
     pos=32'(x)/16;col=(32'(x)%16)/2;row=(32'(y)-8)/2;
     if(pos<10)ch=8'(80'h57415645205350414e20>>(8*(9-pos))); // WAVE SPAN
     else if(pos<12)ch=digit(SPAN_BCD,pos-9);
     else if(pos==12)ch=8'd46;
     else if(pos<15)ch=digit(SPAN_BCD,pos-10);
     else if(pos==15)ch=8'd77;
     else if(pos==16)ch=8'd83;
   end else if(y>=8 && y<22 && x>=352 && x<384)begin
     pos=(32'(x)-352)/16;col=((32'(x)-352)%16)/2;row=(32'(y)-8)/2;
     ch=(pos==0)?8'd88:8'd89;
   end else if(y>=200 && y<214 && x>=64 && x<256)begin
     pos=(32'(x)-64)/16;col=((32'(x)-64)%16)/2;row=(32'(y)-200)/2;
     if(pos<5)ch=8'(40'h5045414b20>>(8*(4-pos))); // PEAK
     else if(pos<10)ch=peak_valid?digit(digits,pos-5):8'd45;
     else ch=(pos==10)?8'd72:8'd90;
   end else if(y>=220 && y<227 && x>=450 && x<522)begin
     pos=(32'(x)-450)/8;col=(32'(x)-450)%8;row=32'(y)-220;
     ch=8'(72'h4c4f4720504f574552>>(8*(8-pos))); // LOG POWER
   end else if(y>=456 && y<463 && x>=64 && x<88)begin
     pos=(32'(x)-64)/8;col=(32'(x)-64)%8;row=32'(y)-456;
     ch=8'(24'h30485a>>(8*(2-pos)));
   end else if(y>=456 && y<463 && ((x>=292 && x<348)||(x>=520 && x<576)))begin
     if(x<348)begin pos=(32'(x)-292)/8;col=(32'(x)-292)%8;end
     else begin pos=(32'(x)-520)/8;col=(32'(x)-520)%8;end
     row=32'(y)-456;
     if(pos<5)ch=digit(x<348?MID_BCD:MAX_BCD,pos);
     else ch=(pos==5)?8'd72:8'd90;
   end else if(x>=264 && x<296 && ((y>=32 && y<39)||(y>=96 && y<103)||(y>=153 && y<160)))begin
     pos=(32'(x)-264)/8;col=(32'(x)-264)%8;
     if(y<39)begin row=32'(y)-32;ch=8'(32'h2b314653>>(8*(3-pos)));end
     else if(y<103)begin row=32'(y)-96;ch=(pos==0)?8'd48:8'd32;end
     else begin row=32'(y)-153;ch=8'(32'h2d314653>>(8*(3-pos)));end
   end
   bits=glyph(ch);ink=0;
   if(col<5 && row<7)ink=bits[34-(row*5+col)];
 end
endmodule
`default_nettype wire
