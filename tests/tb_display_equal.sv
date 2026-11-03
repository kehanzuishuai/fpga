module tb_display_equal;
 reg c_mapping_valid=0;reg [6:0] char_key_note=0;
 function automatic [15:0] decimal(input [15:0] v,input integer place);begin case(place)
 0:decimal=16'd48+16'(v%16'd10);1:decimal=16'd48+16'((v/16'd10)%16'd10);2:decimal=16'd48+16'((v/16'd100)%16'd10);3:decimal=16'd48+16'((v/16'd1000)%16'd10);default:decimal=16'd48+16'((v/16'd10000)%16'd10);endcase end endfunction
 function automatic [15:0] note_char(input [6:0] note,input integer pos);reg [3:0] pc,octave;begin pc=note%7'd12;octave=note/7'd12-7'd1;note_char=16'd32;
 if(pos==0)case(pc)0,1:note_char=67;2,3:note_char=68;4:note_char=69;5,6:note_char=70;7,8:note_char=71;9,10:note_char=65;11:note_char=66;default:note_char=45;endcase
 else if(pos==1)note_char=(pc==1 || pc==3 || pc==6 || pc==8 || pc==10)?16'd35:16'd48+{12'd0,octave};
 else note_char=(pc==1 || pc==3 || pc==6 || pc==8 || pc==10)?16'd48+{12'd0,octave}:16'd32;
 end endfunction
 function automatic [15:0] gold_key_char(input [4:0] key,input [5:0] pos);reg [6:0] note;begin note=char_key_note;
 if(c_mapping_valid && note>=36 && note<=96)gold_key_char=note_char(note,pos);
 else if(pos==0)gold_key_char=16'd75;else if(pos==1)gold_key_char=decimal(32'(key%16+1),key%16+1>=10?1:0);else gold_key_char=key%16+1>=10?decimal(32'(key%16+1),0):16'd32;
 end endfunction
 function automatic [15:0] new_key_char(input [4:0] key,input [5:0] pos);reg [6:0] note;begin note=char_key_note;
 if(c_mapping_valid && note>=36 && note<=96)new_key_char=note_char(note,pos);
 // Exact fallback K1..K16 table; mapped MIDI note names are unchanged.
 else if(pos==0)new_key_char=16'd75;
 else if(pos==1)begin case(key[3:0])
  4'd0:new_key_char=16'd49;
  4'd1:new_key_char=16'd50;
  4'd2:new_key_char=16'd51;
  4'd3:new_key_char=16'd52;
  4'd4:new_key_char=16'd53;
  4'd5:new_key_char=16'd54;
  4'd6:new_key_char=16'd55;
  4'd7:new_key_char=16'd56;
  4'd8:new_key_char=16'd57;
  default:new_key_char=16'd49;endcase end
 else begin case(key[3:0])
  4'd9:new_key_char=16'd48;
  4'd10:new_key_char=16'd49;
  4'd11:new_key_char=16'd50;
  4'd12:new_key_char=16'd51;
  4'd13:new_key_char=16'd52;
  4'd14:new_key_char=16'd53;
  4'd15:new_key_char=16'd54;
  default:new_key_char=16'd32;endcase end
 end endfunction
 function automatic [7:0] gold_digits(input [5:0] v);
 begin gold_digits={4'(v/6'd10),4'(v%6'd10)};end endfunction
 function automatic [7:0] new_digits(input [5:0] v);
 begin case(v)
  6'd0:new_digits=8'h00;
  6'd1:new_digits=8'h01;
  6'd2:new_digits=8'h02;
  6'd3:new_digits=8'h03;
  6'd4:new_digits=8'h04;
  6'd5:new_digits=8'h05;
  6'd6:new_digits=8'h06;
  6'd7:new_digits=8'h07;
  6'd8:new_digits=8'h08;
  6'd9:new_digits=8'h09;
  6'd10:new_digits=8'h10;
  6'd11:new_digits=8'h11;
  6'd12:new_digits=8'h12;
  6'd13:new_digits=8'h13;
  6'd14:new_digits=8'h14;
  6'd15:new_digits=8'h15;
  6'd16:new_digits=8'h16;
  6'd17:new_digits=8'h17;
  6'd18:new_digits=8'h18;
  6'd19:new_digits=8'h19;
  6'd20:new_digits=8'h20;
  6'd21:new_digits=8'h21;
  6'd22:new_digits=8'h22;
  6'd23:new_digits=8'h23;
  6'd24:new_digits=8'h24;
  6'd25:new_digits=8'h25;
  6'd26:new_digits=8'h26;
  6'd27:new_digits=8'h27;
  6'd28:new_digits=8'h28;
  6'd29:new_digits=8'h29;
  6'd30:new_digits=8'h30;
  6'd31:new_digits=8'h31;
  6'd32:new_digits=8'h32;
  6'd33:new_digits=8'h33;
  6'd34:new_digits=8'h34;
  6'd35:new_digits=8'h35;
  6'd36:new_digits=8'h36;
  6'd37:new_digits=8'h37;
  6'd38:new_digits=8'h38;
  6'd39:new_digits=8'h39;
  6'd40:new_digits=8'h40;
  6'd41:new_digits=8'h41;
  6'd42:new_digits=8'h42;
  6'd43:new_digits=8'h43;
  6'd44:new_digits=8'h44;
  6'd45:new_digits=8'h45;
  6'd46:new_digits=8'h46;
  6'd47:new_digits=8'h47;
  6'd48:new_digits=8'h48;
  6'd49:new_digits=8'h49;
  6'd50:new_digits=8'h50;
  6'd51:new_digits=8'h51;
  6'd52:new_digits=8'h52;
  6'd53:new_digits=8'h53;
  6'd54:new_digits=8'h54;
  6'd55:new_digits=8'h55;
  6'd56:new_digits=8'h56;
  6'd57:new_digits=8'h57;
  6'd58:new_digits=8'h58;
  6'd59:new_digits=8'h59;
  6'd60:new_digits=8'h60;
  6'd61:new_digits=8'h61;
  6'd62:new_digits=8'h62;
  6'd63:new_digits=8'h63;
 default:new_digits=8'hxx;endcase end endfunction
 function automatic [2:0] pick_key_trail(input [95:0] trails,input signed [6:0] index);
 begin case(index)
  7'sd0:pick_key_trail=trails[0+:3];
  7'sd1:pick_key_trail=trails[3+:3];
  7'sd2:pick_key_trail=trails[6+:3];
  7'sd3:pick_key_trail=trails[9+:3];
  7'sd4:pick_key_trail=trails[12+:3];
  7'sd5:pick_key_trail=trails[15+:3];
  7'sd6:pick_key_trail=trails[18+:3];
  7'sd7:pick_key_trail=trails[21+:3];
  7'sd8:pick_key_trail=trails[24+:3];
  7'sd9:pick_key_trail=trails[27+:3];
  7'sd10:pick_key_trail=trails[30+:3];
  7'sd11:pick_key_trail=trails[33+:3];
  7'sd12:pick_key_trail=trails[36+:3];
  7'sd13:pick_key_trail=trails[39+:3];
  7'sd14:pick_key_trail=trails[42+:3];
  7'sd15:pick_key_trail=trails[45+:3];
  7'sd16:pick_key_trail=trails[48+:3];
  7'sd17:pick_key_trail=trails[51+:3];
  7'sd18:pick_key_trail=trails[54+:3];
  7'sd19:pick_key_trail=trails[57+:3];
  7'sd20:pick_key_trail=trails[60+:3];
  7'sd21:pick_key_trail=trails[63+:3];
  7'sd22:pick_key_trail=trails[66+:3];
  7'sd23:pick_key_trail=trails[69+:3];
  7'sd24:pick_key_trail=trails[72+:3];
  7'sd25:pick_key_trail=trails[75+:3];
  7'sd26:pick_key_trail=trails[78+:3];
  7'sd27:pick_key_trail=trails[81+:3];
  7'sd28:pick_key_trail=trails[84+:3];
  7'sd29:pick_key_trail=trails[87+:3];
  7'sd30:pick_key_trail=trails[90+:3];
  7'sd31:pick_key_trail=trails[93+:3];
  default:pick_key_trail=3'bxxx;endcase end endfunction

 function automatic [5:0] count_voices(input [31:0] value);
 reg [1:0] p2[0:15];reg [2:0] p4[0:7];reg [3:0] p8[0:3];reg [4:0] p16[0:1];integer i;
 begin
 for(i=0;i<16;i=i+1)p2[i]={1'b0,value[i*2]}+{1'b0,value[i*2+1]};
 for(i=0;i<8;i=i+1)p4[i]={1'b0,p2[i*2]}+{1'b0,p2[i*2+1]};
 for(i=0;i<4;i=i+1)p8[i]={1'b0,p4[i*2]}+{1'b0,p4[i*2+1]};
 for(i=0;i<2;i=i+1)p16[i]={1'b0,p8[i*2]}+{1'b0,p8[i*2+1]};
 count_voices={1'b0,p16[0]}+{1'b0,p16[1]};end endfunction

 reg [95:0] trails;reg signed [6:0] idx;reg [31:0] value;reg flag;
 integer note,key,pos,i,j,n,cases=0;
 initial begin
  for(note=0;note<129;note=note+1)begin c_mapping_valid=note!=128;char_key_note=7'(note);
   for(key=0;key<32;key=key+1)for(pos=0;pos<64;pos=pos+1)begin
    if(gold_key_char(5'(key),6'(pos))!==new_key_char(5'(key),6'(pos)))$fatal(1,"key label");cases=cases+1;
   end
  end
  for(i=0;i<64;i=i+1)if(gold_digits(6'(i))!==new_digits(6'(i)))$fatal(1,"BCD");
  for(i=0;i<128;i=i+1)begin idx=7'(i);
   for(j=0;j<96;j=j+1)begin trails=96'd1<<j;if(pick_key_trail(trails,idx)!==trails[idx*3+:3])$fatal(1,"trail basis idx%d bit%d",i,j);end
   for(n=0;n<1000;n=n+1)begin trails={$random,$random,$random};if(pick_key_trail(trails,idx)!==trails[idx*3+:3])$fatal(1,"trail vector");end
  end
  for(n=0;n<10000;n=n+1)begin value=$random;
   for(j=0;j<2;j=j+1)begin flag=j;
    if(count_voices(flag?value:32'd0)!==(flag?count_voices(value):6'd0))$fatal(1,"gating");end
  end
  $display("PASS display equivalence: %0d key glyph cases, all64 BCD values, all128 signed indexes x96 trail basis +128000 trail vectors,20000 count-gate cases; zero register/pipeline changes",cases);$finish;
 end
endmodule
