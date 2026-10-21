`default_nettype none
// Keep the combinational interface for existing HUD verification and previews.
module piano_status_overlay #(parameter REMOTE_STATUS=0,parameter MAPPING_CONFIRMED=1,parameter INFO_Y=168,DETAIL_Y=184,KEY_X=400,KEY_Y=168,KEY_PITCH=12,KEY_WIDTH=10,KEY_HEIGHT=12)(input wire [9:0] x,y,input wire [57:0] status,
 output wire ink,key_area,key_on);
 wire [7:0] ch;wire [2:0] col,row;wire [34:0] bits;
 piano_status_decode #(.REMOTE_STATUS(REMOTE_STATUS),.MAPPING_CONFIRMED(MAPPING_CONFIRMED),.INFO_Y(INFO_Y),.DETAIL_Y(DETAIL_Y),.KEY_X(KEY_X),.KEY_Y(KEY_Y),.KEY_PITCH(KEY_PITCH),.KEY_WIDTH(KEY_WIDTH),.KEY_HEIGHT(KEY_HEIGHT)) decode(x,y,status,ch,col,row,key_area,key_on);
 piano_status_font font(ch,bits);
 assign ink=col<5 && row<7?bits[6'd34-({3'd0,row}*6'd5+{3'd0,col})]:1'b0;
endmodule
// Production path: register character decode and then glyph lookup.
module piano_status_overlay_pipeline #(parameter REMOTE_STATUS=0,parameter MAPPING_CONFIRMED=1,parameter INFO_Y=168,DETAIL_Y=184,KEY_X=400,KEY_Y=168,KEY_PITCH=12,KEY_WIDTH=10,KEY_HEIGHT=12)(input wire [9:0] x,y,input wire [57:0] status,
 input wire clk,rst_n,output wire ink,output reg key_area,key_on);
 wire [7:0] ch;wire [2:0] col,row;wire area,on;wire [34:0] glyph_bits;
 reg [7:0] char_d;reg [2:0] col_d,row_d;reg area_d,on_d;
 reg [34:0] bits_d;reg [5:0] index_d;reg valid_d;
 piano_status_decode #(.REMOTE_STATUS(REMOTE_STATUS),.MAPPING_CONFIRMED(MAPPING_CONFIRMED),.INFO_Y(INFO_Y),.DETAIL_Y(DETAIL_Y),.KEY_X(KEY_X),.KEY_Y(KEY_Y),.KEY_PITCH(KEY_PITCH),.KEY_WIDTH(KEY_WIDTH),.KEY_HEIGHT(KEY_HEIGHT)) decode(x,y,status,ch,col,row,area,on);
 piano_status_font font(char_d,glyph_bits);
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  char_d<=32;col_d<=0;row_d<=0;area_d<=0;on_d<=0;
  bits_d<=0;index_d<=0;valid_d<=0;key_area<=0;key_on<=0;
 end else begin
  char_d<=ch;col_d<=col;row_d<=row;area_d<=area;on_d<=on;
  bits_d<=glyph_bits;index_d<=6'd34-({3'd0,row_d}*6'd5+{3'd0,col_d});
  valid_d<=col_d<5 && row_d<7;key_area<=area_d;key_on<=on_d;
 end
 assign ink=valid_d?bits_d[index_d]:1'b0;
endmodule
module piano_status_font(input wire [7:0] ch,output wire [34:0] bits);
 function automatic [34:0] glyph(input [7:0] ch);
 begin case(ch)
8'd35:glyph=35'h2bea57d40;
8'd43:glyph=35'h0084f9080;
8'd45:glyph=35'h0000f8000;
8'd46:glyph=35'h0000000c6;
8'd48:glyph=35'h3a33ae62e;
8'd49:glyph=35'h11842108e;
8'd50:glyph=35'h3a211111f;
8'd51:glyph=35'h78217043e;
8'd52:glyph=35'h08ca97c42;
8'd53:glyph=35'h7e10f043e;
8'd54:glyph=35'h3a10f462e;
8'd55:glyph=35'h7c2222108;
8'd56:glyph=35'h3a317462e;
8'd57:glyph=35'h3a317842e;
8'd61:glyph=35'h001f07c00;
8'd65:glyph=35'h3a31fc631;
8'd66:glyph=35'h7a31f463e;
8'd67:glyph=35'h3a308422e;
8'd68:glyph=35'h7a318c63e;
8'd69:glyph=35'h7e10f421f;
8'd70:glyph=35'h7e10f4210;
8'd71:glyph=35'h3a30bc62e;
8'd72:glyph=35'h4631fc631;
8'd73:glyph=35'h38842108e;
8'd75:glyph=35'h4654c5251;
8'd76:glyph=35'h42108421f;
8'd77:glyph=35'h4775ac631;
8'd78:glyph=35'h4739ace71;
8'd79:glyph=35'h3a318c62e;
8'd80:glyph=35'h7a31f4210;
8'd82:glyph=35'h7a31f5251;
8'd83:glyph=35'h3e107043e;
8'd84:glyph=35'h7c8421084;
8'd85:glyph=35'h46318c62e;
8'd86:glyph=35'h46318c544;
8'd87:glyph=35'h4631ad6aa;
8'd88:glyph=35'h462a22a31;
8'd89:glyph=35'h462a21084;
8'd90:glyph=35'h7c222221f;
 default:glyph=0;endcase end endfunction

 assign bits=glyph(ch);
endmodule
module piano_status_decode #(parameter REMOTE_STATUS=0,parameter MAPPING_CONFIRMED=1,parameter INFO_Y=168,DETAIL_Y=184,KEY_X=400,KEY_Y=168,KEY_PITCH=12,KEY_WIDTH=10,KEY_HEIGHT=12)(input wire [9:0] x,y,input wire [57:0] status,
 output reg [7:0] ch,output reg [2:0] col,row,output wire key_area,key_on);
 wire [15:0] keys=status[57:42];wire [5:0] voices=status[41:36];
 wire [23:0] peak=status[35:12];wire [6:0] note=status[11:5];
 wire note_valid=status[4];wire [3:0] stage=status[3:0];
 wire [127:0] instrument_name;wire [2:0] actual_id;wire switching;
 // In the integrated build the existing status mailbox carries actual timbre and switching.
 yinse_display_info instrument(REMOTE_STATUS?status[2:0]:3'd0,REMOTE_STATUS?status[3]:1'b0,instrument_name,actual_id,switching);
 function automatic [7:0] hexchar(input [3:0] n);
 hexchar=(n<10)?8'd48+{4'd0,n}:8'd55+{4'd0,n};
 endfunction
 reg [5:0] pos;integer noteclass;
 reg [7:0] note_letter,note_accidental,note_octave;
 always_comb begin
  noteclass=32'(note)%12;note_letter="C";note_accidental=" ";
  case(noteclass)
   0:note_letter="C";1:begin note_letter="C";note_accidental="#";end
   2:note_letter="D";3:begin note_letter="D";note_accidental="#";end
   4:note_letter="E";5:note_letter="F";6:begin note_letter="F";note_accidental="#";end
   7:note_letter="G";8:begin note_letter="G";note_accidental="#";end
   9:note_letter="A";10:begin note_letter="A";note_accidental="#";end
   11:note_letter="B";default:note_letter="-";
  endcase
  note_octave=8'(32'(note)/12+47);
  ch=" ";pos=0;col=0;row=0;
  if(x<392 && y>=INFO_Y && y<INFO_Y+7)begin
   pos=x[8:3];col=x[2:0];row=3'(y-INFO_Y);
   case(pos)
    0:ch=instrument_name[127-:8];
    1:ch=instrument_name[119-:8];
    2:ch=instrument_name[111-:8];
    3:ch=instrument_name[103-:8];
    4:ch=instrument_name[95-:8];
    7:ch=8'd86;
    8:ch=8'd79;
    9:ch=8'd73;
    10:ch=8'd67;
    11:ch=8'd69;
    12:ch=8'd83;
    13:ch=8'd61;
    14:ch=8'(48+32'(voices)/10);
    15:ch=8'(48+32'(voices)%10);
    18:ch=8'd78;
    19:ch=8'd79;
    20:ch=8'd84;
    21:ch=8'd69;
    22:ch=8'd61;
    23:ch=note_valid?note_letter:8'd45;
    24:ch=note_valid?note_accidental:8'd45;
    25:ch=note_valid?note_octave:8'd45;
    28:ch=8'd77;
    29:ch=8'd73;
    30:ch=8'd68;
    31:ch=8'd73;
    32:ch=8'd61;
    33:ch=note_valid?8'(48+32'(note)/100):8'd45;
    34:ch=note_valid?8'(48+(32'(note)/10)%10):8'd45;
    35:ch=note_valid?8'(48+32'(note)%10):8'd45;
    default:ch=8'd32;
   endcase
  end else if(x<392 && y>=DETAIL_Y && y<DETAIL_Y+7)begin
   pos=x[8:3];col=x[2:0];row=3'(y-DETAIL_Y);
   case(pos)
    0:ch=MAPPING_CONFIRMED?8'd75:8'd82;
    1:ch=MAPPING_CONFIRMED?8'd69:8'd65;
    2:ch=MAPPING_CONFIRMED?8'd89:8'd87;
    3:ch=MAPPING_CONFIRMED?8'd83:8'd83;
    4:ch=MAPPING_CONFIRMED?8'd61:8'd61;
    5:ch=hexchar(keys[15-:4]);
    6:ch=hexchar(keys[11-:4]);
    7:ch=hexchar(keys[7-:4]);
    8:ch=hexchar(keys[3-:4]);
    11:ch=8'd80;
    12:ch=8'd69;
    13:ch=8'd65;
    14:ch=8'd75;
    15:ch=8'd61;
    16:ch=hexchar(peak[23-:4]);
    17:ch=hexchar(peak[19-:4]);
    18:ch=hexchar(peak[15-:4]);
    19:ch=hexchar(peak[11-:4]);
    20:ch=hexchar(peak[7-:4]);
    21:ch=hexchar(peak[3-:4]);
    24:ch=REMOTE_STATUS?"S":8'd83;
    25:ch=REMOTE_STATUS?"W":8'd84;
    26:ch=REMOTE_STATUS?"I":8'd65;
    27:ch=REMOTE_STATUS?"T":8'd71;
    28:ch=REMOTE_STATUS?"C":8'd69;
    29:ch=8'd61;
    30:ch=REMOTE_STATUS?(switching?"1":"0"):hexchar(stage);
    33:ch=8'd77;
    34:ch=8'd65;
    35:ch=8'd80;
    36:ch=8'd61;
    37:ch=MAPPING_CONFIRMED?8'd49:8'd48;
    default:ch=8'd32;
   endcase
  end
 end
 //16 constant rectangles avoid a variable divide/modulo on the pixel path.
 wire [15:0] key_hits;
 genvar ki;
 generate for(ki=0;ki<16;ki=ki+1)begin:G_KEY
 assign key_hits[ki]=x>=KEY_X+ki*KEY_PITCH && x<KEY_X+ki*KEY_PITCH+KEY_WIDTH &&
                     y>=KEY_Y && y<KEY_Y+KEY_HEIGHT;
 end endgenerate
 assign key_area=|key_hits;
 assign key_on=|(key_hits & keys);

endmodule
`default_nettype wire
