`timescale 1ns/1ps
module tb_indicator_equal;
reg clk=0;always #1 clk=~clk;reg [11:0] x=0,y=0;reg [511:0] status=0;wire [3:0] before_flags,after_flags;wire [23:0] before_fill,after_fill;
indicator_before a(clk,x,y,status,before_flags,before_fill);indicator_after b(clk,x,y,status,after_flags,after_fill);
reg [3:0] pipe0,pipe1;integer cycles=0,cases=0,i,j,k;always @(posedge clk)begin pipe0<=before_flags;pipe1<=pipe0;#0.1;if(cycles>5 && after_flags!==pipe1)$fatal(1,"glyph pipeline mismatch x%d y%d actual%b expected%b",x,y,after_flags,pipe1);if(y>=220 && y<432 && before_fill!==after_fill)$fatal(1,"gradient mismatch");cycles=cycles+1;end
initial begin
 for(k=0;k<3;k=k+1)begin
 status[7]=(k==0);
 for(j=220;j<459;j=j+1)begin
  for(i=770;i<1440;i=i+1)begin @(negedge clk);x=12'(i);y=12'(j);status[511:509]=(k==2)?6:3'((i%4)+1);cases=cases+1;end
 end end
 repeat(5)@(negedge clk);$display("PASS production-extracted glyph mask and 3-clock alignment %0d pixels, all3 badges, allphases, gradient exact in activewell",cases);$finish;
end
endmodule
module indicator_before(input wire clk,input wire [11:0] x,y,input wire [511:0] status_data,output wire [3:0] flags,output wire [23:0] fill);
localparam SCENE_LATENCY=40;typedef struct packed {logic[11:0] x,y;} pixel_info;wire [23:0] info_pipe[0:39];genvar j;generate for(j=0;j<40;j=j+1)begin assign info_pipe[j]={x,y};end endgenerate
 function automatic [34:0] adsr_letter(input [3:0] code);
 begin case(code)
 0:adsr_letter={5'b01110,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
 1:adsr_letter={5'b11110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b11110};
 2:adsr_letter={5'b01111,5'b10000,5'b10000,5'b01110,5'b00001,5'b00001,5'b11110};
 3:adsr_letter={5'b11110,5'b10001,5'b10001,5'b11110,5'b10100,5'b10010,5'b10001};
 4:adsr_letter={5'b11110,5'b10001,5'b10001,5'b11110,5'b10000,5'b10000,5'b10000};
 5:adsr_letter={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100};
 6:adsr_letter={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b11111};
 7:adsr_letter={5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b11111};
 8:adsr_letter={5'b11110,5'b10001,5'b10001,5'b11110,5'b10001,5'b10001,5'b11110};
 9:adsr_letter={5'b10001,5'b10001,5'b01010,5'b00100,5'b00100,5'b00100,5'b00100};
 default:adsr_letter=0;endcase end endfunction
 // Four stage indicators below the existing 32-voice grid (226..379).
 function automatic [7:0] adsr_row(input [11:0] px,py);
 reg [1:0] stage_id;reg hit;
 begin
  stage_id=0;hit=0;
  if(px>=1192 && px<1228)begin stage_id=0;hit=1;end
  else if(px>=1246 && px<1282)begin stage_id=1;hit=1;end
  else if(px>=1300 && px<1336)begin stage_id=2;hit=1;end
  else if(px>=1354 && px<1390)begin stage_id=3;hit=1;end
  adsr_row={hit && py>=400 && py<432,stage_id,5'(py-400)};
 end endfunction
 function automatic letter_bit(input [3:0] code,input [2:0] row,col);
 reg [34:0] bitmap;reg [5:0] bit_index;
 begin bitmap=adsr_letter(code);bit_index=6'd34-(6'(row)*6'd5+6'(col));
 letter_bit=(row<7 && col<5)?bitmap[bit_index]:1'b0;end endfunction
 function automatic badge_pixel(input [11:0] px,py,input piano,bypass);
 reg [6:0] dx;reg [3:0] dy,local_x,code;reg [2:0] badge_cell;
 begin
  badge_pixel=0;dx=7'(px-836);dy=4'(py-444);badge_cell=0;local_x=0;code=15;
  if(px>=836 && px<920 && py>=444 && py<458)begin
   if(dx<12)begin badge_cell=0;local_x=4'(dx);end
   else if(dx<24)begin badge_cell=1;local_x=4'(dx-12);end
   else if(dx<36)begin badge_cell=2;local_x=4'(dx-24);end
   else if(dx<48)begin badge_cell=3;local_x=4'(dx-36);end
   else if(dx<60)begin badge_cell=4;local_x=4'(dx-48);end
   else if(dx<72)begin badge_cell=5;local_x=4'(dx-60);end
   else begin badge_cell=6;local_x=4'(dx-72);end
   if(bypass)case(badge_cell)0:code=8;1:code=9;2:code=4;3:code=0;4,5:code=2;default:code=15;endcase
   else if(piano)case(badge_cell)0:code=4;1:code=0;2:code=3;3:code=5;4:code=6;5:code=0;6:code=7;default:code=15;endcase
   else case(badge_cell)0:code=0;1:code=1;2:code=2;3:code=3;default:code=15;endcase
   badge_pixel=letter_bit(code,dy[3:1],local_x[3:1]);
  end
 end endfunction
 pixel_info alias_pre; assign alias_pre=info_pipe[SCENE_LATENCY-2];wire [11:0] envelope_pre_x=alias_pre.x;
 wire [11:0] envelope_pre_y=alias_pre.y;
 wire [7:0] envelope_row=adsr_row(envelope_pre_x,envelope_pre_y);
 wire [5:0] envelope_local_x=envelope_pre_x<1246?6'(envelope_pre_x-1192):envelope_pre_x<1300?6'(envelope_pre_x-1246):envelope_pre_x<1354?6'(envelope_pre_x-1300):6'(envelope_pre_x-1354);
 reg envelope_letter_q,envelope_bar_q,envelope_active_q,envelope_badge_q;
 always @(posedge clk)begin
  envelope_letter_q<=envelope_row[7] && envelope_row[4:0]<21 && envelope_local_x<15 &&
   letter_bit({2'b0,envelope_row[6:5]},3'(envelope_row[4:0]/5'd3),3'(envelope_local_x[3:0]/4'd3));
  envelope_bar_q<=envelope_row[7] && envelope_row[4:0]>=28;
  envelope_active_q<=status_data[511:509]=={1'b0,envelope_row[6:5]}+3'd1;
  envelope_badge_q<=badge_pixel(envelope_pre_x,envelope_pre_y,status_data[7],status_data[511:509]==6);
 end


 reg [23:0] envelope_fill_q;always @(posedge clk)envelope_fill_q<={8'((432-32'(y))/10),8'((432-32'(y))/6),8'((432-32'(y))/5)};

assign flags={envelope_letter_q,envelope_bar_q,envelope_active_q,envelope_badge_q};assign fill=envelope_fill_q;endmodule
module indicator_after(input wire clk,input wire [11:0] x,y,input wire [511:0] status_data,output wire [3:0] flags,output wire [23:0] fill);
localparam SCENE_LATENCY=40;typedef struct packed {logic[11:0] x,y;} pixel_info;wire [23:0] info_pipe[0:39];genvar j;generate for(j=0;j<40;j=j+1)begin assign info_pipe[j]={x,y};end endgenerate
 function automatic [34:0] adsr_letter(input [3:0] code);
 begin case(code)
 0:adsr_letter={5'b01110,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
 1:adsr_letter={5'b11110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b11110};
 2:adsr_letter={5'b01111,5'b10000,5'b10000,5'b01110,5'b00001,5'b00001,5'b11110};
 3:adsr_letter={5'b11110,5'b10001,5'b10001,5'b11110,5'b10100,5'b10010,5'b10001};
 4:adsr_letter={5'b11110,5'b10001,5'b10001,5'b11110,5'b10000,5'b10000,5'b10000};
 5:adsr_letter={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100};
 6:adsr_letter={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b11111};
 7:adsr_letter={5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b11111};
 8:adsr_letter={5'b11110,5'b10001,5'b10001,5'b11110,5'b10001,5'b10001,5'b11110};
 9:adsr_letter={5'b10001,5'b10001,5'b01010,5'b00100,5'b00100,5'b00100,5'b00100};
 default:adsr_letter=0;endcase end endfunction
 // Four stage indicators below the existing 32-voice grid (226..379).
 function automatic [7:0] adsr_row(input [11:0] px,py);
 reg [1:0] stage_id;reg hit;
 begin
  stage_id=0;hit=0;
  if(px>=1192 && px<1228)begin stage_id=0;hit=1;end
  else if(px>=1246 && px<1282)begin stage_id=1;hit=1;end
  else if(px>=1300 && px<1336)begin stage_id=2;hit=1;end
  else if(px>=1354 && px<1390)begin stage_id=3;hit=1;end
  adsr_row={hit && py>=400 && py<432,stage_id,5'(py-400)};
 end endfunction
 function automatic letter_bit(input [3:0] code,input [2:0] row,col);
 reg [34:0] bitmap;reg [5:0] bit_index;
 begin bitmap=adsr_letter(code);bit_index=6'd34-(6'(row)*6'd5+6'(col));
 letter_bit=(row<7 && col<5)?bitmap[bit_index]:1'b0;end endfunction
 function automatic badge_pixel(input [11:0] px,py,input piano,bypass);
 reg [6:0] dx;reg [3:0] dy,local_x,code;reg [2:0] badge_cell;
 begin
  badge_pixel=0;dx=7'(px-836);dy=4'(py-444);badge_cell=0;local_x=0;code=15;
  if(px>=836 && px<920 && py>=444 && py<458)begin
   if(dx<12)begin badge_cell=0;local_x=4'(dx);end
   else if(dx<24)begin badge_cell=1;local_x=4'(dx-12);end
   else if(dx<36)begin badge_cell=2;local_x=4'(dx-24);end
   else if(dx<48)begin badge_cell=3;local_x=4'(dx-36);end
   else if(dx<60)begin badge_cell=4;local_x=4'(dx-48);end
   else if(dx<72)begin badge_cell=5;local_x=4'(dx-60);end
   else begin badge_cell=6;local_x=4'(dx-72);end
   if(bypass)case(badge_cell)0:code=8;1:code=9;2:code=4;3:code=0;4,5:code=2;default:code=15;endcase
   else if(piano)case(badge_cell)0:code=4;1:code=0;2:code=3;3:code=5;4:code=6;5:code=0;6:code=7;default:code=15;endcase
   else case(badge_cell)0:code=0;1:code=1;2:code=2;3:code=3;default:code=15;endcase
   badge_pixel=letter_bit(code,dy[3:1],local_x[3:1]);
  end
 end endfunction
 // Geometry, ROM lookup and masks use three existing descriptor clocks.
 pixel_info indicator_pre,envelope_late;
 assign indicator_pre=info_pipe[SCENE_LATENCY-4];
 assign envelope_late=info_pipe[SCENE_LATENCY-2];
 wire [11:0] envelope_pre_x=indicator_pre.x,envelope_pre_y=indicator_pre.y;
 wire [7:0] envelope_row=adsr_row(envelope_pre_x,envelope_pre_y);
 wire [5:0] envelope_local_x=envelope_pre_x<1246?6'(envelope_pre_x-1192):envelope_pre_x<1300?6'(envelope_pre_x-1246):envelope_pre_x<1354?6'(envelope_pre_x-1300):6'(envelope_pre_x-1354);
 function automatic [2:0] thirds(input [4:0] v);
 begin case(v)
 0,1,2:thirds=0;3,4,5:thirds=1;6,7,8:thirds=2;9,10,11:thirds=3;
 12,13,14:thirds=4;15,16,17:thirds=5;18,19,20:thirds=6;default:thirds=7;
 endcase end endfunction
 function automatic [10:0] badge_address(input [11:0] px,py,input piano,bypass);
 reg [6:0] dx;reg [3:0] dy,lx,code;reg [2:0] bc;
 begin
 dx=7'(px-836);dy=4'(py-444);bc=0;lx=0;code=15;
 if(dx<12)begin bc=0;lx=4'(dx);end
 else if(dx<24)begin bc=1;lx=4'(dx-12);end
 else if(dx<36)begin bc=2;lx=4'(dx-24);end
 else if(dx<48)begin bc=3;lx=4'(dx-36);end
 else if(dx<60)begin bc=4;lx=4'(dx-48);end
 else if(dx<72)begin bc=5;lx=4'(dx-60);end
 else begin bc=6;lx=4'(dx-72);end
 if(bypass)case(bc)0:code=8;1:code=9;2:code=4;3:code=0;4,5:code=2;default:code=15;endcase
 else if(piano)case(bc)0:code=4;1:code=0;2:code=3;3:code=5;4:code=6;5:code=0;6:code=7;default:code=15;endcase
 else case(bc)0:code=0;1:code=1;2:code=2;3:code=3;default:code=15;endcase
 badge_address={px>=836 && px<920 && py>=444 && py<458,code,dy[3:1],lx[3:1]};
 end endfunction
 (* syn_romstyle="block_rom" *) reg indicator_font[0:1023];
 (* syn_romstyle="block_rom" *) reg [23:0] envelope_fill[0:255];
 integer font_i,fill_i;
 initial begin
  for(font_i=0;font_i<1024;font_i=font_i+1)indicator_font[font_i]=letter_bit(4'(font_i>>6),3'(font_i>>3),3'(font_i));
  for(fill_i=0;fill_i<256;fill_i=fill_i+1)envelope_fill[fill_i]={8'(fill_i/10),8'(fill_i/6),8'(fill_i/5)};
 end
 wire [10:0] badge_geometry=badge_address(envelope_pre_x,envelope_pre_y,status_data[7],status_data[511:509]==6);
 reg [9:0] letter_address1,badge_address1;
 reg letter_ok1,badge_ok1,bar1,active1,letter2,badge2,letter_ok2,badge_ok2,bar2,active2;
 reg envelope_letter_q,envelope_bar_q,envelope_active_q,envelope_badge_q;
 reg [23:0] envelope_fill_q;
 always @(posedge clk)begin
  letter_address1<={2'b0,envelope_row[6:5],thirds(envelope_row[4:0]),thirds({1'b0,envelope_local_x[3:0]})};
  letter_ok1<=envelope_row[7] && envelope_row[4:0]<21 && envelope_local_x<15;
  bar1<=envelope_row[7] && envelope_row[4:0]>=28;
  active1<=status_data[511:509]=={1'b0,envelope_row[6:5]}+3'd1;
  badge_address1<=badge_geometry[9:0];badge_ok1<=badge_geometry[10];
  letter2<=indicator_font[letter_address1];badge2<=indicator_font[badge_address1];
  letter_ok2<=letter_ok1;badge_ok2<=badge_ok1;bar2<=bar1;active2<=active1;
  envelope_letter_q<=letter2 && letter_ok2;envelope_bar_q<=bar2;envelope_active_q<=active2;envelope_badge_q<=badge2 && badge_ok2;
  // Positive fill distance is at most212 pixels in the fixed ADSR well.
  envelope_fill_q<=envelope_fill[8'd176-envelope_late.y[7:0]];
 end


assign flags={envelope_letter_q,envelope_bar_q,envelope_active_q,envelope_badge_q};assign fill=envelope_fill_q;endmodule
