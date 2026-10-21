`default_nettype none
// Chinese bitmap labels; embedded glyphs need no external font or frame buffer.
// Double-dabble avoids runtime decimal division.
module original_labels #(parameter SAMPLE_RATE=48000)(
 input wire [9:0] x,y,input wire peak_valid,input wire [15:0] peak_hz,
 input wire xy_direct,xy_signal,xy_mixed,input wire signed [5:0] xy_shift,
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
 function [143:0] glyph;
 input [15:0] ch;
 begin case(ch)
   16'h0020:glyph=144'h000000000000000000000000000000000000; //  
   16'h002b:glyph=144'h0000000000200200f8020020000000000000; // +
   16'h002d:glyph=144'h0000000000000001f8000000000000000000; // -
   16'h002e:glyph=144'h000000000000000000000000000080000000; // .
   16'h0030:glyph=144'h0000000e01101101101101101100e0000000; // 0
   16'h0031:glyph=144'h0000000400c00400400400400400e0000000; // 1
   16'h0032:glyph=144'h0000000e01101100200400801001f0000000; // 2
   16'h0033:glyph=144'h0000000e01100100600100101100e0000000; // 3
   16'h0034:glyph=144'h0000000200600600a01201f0020070000000; // 4
   16'h0035:glyph=144'h0000001f01001001e01100101100e0000000; // 5
   16'h0036:glyph=144'h0000000600901001601901101100e0000000; // 6
   16'h0037:glyph=144'h0000000f0010020020040040040040000000; // 7
   16'h0038:glyph=144'h0000000e01101100e00901101100e0000000; // 8
   16'h0039:glyph=144'h0000000e01101101300d00101200c0000000; // 9
   16'h0046:glyph=144'h0000001f00900a00e00a00800801c0000000; // F
   16'h0048:glyph=144'h0000001980900900f0090090090198000000; // H
   16'h0053:glyph=144'h0000000f01101000c00200101101e0000000; // S
   16'h006d:glyph=144'h0000000000000003c02a02a02a02a0000000; // m
   16'h0073:glyph=144'h0000000000000000f00800600100f0000000; // s
   16'h007a:glyph=144'h0000000000000000f00200400400f0000000; // z
   16'h00b7:glyph=144'h000000000000000060060000000000000000; // ·
   16'h4e2d:glyph=144'h0400400407fc4444444447fc444040040040; // 中
   16'h4fe1:glyph=144'h2202105fe400cfc4004fc4004fc4844fc484; // 信
   16'h503c:glyph=144'h2202fe4204fcc844fc4844fc4844fc4845fe; // 值
   16'h5207:glyph=144'h20027e212392e122122122122a232224208c; // 切
   16'h52a8:glyph=144'h01071001003ef92212412512892fa202204c; // 动
   16'h5355:glyph=144'h2081107fc4447fc4447fc040ffe040040040; // 单
   16'h53cc:glyph=144'h000fbe0a20a28a2514514208208514524842; // 双
   16'h53f7:glyph=144'h3f82082083f8000ffe1002003fc004004018; // 号
   16'h56fe:glyph=144'hffe8829f2b128e2f1e8c2822982862ffe802; // 图
   16'h58f0:glyph=144'h040ffe0407fc0007fc4444447fc404400800; // 声
   16'h5982:glyph=144'h20020023efa24a24a24a292252222253e8a2; // 如
   16'h5cf0:glyph=144'h21021e232a8cab2a88abea88abeb88cbe008; // 峰
   16'h5f62:glyph=144'h004fc4488492482fc44884904824844888b0; // 形
   16'h6362:glyph=144'h220238248f9027c254354e542fe228244682; // 换
   16'h653e:glyph=144'h410210010f9e4244547944944944884949a2; // 放
   16'h65e0:glyph=144'h0007fc040040040ffe0a00a012022242281e; // 无
   16'h674e:glyph=144'h040ffe150248c463f0020040ffe0400401c0; // 李
   16'h6ce2:glyph=144'h0108105fe1121109fc5441441285109282c6; // 波
   16'h7387:glyph=144'h040ffe0805143e80402a85f4040ffe040040; // 率
   16'h7f29:glyph=144'h2102fe482920e5e2c845ef5205e352c5e052; // 缩
   16'h81ea:glyph=144'h0400807fc4044047fc4044047fc4044047fc; // 自
   16'h8428:glyph=144'h110ffe110f0897e924a1897ed40a40880900; // 萨
   16'h8c31:glyph=144'h4442fe0280aae282fe20027c24437c24407c; // 谱
   16'h90e8:glyph=144'h1007de012452294ff40127d245245c7d0450; // 部
   16'h9891:glyph=144'h13e5c851053efe212a52a56a8aa108214c22; // 频
   16'hff1a:glyph=144'h000000000000300300000000300300000000; // ：
   default:glyph=0;
 endcase end endfunction
 function [15:0] digit;
 input [19:0] value;input integer position;
 begin digit=16'd48+{12'd0,value[4*(4-position)+:4]};end
 endfunction
 // xy_shift remains an interface input; the main screen deliberately hides the exponent.
 wire unused_shift=^xy_shift;
 reg [15:0] ch;reg [143:0] bits;
 integer pos,col,row;
 always @(*)begin
   ch=16'd32;pos=0;col=0;row=0;
   if(y>=8 && y<20 && x<180)begin
     pos=(32'(x)-0)/12;col=(32'(x)-0)%12;row=32'(y)-8;
case(pos)
       0:ch=16'h6ce2; // 波
       1:ch=16'h5f62; // 形
       2:ch=16'h0020; //  
       3:ch=16'h00b7; // ·
       4:ch=16'h0020; //  
       default:ch=16'd32;
     endcase
     if(pos>=5 && pos<7)ch=digit(SPAN_BCD,pos-4);
     else if(pos==7)ch=16'd46;
     else if(pos>=8 && pos<10)ch=digit(SPAN_BCD,pos-5);
     else if(pos==11)ch=16'd109;
     else if(pos==12)ch=16'd115;
   end else if(y>=8 && y<20 && x>=448 && x<496)begin
     pos=(32'(x)-448)/12;col=(32'(x)-448)%12;row=32'(y)-8;
case(pos)
       0:ch=16'h674e; // 李
       1:ch=16'h8428; // 萨
       2:ch=16'h5982; // 如
       3:ch=16'h56fe; // 图
       default:ch=16'd32;
     endcase
   end else if(y>=164 && y<176 && x>=432 && x<624)begin
     pos=(32'(x)-432)/12;col=(32'(x)-432)%12;row=32'(y)-164;
     if(xy_mixed)begin
case(pos)
       0:ch=16'h4fe1; // 信
       1:ch=16'h53f7; // 号
       2:ch=16'h5207; // 切
       3:ch=16'h6362; // 换
       4:ch=16'h4e2d; // 中
       default:ch=16'd32;
     endcase
     end
     else if(!xy_signal)begin
case(pos)
       0:ch=16'h65e0; // 无
       1:ch=16'h4fe1; // 信
       2:ch=16'h53f7; // 号
       default:ch=16'd32;
     endcase
     end
     else if(xy_direct)begin
case(pos)
       0:ch=16'h53cc; // 双
       1:ch=16'h58f0; // 声
       2:ch=16'h90e8; // 部
       default:ch=16'd32;
     endcase
     end
     else begin
case(pos)
       0:ch=16'h5355; // 单
       1:ch=16'h58f0; // 声
       2:ch=16'h90e8; // 部
       default:ch=16'd32;
     endcase
     end
   end else if(y>=182 && y<194 && x>=448 && x<496)begin
     pos=(32'(x)-448)/12;col=(32'(x)-448)%12;row=32'(y)-182;
case(pos)
       0:ch=16'h81ea; // 自
       1:ch=16'h52a8; // 动
       2:ch=16'h7f29; // 缩
       3:ch=16'h653e; // 放
       default:ch=16'd32;
     endcase
   end else if(y>=184 && y<196 && x>=64 && x<256)begin
     pos=(32'(x)-64)/12;col=(32'(x)-64)%12;row=32'(y)-184;
case(pos)
       0:ch=16'h5cf0; // 峰
       1:ch=16'h503c; // 值
       2:ch=16'h9891; // 频
       3:ch=16'h7387; // 率
       4:ch=16'hff1a; // ：
       default:ch=16'd32;
     endcase
     if(pos>=5 && pos<10)begin
       ch=peak_valid?digit(digits,pos-5):16'd45;
       if(peak_valid && pos<9 && (digits>>(4*(9-pos)))==0)ch=16'd32;
     end else if(pos==11)ch=16'd72;
     else if(pos==12)ch=16'd122;
   end else if(y>=198 && y<210 && x>=450 && x<474)begin
     pos=(32'(x)-450)/12;col=(32'(x)-450)%12;row=32'(y)-198;
case(pos)
       0:ch=16'h9891; // 频
       1:ch=16'h8c31; // 谱
       default:ch=16'd32;
     endcase
   end else if(y>=340 && y<352 && x>=64 && x<112)begin
     pos=(32'(x)-64)/12;col=(32'(x)-64)%12;row=32'(y)-340;
case(pos)
       0:ch=16'h0030; // 0
       1:ch=16'h0020; //  
       2:ch=16'h0048; // H
       3:ch=16'h007a; // z
       default:ch=16'd32;
     endcase
   end else if(y>=340 && y<352 && ((x>=272 && x<368)||(x>=480 && x<576)))begin
     if(x<368)begin pos=(32'(x)-272)/12;col=(32'(x)-272)%12;end
     else begin pos=(32'(x)-480)/12;col=(32'(x)-480)%12;end
     row=32'(y)-340;
     if(pos<5)ch=digit(x<368?MID_BCD:MAX_BCD,pos);
     else if(pos==6)ch=16'd72;
     else if(pos==7)ch=16'd122;
   end else if(x>=264 && x<312 && ((y>=32 && y<44)||(y>=96 && y<108)||(y>=148 && y<160)))begin
     pos=(32'(x)-264)/12;col=(32'(x)-264)%12;
     if(y<44)begin row=32'(y)-32;
case(pos)
       0:ch=16'h002b; // +
       1:ch=16'h0031; // 1
       2:ch=16'h0046; // F
       3:ch=16'h0053; // S
       default:ch=16'd32;
     endcase
     end else if(y<108)begin row=32'(y)-96;ch=(pos==0)?16'd48:16'd32;end
     else begin row=32'(y)-148;
case(pos)
       0:ch=16'h002d; // -
       1:ch=16'h0031; // 1
       2:ch=16'h0046; // F
       3:ch=16'h0053; // S
       default:ch=16'd32;
     endcase
     end
   end
   bits=glyph(ch);ink=0;
   if(col<12 && row<12)ink=bits[143-(row*12+col)];
 end
endmodule
`default_nettype wire
