`default_nettype none
(* syn_srlstyle="distributed_ram" *)
module pre_visual_labels #(parameter SAMPLE_RATE=48000)(
 input wire [11:0] x_early,y_early,input wire peak_valid,input wire [15:0] peak_hz,
 input wire xy_direct,xy_signal,xy_mixed,input wire signed [5:0] xy_shift,
 output reg ink,input wire status_live,input wire [511:0] status_data,output reg [23:0] color,output reg [1:0] coverage,input wire [1:0] spectrum_range,input wire clk
);
 // Private, preserved copy of the renderer's draw_x/draw_y register: the
 // inputs are one stage earlier, so x/y here equal draw_x/draw_y every clock.
 (* syn_preserve=1 *) reg [11:0] x,y;
 always @(posedge clk)begin x<=x_early;y<=y_early;end
 wire note_valid=status_live && status_data[3] && status_data[11+:7]>=36 && status_data[11+:7]<=96;
 wire voices_valid=status_live && status_data[4];
 wire env_valid=status_live && status_data[5];
 wire keys_valid=status_live && status_data[0];
 wire mapping_valid=status_live && status_data[1];
 function automatic [5:0] count_voices(input [31:0] value);
 reg [1:0] p2[0:15];reg [2:0] p4[0:7];reg [3:0] p8[0:3];reg [4:0] p16[0:1];integer i;
 begin
 for(i=0;i<16;i=i+1)p2[i]={1'b0,value[i*2]}+{1'b0,value[i*2+1]};
 for(i=0;i<8;i=i+1)p4[i]={1'b0,p2[i*2]}+{1'b0,p2[i*2+1]};
 for(i=0;i<4;i=i+1)p8[i]={1'b0,p4[i*2]}+{1'b0,p4[i*2+1]};
 for(i=0;i<2;i=i+1)p16[i]={1'b0,p8[i*2]}+{1'b0,p8[i*2+1]};
 count_voices={1'b0,p16[0]}+{1'b0,p16[1]};end endfunction
 function automatic [31:0] decimal_power(input integer place);begin case(place)0:decimal_power=1;1:decimal_power=10;2:decimal_power=100;3:decimal_power=1000;default:decimal_power=10000;endcase end endfunction
 function automatic [15:0] decimal(input [15:0] v,input integer place);begin case(place)
 0:decimal=16'd48+16'(v%16'd10);1:decimal=16'd48+16'((v/16'd10)%16'd10);2:decimal=16'd48+16'((v/16'd100)%16'd10);3:decimal=16'd48+16'((v/16'd1000)%16'd10);default:decimal=16'd48+16'((v/16'd10000)%16'd10);endcase end endfunction
 function automatic [15:0] decimal_trim(input [15:0] v,input integer place);begin decimal_trim=(place>0 && v<decimal_power(place))?16'd32:decimal(v,place);end endfunction
 function automatic [15:0] note_char(input [6:0] note,input integer pos);reg [3:0] pc,octave;begin pc=note%7'd12;octave=note/7'd12-7'd1;note_char=16'd32;
 if(pos==0)case(pc)0,1:note_char=67;2,3:note_char=68;4:note_char=69;5,6:note_char=70;7,8:note_char=71;9,10:note_char=65;11:note_char=66;default:note_char=45;endcase
 else if(pos==1)note_char=(pc==1 || pc==3 || pc==6 || pc==8 || pc==10)?16'd35:16'd48+{12'd0,octave};
 else note_char=(pc==1 || pc==3 || pc==6 || pc==8 || pc==10)?16'd48+{12'd0,octave}:16'd32;
 end endfunction
 function automatic [15:0] key_char(input [4:0] key,input [5:0] pos);reg [6:0] note;begin note=char_key_note;
 if(c_mapping_valid && note>=36 && note<=96)key_char=note_char(note,pos);
 else if(pos==0)key_char=16'd75;else if(pos==1)key_char=decimal(32'(key%16+1),key%16+1>=10?1:0);else key_char=key%16+1>=10?decimal(32'(key%16+1),0):16'd32;
 end endfunction
 function automatic [15:0] timbre_char(input integer pos);begin timbre_char=16'd32;
 if(!char_live || !char_status[2] || char_status[8+:3]>4)timbre_char=pos<2?16'd45:16'd32;
 else case(char_status[8+:3])
 0:case(pos)0:timbre_char=16'h94a2;1:timbre_char=16'h7434;default:timbre_char=32;endcase
 1:case(pos)0:timbre_char=16'h7ba1;1:timbre_char=16'h98ce;2:timbre_char=16'h7434;default:timbre_char=32;endcase
 2:case(pos)0:timbre_char=16'h957f;1:timbre_char=16'h7b1b;default:timbre_char=32;endcase
 3:case(pos)0:timbre_char=16'h5409;1:timbre_char=16'h4ed6;default:timbre_char=32;endcase
 4:case(pos)0:timbre_char=16'h949f;1:timbre_char=16'h7434;default:timbre_char=32;endcase
 default:timbre_char=45;endcase
 end endfunction
 function automatic [15:0] xy_char(input integer pos);begin
 if(char_mixed)case(pos)0:xy_char=16'h5207;1:xy_char=16'h6362;2:xy_char=16'h4e2d;default:xy_char=32;endcase
 else if(!char_signal)case(pos)0:xy_char=16'h65e0;1:xy_char=16'h4fe1;2:xy_char=16'h53f7;default:xy_char=32;endcase
 else case(pos)0:xy_char=char_direct?16'h53cc:16'h5355;1:xy_char=16'h58f0;2:xy_char=16'h90e8;default:xy_char=32;endcase
 end endfunction

 wire mode_valid=status_live && status_data[455] && status_data[456+:2]!=3;
 wire [1:0] mode=status_data[456+:2];
 wire guide_mode=mode_valid && mode==2;
 wire [2:0] guide_state=status_data[490+:3];
 wire target_valid=guide_mode && keys_valid && (guide_state==2 || guide_state==3);
 wire [31:0] target_keys=target_valid?status_data[458+:32]:32'd0;
 wire [31:0] actual_keys=keys_valid?status_data[18+:32]:32'd0;
 wire [5:0] target_count=count_voices(target_keys & ~actual_keys);
 wire [5:0] pressed_count=count_voices(actual_keys);
 wire [5:0] wrong_count=count_voices(target_valid?(actual_keys & ~target_keys):32'd0);
 function automatic [31:0] axis_frequency(input integer tick);begin axis_frequency=32'((64'(SAMPLE_RATE)*(64'(char_range)+1)*64'(tick))/48);end endfunction
 reg [15:0] static_character_q;
 function automatic [15:0] static_constant(input [13:0] index);
 begin case(index)
 14'd0:static_constant=16'h5f26;
 14'd1:static_constant=16'h52a8;
 14'd2:static_constant=16'h667a;
 14'd3:static_constant=16'h97f3;
 14'd64:static_constant=16'h6a21;
 14'd65:static_constant=16'h5f0f;
 14'd192:static_constant=16'h97f3;
 14'd193:static_constant=16'h8272;
 14'd320:static_constant=16'h97f3;
 14'd321:static_constant=16'h7b26;
 14'd448:static_constant=16'h6d3b;
 14'd449:static_constant=16'h8dc3;
 14'd450:static_constant=16'h58f0;
 14'd451:static_constant=16'h90e8;
 14'd576:static_constant=16'h91c7;
 14'd577:static_constant=16'h6837;
 14'd578:static_constant=16'h7387;
 14'd704:static_constant=16'h6ce2;
 14'd705:static_constant=16'h5f62;
 14'd768:static_constant=16'h0031;
 14'd769:static_constant=16'h0030;
 14'd770:static_constant=16'h002e;
 14'd771:static_constant=16'h0036;
 14'd772:static_constant=16'h0037;
 14'd773:static_constant=16'h0020;
 14'd774:static_constant=16'h006d;
 14'd775:static_constant=16'h0073;
 14'd832:static_constant=16'h0041;
 14'd833:static_constant=16'h0044;
 14'd834:static_constant=16'h0053;
 14'd835:static_constant=16'h0052;
 14'd836:static_constant=16'h0020;
 14'd896:static_constant=16'h5305;
 14'd897:static_constant=16'h7edc;
 14'd960:static_constant=16'h58f0;
 14'd961:static_constant=16'h90e8;
 14'd1088:static_constant=16'h58f0;
 14'd1089:static_constant=16'h90e8;
 14'd1090:static_constant=16'h6d3b;
 14'd1091:static_constant=16'h52a8;
 14'd1152:static_constant=16'h004c;
 14'd1153:static_constant=16'h0020;
 14'd1154:static_constant=16'h0052;
 14'd1216:static_constant=16'h674e;
 14'd1217:static_constant=16'h8428;
 14'd1218:static_constant=16'h5982;
 14'd1219:static_constant=16'h56fe;
 14'd1344:static_constant=16'h5b9e;
 14'd1345:static_constant=16'h65f6;
 14'd1408:static_constant=16'h0020;
 14'd1409:static_constant=16'h0046;
 14'd1410:static_constant=16'h0046;
 14'd1411:static_constant=16'h0054;
 14'd1412:static_constant=16'h0020;
 14'd1472:static_constant=16'h9891;
 14'd1473:static_constant=16'h8c31;
 14'd1536:static_constant=16'h5cf0;
 14'd1537:static_constant=16'h503c;
 14'd2112:static_constant=16'h5f3a;
 14'd2176:static_constant=16'h5f31;
 14'd2240:static_constant=16'h5f39;
 14'd2241:static_constant=16'h5bf9;
 14'd2242:static_constant=16'h518d;
 14'd2243:static_constant=16'h7ee7;
 14'd2244:static_constant=16'h7eed;
 14'd2368:static_constant=16'h5f85;
 14'd2369:static_constant=16'h6309;
 14'd2496:static_constant=16'h5df2;
 14'd2497:static_constant=16'h6309;
 14'd2624:static_constant=16'h6309;
 14'd2625:static_constant=16'h9519;
 14'd2752:static_constant=16'h5df2;
 14'd2753:static_constant=16'h5b8c;
 14'd2754:static_constant=16'h6210;
 14'd2880:static_constant=16'h002b;
 14'd2881:static_constant=16'h0031;
 14'd2944:static_constant=16'h0030;
 14'd3008:static_constant=16'h002d;
 14'd3009:static_constant=16'h0031;
 14'd3072:static_constant=16'h0031;
 14'd3136:static_constant=16'h0030;
 14'd3137:static_constant=16'h002e;
 14'd3138:static_constant=16'h0035;
 14'd3200:static_constant=16'h0030;
 14'd3264:static_constant=16'h89e6;
 14'd3265:static_constant=16'h6478;
 14'd3266:static_constant=16'h7434;
 14'd3328:static_constant=16'h0020;
 14'd3329:static_constant=16'h0031;
 14'd3392:static_constant=16'h89e6;
 14'd3393:static_constant=16'h6478;
 14'd3394:static_constant=16'h7434;
 14'd3456:static_constant=16'h0020;
 14'd3457:static_constant=16'h0032;
 14'd5696:static_constant=16'h672a;
 14'd5697:static_constant=16'h63a5;
 14'd5698:static_constant=16'h5165;
 default:static_constant=16'd32;endcase end endfunction
 // Same stage as attr_char; the following character edge handles only
 // dynamic text and kind selection. Overall label latency remains21 clocks.
 always @(posedge clk)static_character_q<=static_constant({attr_pipe[14][35:28],attr_pipe[14][19:14]});
 function automatic [15:0] static_char(input [13:0] index,input live_mode_valid,input [1:0] selected_mode,input [2:0] selected_state,input live_keys_valid,input [5:0] count_target,count_actual,count_wrong,input [15:0] completed_events,input [19:0] completed_bcd);begin static_char=static_character_q;case(index)
 14'd128:static_char=(live_mode_valid && selected_mode==0?16'h81ea:live_mode_valid && selected_mode==1?16'h81ea:live_mode_valid && selected_mode==2?16'h6307:16'd32);
 14'd129:static_char=(live_mode_valid && selected_mode==0?16'h7531:live_mode_valid && selected_mode==1?16'h52a8:live_mode_valid && selected_mode==2?16'h5bfc:16'd32);
 14'd130:static_char=(live_mode_valid && selected_mode==0?16'h6f14:live_mode_valid && selected_mode==1?16'h64ad:live_mode_valid && selected_mode==2?16'h6a21:16'd32);
 14'd131:static_char=(live_mode_valid && selected_mode==0?16'h594f:live_mode_valid && selected_mode==1?16'h653e:live_mode_valid && selected_mode==2?16'h5f0f:16'd32);
 14'd2304:static_char=(selected_state==0?16'h672a:selected_state==1?16'h7b49:selected_state==2 && !live_keys_valid?16'h7b49:selected_state==2 && count_wrong!=0?16'h8bf7:selected_state==2?16'h7b49:selected_state==3?16'h8bf7:selected_state==4?16'h5df2:selected_state==5?16'h6f14:selected_state==6?16'h4f11:selected_state==7?16'h7b49:16'd32);
 14'd2305:static_char=(selected_state==0?16'h5f00:selected_state==1?16'h5f85:selected_state==2 && !live_keys_valid?16'h5f85:selected_state==2 && count_wrong!=0?16'h68c0:selected_state==2?16'h5f85:selected_state==3?16'h677e:selected_state==4?16'h6682:selected_state==5?16'h594f:selected_state==6?16'h6b62:selected_state==7?16'h5f85:16'd32);
 14'd2306:static_char=(selected_state==0?16'h59cb:selected_state==1?16'h66f2:selected_state==2 && !live_keys_valid?16'h8fde:selected_state==2 && count_wrong!=0?16'h67e5:selected_state==2?16'h6309:selected_state==3?16'h5f00:selected_state==4?16'h505c:selected_state==5?16'h5b8c:selected_state==6?16'h0020:selected_state==7?16'h8fde:16'd32);
 14'd2307:static_char=(selected_state==0?16'h0020:selected_state==1?16'h8c31:selected_state==2 && !live_keys_valid?16'h63a5:selected_state==2 && count_wrong!=0?16'h7434:selected_state==2?16'h952e:selected_state==3?16'h7434:selected_state==4?16'h0020:selected_state==5?16'h6210:selected_state==6?16'h0020:selected_state==7?16'h63a5:16'd32);
 14'd2308:static_char=(selected_state==0?16'h0020:selected_state==1?16'h0020:selected_state==2 && !live_keys_valid?16'h0020:selected_state==2 && count_wrong!=0?16'h952e:selected_state==2?16'h0020:selected_state==3?16'h952e:selected_state==4?16'h0020:selected_state==5?16'h0020:selected_state==6?16'h0020:selected_state==7?16'h0020:16'd32);
 14'd2432:static_char=decimal({26'd0,count_target},1);
 14'd2433:static_char=decimal({26'd0,count_target},0);
 14'd2560:static_char=decimal({26'd0,count_actual},1);
 14'd2561:static_char=decimal({26'd0,count_actual},0);
 14'd2688:static_char=decimal({26'd0,count_wrong},1);
 14'd2689:static_char=decimal({26'd0,count_wrong},0);
 14'd2816:static_char=completed_character_q[4];
 14'd2817:static_char=completed_character_q[3];
 14'd2818:static_char=completed_character_q[2];
 14'd2819:static_char=completed_character_q[1];
 14'd2820:static_char=completed_character_q[0];
 default:static_char=static_character_q;endcase end endfunction

 localparam [3:0] STATIC=0,KEY=1,TIMBRE=2,NOTE=3,VOICES=4,VOICEID=5,SAMPLE=6,PEAK=7,XY=8,KEYSTATUS=9,AXIS=10;
 wire [3:0] kind;wire [7:0] argument,font_size;wire [5:0] pos,col,row;wire [1:0] tone;
 reg [15:0] ch,ch_next;reg [31:0] numeric_value;reg [2:0] numeric_place;
 // Exact original 2-bit anti-aliased coverage, tightly packed by font size.
 reg [1:0] font_rom[0:106995];
 initial $readmemh("assets/display_font_coverage.hex",font_rom);
 wire[16:0] base_q;wire font_found;
 pre_visual_glyph_index glyph_index(clk,attr_glyph[27:20],ch,base_q,font_found);
 reg [16:0] font_addr_q;reg [11:0] row_product_q;reg [5:0] col_q;reg [12:0] glyph_offset_q;
 reg visible_q,visible_glyph,visible_addr;reg [23:0] color_q,color_glyph,color_addr;

 always @(posedge clk)begin
  ch<=ch_next;
  row_product_q<=12'(attr_glyph[5:0])*12'(attr_glyph[27:20]);col_q<=attr_glyph[11:6];
  visible_q<=attr_glyph[5:0]<attr_glyph[27:20] && attr_glyph[11:6]<attr_glyph[27:20];
  case(attr_glyph[13:12])1:color_q<=24'hfaf8f1;2:color_q<=24'hf4f4ec;3:color_q<=24'h4d6269;default:color_q<=24'he6e9e3;endcase
  glyph_offset_q<=13'(row_product_q)+13'(col_q);visible_glyph<=visible_q;color_glyph<=color_q;
  font_addr_q<=base_q+17'(glyph_offset_q);visible_addr<=visible_glyph && font_found;color_addr<=color_glyph;
 end


 wire hit_0=((1'b1) && x>=146 && x<314 && y>=47 && y<89);
 // Only selected inside [146,314) x [47,89); truncated coordinates are exact there.
 wire [7:0] label_dx_0=8'(x-12'd146);
 wire [5:0] label_dy_0=6'(y-12'd47);
 wire [39:0] region_0=hit_0?{STATIC,8'd0,8'd42,6'(label_dx_0/8'd42),2'd1,6'(label_dx_0%8'd42+8'd0),6'(label_dy_0)}:40'd0;
 wire hit_1=((1'b1) && x>=466 && x<506 && y>=39 && y<59);
 // Only selected inside [466,506) x [39,59); truncated coordinates are exact there.
 wire [5:0] label_dx_1=6'(x-12'd466);
 wire [4:0] label_dy_1=5'(y-12'd39);
 wire [39:0] region_1=hit_1?{STATIC,8'd1,8'd20,6'(label_dx_1/6'd20),2'd0,6'(label_dx_1%6'd20+6'd0),6'(label_dy_1)}:40'd0;
 wire hit_2=((1'b1) && x>=466 && x<578 && y>=73 && y<101);
 // Only selected inside [466,578) x [73,101); truncated coordinates are exact there.
 wire [6:0] label_dx_2=7'(x-12'd466);
 wire [4:0] label_dy_2=5'(y-12'd73);
 wire [39:0] region_2=hit_2?{STATIC,8'd2,8'd28,6'(label_dx_2/7'd28),2'd1,6'(label_dx_2%7'd28+7'd0),6'(label_dy_2)}:40'd0;
 wire hit_3=((1'b1) && x>=746 && x<786 && y>=39 && y<59);
 // Only selected inside [746,786) x [39,59); truncated coordinates are exact there.
 wire [5:0] label_dx_3=6'(x-12'd746);
 wire [4:0] label_dy_3=5'(y-12'd39);
 wire [39:0] region_3=hit_3?{STATIC,8'd3,8'd20,6'(label_dx_3/6'd20),2'd0,6'(label_dx_3%6'd20+6'd0),6'(label_dy_3)}:40'd0;
 wire hit_4=((1'b1) && x>=746 && x<830 && y>=73 && y<101);
 // Only selected inside [746,830) x [73,101); truncated coordinates are exact there.
 wire [6:0] label_dx_4=7'(x-12'd746);
 wire [4:0] label_dy_4=5'(y-12'd73);
 wire [39:0] region_4=hit_4?{TIMBRE,8'd4,8'd28,6'(label_dx_4/7'd28),2'd1,6'(label_dx_4%7'd28+7'd0),6'(label_dy_4)}:40'd0;
 wire hit_5=((1'b1) && x>=986 && x<1026 && y>=39 && y<59);
 // Only selected inside [986,1026) x [39,59); truncated coordinates are exact there.
 wire [5:0] label_dx_5=6'(x-12'd986);
 wire [4:0] label_dy_5=5'(y-12'd39);
 wire [39:0] region_5=hit_5?{STATIC,8'd5,8'd20,6'(label_dx_5/6'd20),2'd0,6'(label_dx_5%6'd20+6'd0),6'(label_dy_5)}:40'd0;
 wire hit_6=((1'b1) && x>=986 && x<1046 && y>=73 && y<101);
 // Only selected inside [986,1046) x [73,101); truncated coordinates are exact there.
 wire [5:0] label_dx_6=6'(x-12'd986);
 wire [4:0] label_dy_6=5'(y-12'd73);
 wire [39:0] region_6=hit_6?{NOTE,8'd6,8'd28,6'(label_dx_6/6'd20),2'd2,6'(label_dx_6%6'd20+6'd4),6'(label_dy_6)}:40'd0;
 wire hit_7=((1'b1) && x>=1236 && x<1316 && y>=39 && y<59);
 // Only selected inside [1236,1316) x [39,59); truncated coordinates are exact there.
 wire [6:0] label_dx_7=7'(x-12'd1236);
 wire [4:0] label_dy_7=5'(y-12'd39);
 wire [39:0] region_7=hit_7?{STATIC,8'd7,8'd20,6'(label_dx_7/7'd20),2'd0,6'(label_dx_7%7'd20+7'd0),6'(label_dy_7)}:40'd0;
 wire hit_8=((1'b1) && x>=1236 && x<1376 && y>=73 && y<101);
 // Only selected inside [1236,1376) x [73,101); truncated coordinates are exact there.
 wire [7:0] label_dx_8=8'(x-12'd1236);
 wire [4:0] label_dy_8=5'(y-12'd73);
 wire [39:0] region_8=hit_8?{VOICES,8'd8,8'd28,6'(label_dx_8/8'd20),2'd2,6'(label_dx_8%8'd20+8'd4),6'(label_dy_8)}:40'd0;
 wire hit_9=((1'b1) && x>=1546 && x<1606 && y>=39 && y<59);
 // Only selected inside [1546,1606) x [39,59); truncated coordinates are exact there.
 wire [5:0] label_dx_9=6'(x-12'd1546);
 wire [4:0] label_dy_9=5'(y-12'd39);
 wire [39:0] region_9=hit_9?{STATIC,8'd9,8'd20,6'(label_dx_9/6'd20),2'd0,6'(label_dx_9%6'd20+6'd0),6'(label_dy_9)}:40'd0;
 wire hit_10=((1'b1) && x>=1546 && x<1666 && y>=73 && y<101);
 // Only selected inside [1546,1666) x [73,101); truncated coordinates are exact there.
 wire [6:0] label_dx_10=7'(x-12'd1546);
 wire [4:0] label_dy_10=5'(y-12'd73);
 wire [39:0] region_10=hit_10?{SAMPLE,8'd10,8'd28,6'(label_dx_10/7'd20),2'd1,6'(label_dx_10%7'd20+7'd4),6'(label_dy_10)}:40'd0;
 wire hit_11=((1'b1) && x>=52 && x<108 && y>=139 && y<167);
 // Only selected inside [52,108) x [139,167); truncated coordinates are exact there.
 wire [5:0] label_dx_11=6'(x-12'd52);
 wire [4:0] label_dy_11=5'(y-12'd139);
 wire [39:0] region_11=hit_11?{STATIC,8'd11,8'd28,6'(label_dx_11/6'd28),2'd1,6'(label_dx_11%6'd28+6'd0),6'(label_dy_11)}:40'd0;
 wire hit_12=((1'b1) && x>=530 && x<642 && y>=147 && y<167);
 // Only selected inside [530,642) x [147,167); truncated coordinates are exact there.
 wire [6:0] label_dx_12=7'(x-12'd530);
 wire [4:0] label_dy_12=5'(y-12'd147);
 wire [39:0] region_12=hit_12?{STATIC,8'd12,8'd20,6'(label_dx_12/7'd14),2'd0,6'(label_dx_12%7'd14+7'd3),6'(label_dy_12)}:40'd0;
 wire hit_13=((1'b1) && x>=792 && x<892 && y>=139 && y<167);
 // Only selected inside [792,892) x [139,167); truncated coordinates are exact there.
 wire [6:0] label_dx_13=7'(x-12'd792);
 wire [4:0] label_dy_13=5'(y-12'd139);
 wire [39:0] region_13=hit_13?{STATIC,8'd13,8'd28,6'(label_dx_13/7'd20),2'd1,6'(label_dx_13%7'd20+7'd4),6'(label_dy_13)}:40'd0;
 wire hit_14=((1'b1) && x>=892 && x<948 && y>=139 && y<167);
 // Only selected inside [892,948) x [139,167); truncated coordinates are exact there.
 wire [5:0] label_dx_14=6'(x-12'd892);
 wire [4:0] label_dy_14=5'(y-12'd139);
 wire [39:0] region_14=hit_14?{STATIC,8'd14,8'd28,6'(label_dx_14/6'd28),2'd1,6'(label_dx_14%6'd28+6'd0),6'(label_dy_14)}:40'd0;
 wire hit_15=((1'b1) && x>=1228 && x<1264 && y>=149 && y<167);
 // Only selected inside [1228,1264) x [149,167); truncated coordinates are exact there.
 wire [5:0] label_dx_15=6'(x-12'd1228);
 wire [4:0] label_dy_15=5'(y-12'd149);
 wire [39:0] region_15=hit_15?{STATIC,8'd15,8'd18,6'(label_dx_15/6'd18),2'd0,6'(label_dx_15%6'd18+6'd0),6'(label_dy_15)}:40'd0;
 wire hit_16=((1'b1) && x>=1306 && x<1332 && y>=149 && y<167);
 // Only selected inside [1306,1332) x [149,167); truncated coordinates are exact there.
 wire [4:0] label_dx_16=5'(x-12'd1306);
 wire [4:0] label_dy_16=5'(y-12'd149);
 wire [39:0] region_16=hit_16?{VOICEID,8'd16,8'd18,6'(label_dx_16/6'd13),2'd0,6'(label_dx_16%6'd13+6'd2),6'(label_dy_16)}:40'd0;
 wire hit_17=((1'b1) && x>=1192 && x<1264 && y>=195 && y<213);
 // Only selected inside [1192,1264) x [195,213); truncated coordinates are exact there.
 wire [6:0] label_dx_17=7'(x-12'd1192);
 wire [4:0] label_dy_17=5'(y-12'd195);
 wire [39:0] region_17=hit_17?{STATIC,8'd17,8'd18,6'(label_dx_17/7'd18),2'd0,6'(label_dx_17%7'd18+7'd0),6'(label_dy_17)}:40'd0;
 wire hit_18=((1'b1) && x>=1420 && x<1450 && y>=435 && y<449);
 // Only selected inside [1420,1450) x [435,449); truncated coordinates are exact there.
 wire [4:0] label_dx_18=5'(x-12'd1420);
 wire [3:0] label_dy_18=4'(y-12'd435);
 wire [39:0] region_18=hit_18?{STATIC,8'd18,8'd14,6'(label_dx_18/6'd10),2'd0,6'(label_dx_18%6'd10+6'd2),6'(label_dy_18)}:40'd0;
 wire hit_19=((1'b1) && x>=1534 && x<1646 && y>=139 && y<167);
 // Only selected inside [1534,1646) x [139,167); truncated coordinates are exact there.
 wire [6:0] label_dx_19=7'(x-12'd1534);
 wire [4:0] label_dy_19=5'(y-12'd139);
 wire [39:0] region_19=hit_19?{STATIC,8'd19,8'd28,6'(label_dx_19/7'd28),2'd1,6'(label_dx_19%7'd28+7'd0),6'(label_dy_19)}:40'd0;
 wire hit_20=((1'b1) && x>=1772 && x<1826 && y>=149 && y<167);
 // Only selected inside [1772,1826) x [149,167); truncated coordinates are exact there.
 wire [5:0] label_dx_20=6'(x-12'd1772);
 wire [4:0] label_dy_20=5'(y-12'd149);
 wire [39:0] region_20=hit_20?{XY,8'd20,8'd18,6'(label_dx_20/6'd18),2'd0,6'(label_dx_20%6'd18+6'd0),6'(label_dy_20)}:40'd0;
 wire hit_21=((1'b1) && x>=52 && x<108 && y>=509 && y<537);
 // Only selected inside [52,108) x [509,537); truncated coordinates are exact there.
 wire [5:0] label_dx_21=6'(x-12'd52);
 wire [4:0] label_dy_21=5'(y-12'd509);
 wire [39:0] region_21=hit_21?{STATIC,8'd21,8'd28,6'(label_dx_21/6'd28),2'd1,6'(label_dx_21%6'd28+6'd0),6'(label_dy_21)}:40'd0;
 wire hit_22=((1'b1) && x>=108 && x<208 && y>=509 && y<537);
 // Only selected inside [108,208) x [509,537); truncated coordinates are exact there.
 wire [6:0] label_dx_22=7'(x-12'd108);
 wire [4:0] label_dy_22=5'(y-12'd509);
 wire [39:0] region_22=hit_22?{STATIC,8'd22,8'd28,6'(label_dx_22/7'd20),2'd1,6'(label_dx_22%7'd20+7'd4),6'(label_dy_22)}:40'd0;
 wire hit_23=((1'b1) && x>=208 && x<264 && y>=509 && y<537);
 // Only selected inside [208,264) x [509,537); truncated coordinates are exact there.
 wire [5:0] label_dx_23=6'(x-12'd208);
 wire [4:0] label_dy_23=5'(y-12'd509);
 wire [39:0] region_23=hit_23?{STATIC,8'd23,8'd28,6'(label_dx_23/6'd28),2'd1,6'(label_dx_23%6'd28+6'd0),6'(label_dy_23)}:40'd0;
 wire hit_24=((1'b1) && x>=1482 && x<1522 && y>=515 && y<535);
 // Only selected inside [1482,1522) x [515,535); truncated coordinates are exact there.
 wire [5:0] label_dx_24=6'(x-12'd1482);
 wire [4:0] label_dy_24=5'(y-12'd515);
 wire [39:0] region_24=hit_24?{STATIC,8'd24,8'd20,6'(label_dx_24/6'd20),2'd0,6'(label_dx_24%6'd20+6'd0),6'(label_dy_24)}:40'd0;
 wire hit_25=((1'b1) && x>=1548 && x<1660 && y>=515 && y<535);
 // Only selected inside [1548,1660) x [515,535); truncated coordinates are exact there.
 wire [6:0] label_dx_25=7'(x-12'd1548);
 wire [4:0] label_dy_25=5'(y-12'd515);
 wire [39:0] region_25=hit_25?{PEAK,8'd25,8'd20,6'(label_dx_25/7'd14),2'd0,6'(label_dx_25%7'd14+7'd3),6'(label_dy_25)}:40'd0;
 wire hit_26=((1'b1) && x>=32 && x<120 && y>=556 && y<572);
 // Only selected inside [32,120) x [556,572); truncated coordinates are exact there.
 wire [6:0] label_dx_26=7'(x-12'd32);
 wire [3:0] label_dy_26=4'(y-12'd556);
 wire [39:0] region_26=hit_26?{AXIS,8'd0,8'd16,6'(label_dx_26/7'd11),2'd0,6'(label_dx_26%7'd11+7'd2),6'(label_dy_26)}:40'd0;
 wire hit_27=((1'b1) && x>=325 && x<413 && y>=556 && y<572);
 // Only selected inside [325,413) x [556,572); truncated coordinates are exact there.
 wire [6:0] label_dx_27=7'(x-12'd325);
 wire [3:0] label_dy_27=4'(y-12'd556);
 wire [39:0] region_27=hit_27?{AXIS,8'd1,8'd16,6'(label_dx_27/7'd11),2'd0,6'(label_dx_27%7'd11+7'd2),6'(label_dy_27)}:40'd0;
 wire hit_28=((1'b1) && x>=618 && x<706 && y>=556 && y<572);
 // Only selected inside [618,706) x [556,572); truncated coordinates are exact there.
 wire [6:0] label_dx_28=7'(x-12'd618);
 wire [3:0] label_dy_28=4'(y-12'd556);
 wire [39:0] region_28=hit_28?{AXIS,8'd2,8'd16,6'(label_dx_28/7'd11),2'd0,6'(label_dx_28%7'd11+7'd2),6'(label_dy_28)}:40'd0;
 wire hit_29=((1'b1) && x>=912 && x<1000 && y>=556 && y<572);
 // Only selected inside [912,1000) x [556,572); truncated coordinates are exact there.
 wire [6:0] label_dx_29=7'(x-12'd912);
 wire [3:0] label_dy_29=4'(y-12'd556);
 wire [39:0] region_29=hit_29?{AXIS,8'd3,8'd16,6'(label_dx_29/7'd11),2'd0,6'(label_dx_29%7'd11+7'd2),6'(label_dy_29)}:40'd0;
 wire hit_30=((1'b1) && x>=1205 && x<1293 && y>=556 && y<572);
 // Only selected inside [1205,1293) x [556,572); truncated coordinates are exact there.
 wire [6:0] label_dx_30=7'(x-12'd1205);
 wire [3:0] label_dy_30=4'(y-12'd556);
 wire [39:0] region_30=hit_30?{AXIS,8'd4,8'd16,6'(label_dx_30/7'd11),2'd0,6'(label_dx_30%7'd11+7'd2),6'(label_dy_30)}:40'd0;
 wire hit_31=((1'b1) && x>=1498 && x<1586 && y>=556 && y<572);
 // Only selected inside [1498,1586) x [556,572); truncated coordinates are exact there.
 wire [6:0] label_dx_31=7'(x-12'd1498);
 wire [3:0] label_dy_31=4'(y-12'd556);
 wire [39:0] region_31=hit_31?{AXIS,8'd5,8'd16,6'(label_dx_31/7'd11),2'd0,6'(label_dx_31%7'd11+7'd2),6'(label_dy_31)}:40'd0;
 wire hit_32=((1'b1) && x>=1791 && x<1879 && y>=556 && y<572);
 // Only selected inside [1791,1879) x [556,572); truncated coordinates are exact there.
 wire [6:0] label_dx_32=7'(x-12'd1791);
 wire [3:0] label_dy_32=4'(y-12'd556);
 wire [39:0] region_32=hit_32?{AXIS,8'd6,8'd16,6'(label_dx_32/7'd11),2'd0,6'(label_dx_32%7'd11+7'd2),6'(label_dy_32)}:40'd0;
 wire hit_33=((1'b1) && x>=50 && x<64 && y>=598 && y<612);
 // Only selected inside [50,64) x [598,612); truncated coordinates are exact there.
 wire [3:0] label_dx_33=4'(x-12'd50);
 wire [3:0] label_dy_33=4'(y-12'd598);
 wire [39:0] region_33=hit_33?{STATIC,8'd33,8'd14,6'(label_dx_33/6'd14),2'd0,6'(label_dx_33%6'd14+6'd0),6'(label_dy_33)}:40'd0;
 wire hit_34=((1'b1) && x>=50 && x<64 && y>=674 && y<688);
 // Only selected inside [50,64) x [674,688); truncated coordinates are exact there.
 wire [3:0] label_dx_34=4'(x-12'd50);
 wire [3:0] label_dy_34=4'(y-12'd674);
 wire [39:0] region_34=hit_34?{STATIC,8'd34,8'd14,6'(label_dx_34/6'd14),2'd0,6'(label_dx_34%6'd14+6'd0),6'(label_dy_34)}:40'd0;
 wire hit_35=((guide_mode) && x>=52 && x<142 && y>=755 && y<773);
 // Only selected inside [52,142) x [755,773); truncated coordinates are exact there.
 wire [6:0] label_dx_35=7'(x-12'd52);
 wire [4:0] label_dy_35=5'(y-12'd755);
 wire [39:0] region_35=hit_35?{STATIC,8'd35,8'd18,6'(label_dx_35/7'd18),2'd1,6'(label_dx_35%7'd18+7'd0),6'(label_dy_35)}:40'd0;
 wire hit_36=((guide_mode) && x>=1560 && x<1650 && y>=755 && y<773);
 // Only selected inside [1560,1650) x [755,773); truncated coordinates are exact there.
 wire [6:0] label_dx_36=7'(x-12'd1560);
 wire [4:0] label_dy_36=5'(y-12'd755);
 wire [39:0] region_36=hit_36?{STATIC,8'd36,8'd18,6'(label_dx_36/7'd18),2'd1,6'(label_dx_36%7'd18+7'd0),6'(label_dy_36)}:40'd0;
 wire hit_37=((guide_mode) && x>=400 && x<436 && y>=755 && y<773);
 // Only selected inside [400,436) x [755,773); truncated coordinates are exact there.
 wire [5:0] label_dx_37=6'(x-12'd400);
 wire [4:0] label_dy_37=5'(y-12'd755);
 wire [39:0] region_37=hit_37?{STATIC,8'd37,8'd18,6'(label_dx_37/6'd18),2'd0,6'(label_dx_37%6'd18+6'd0),6'(label_dy_37)}:40'd0;
 wire hit_38=((guide_mode) && x>=466 && x<494 && y>=754 && y<774);
 // Only selected inside [466,494) x [754,774); truncated coordinates are exact there.
 wire [4:0] label_dx_38=5'(x-12'd466);
 wire [4:0] label_dy_38=5'(y-12'd754);
 wire [39:0] region_38=hit_38?{STATIC,8'd38,8'd20,6'(label_dx_38/6'd14),2'd2,6'(label_dx_38%6'd14+6'd3),6'(label_dy_38)}:40'd0;
 wire hit_39=((guide_mode) && x>=650 && x<686 && y>=755 && y<773);
 // Only selected inside [650,686) x [755,773); truncated coordinates are exact there.
 wire [5:0] label_dx_39=6'(x-12'd650);
 wire [4:0] label_dy_39=5'(y-12'd755);
 wire [39:0] region_39=hit_39?{STATIC,8'd39,8'd18,6'(label_dx_39/6'd18),2'd0,6'(label_dx_39%6'd18+6'd0),6'(label_dy_39)}:40'd0;
 wire hit_40=((guide_mode) && x>=716 && x<744 && y>=754 && y<774);
 // Only selected inside [716,744) x [754,774); truncated coordinates are exact there.
 wire [4:0] label_dx_40=5'(x-12'd716);
 wire [4:0] label_dy_40=5'(y-12'd754);
 wire [39:0] region_40=hit_40?{STATIC,8'd40,8'd20,6'(label_dx_40/6'd14),2'd2,6'(label_dx_40%6'd14+6'd3),6'(label_dy_40)}:40'd0;
 wire hit_41=((guide_mode) && x>=900 && x<936 && y>=755 && y<773);
 // Only selected inside [900,936) x [755,773); truncated coordinates are exact there.
 wire [5:0] label_dx_41=6'(x-12'd900);
 wire [4:0] label_dy_41=5'(y-12'd755);
 wire [39:0] region_41=hit_41?{STATIC,8'd41,8'd18,6'(label_dx_41/6'd18),2'd0,6'(label_dx_41%6'd18+6'd0),6'(label_dy_41)}:40'd0;
 wire hit_42=((guide_mode) && x>=966 && x<994 && y>=754 && y<774);
 // Only selected inside [966,994) x [754,774); truncated coordinates are exact there.
 wire [4:0] label_dx_42=5'(x-12'd966);
 wire [4:0] label_dy_42=5'(y-12'd754);
 wire [39:0] region_42=hit_42?{STATIC,8'd42,8'd20,6'(label_dx_42/6'd14),2'd2,6'(label_dx_42%6'd14+6'd3),6'(label_dy_42)}:40'd0;
 wire hit_43=((guide_mode) && x>=1150 && x<1204 && y>=755 && y<773);
 // Only selected inside [1150,1204) x [755,773); truncated coordinates are exact there.
 wire [5:0] label_dx_43=6'(x-12'd1150);
 wire [4:0] label_dy_43=5'(y-12'd755);
 wire [39:0] region_43=hit_43?{STATIC,8'd43,8'd18,6'(label_dx_43/6'd18),2'd0,6'(label_dx_43%6'd18+6'd0),6'(label_dy_43)}:40'd0;
 wire hit_44=((guide_mode) && x>=1240 && x<1310 && y>=754 && y<774);
 // Only selected inside [1240,1310) x [754,774); truncated coordinates are exact there.
 wire [6:0] label_dx_44=7'(x-12'd1240);
 wire [4:0] label_dy_44=5'(y-12'd754);
 wire [39:0] region_44=hit_44?{STATIC,8'd44,8'd20,6'(label_dx_44/7'd14),2'd0,6'(label_dx_44%7'd14+7'd3),6'(label_dy_44)}:40'd0;
 wire hit_45=((1'b1) && x>=51 && x<73 && y>=209 && y<225);
 // Only selected inside [51,73) x [209,225); truncated coordinates are exact there.
 wire [4:0] label_dx_45=5'(x-12'd51);
 wire [3:0] label_dy_45=4'(y-12'd209);
 wire [39:0] region_45=hit_45?{STATIC,8'd45,8'd16,6'(label_dx_45/6'd11),2'd0,6'(label_dx_45%6'd11+6'd2),6'(label_dy_45)}:40'd0;
 wire hit_46=((1'b1) && x>=55 && x<66 && y>=313 && y<329);
 // Only selected inside [55,66) x [313,329); truncated coordinates are exact there.
 wire [3:0] label_dx_46=4'(x-12'd55);
 wire [3:0] label_dy_46=4'(y-12'd313);
 wire [39:0] region_46=hit_46?{STATIC,8'd46,8'd16,6'(label_dx_46/6'd11),2'd0,6'(label_dx_46%6'd11+6'd2),6'(label_dy_46)}:40'd0;
 wire hit_47=((1'b1) && x>=51 && x<73 && y>=415 && y<431);
 // Only selected inside [51,73) x [415,431); truncated coordinates are exact there.
 wire [4:0] label_dx_47=5'(x-12'd51);
 wire [3:0] label_dy_47=4'(y-12'd415);
 wire [39:0] region_47=hit_47?{STATIC,8'd47,8'd16,6'(label_dx_47/6'd11),2'd0,6'(label_dx_47%6'd11+6'd2),6'(label_dy_47)}:40'd0;
 wire hit_48=((1'b1) && x>=794 && x<805 && y>=206 && y<222);
 // Only selected inside [794,805) x [206,222); truncated coordinates are exact there.
 wire [3:0] label_dx_48=4'(x-12'd794);
 wire [3:0] label_dy_48=4'(y-12'd206);
 wire [39:0] region_48=hit_48?{STATIC,8'd48,8'd16,6'(label_dx_48/6'd11),2'd0,6'(label_dx_48%6'd11+6'd2),6'(label_dy_48)}:40'd0;
 wire hit_49=((1'b1) && x>=794 && x<827 && y>=306 && y<322);
 // Only selected inside [794,827) x [306,322); truncated coordinates are exact there.
 wire [5:0] label_dx_49=6'(x-12'd794);
 wire [3:0] label_dy_49=4'(y-12'd306);
 wire [39:0] region_49=hit_49?{STATIC,8'd49,8'd16,6'(label_dx_49/6'd11),2'd0,6'(label_dx_49%6'd11+6'd2),6'(label_dy_49)}:40'd0;
 wire hit_50=((1'b1) && x>=794 && x<805 && y>=422 && y<438);
 // Only selected inside [794,805) x [422,438); truncated coordinates are exact there.
 wire [3:0] label_dx_50=4'(x-12'd794);
 wire [3:0] label_dy_50=4'(y-12'd422);
 wire [39:0] region_50=hit_50?{STATIC,8'd50,8'd16,6'(label_dx_50/6'd11),2'd0,6'(label_dx_50%6'd11+6'd2),6'(label_dy_50)}:40'd0;
 wire hit_51=((1'b1) && x>=84 && x<162 && y>=804 && y<830);
 // Only selected inside [84,162) x [804,830); truncated coordinates are exact there.
 wire [6:0] label_dx_51=7'(x-12'd84);
 wire [4:0] label_dy_51=5'(y-12'd804);
 wire [39:0] region_51=hit_51?{STATIC,8'd51,8'd26,6'(label_dx_51/7'd26),2'd1,6'(label_dx_51%7'd26+7'd0),6'(label_dy_51)}:40'd0;
 wire hit_52=((1'b1) && x>=162 && x<198 && y>=804 && y<830);
 // Only selected inside [162,198) x [804,830); truncated coordinates are exact there.
 wire [5:0] label_dx_52=6'(x-12'd162);
 wire [4:0] label_dy_52=5'(y-12'd804);
 wire [39:0] region_52=hit_52?{STATIC,8'd52,8'd26,6'(label_dx_52/6'd18),2'd1,6'(label_dx_52%6'd18+6'd4),6'(label_dy_52)}:40'd0;
 wire hit_53=((1'b1) && x>=1028 && x<1106 && y>=804 && y<830);
 // Only selected inside [1028,1106) x [804,830); truncated coordinates are exact there.
 wire [6:0] label_dx_53=7'(x-12'd1028);
 wire [4:0] label_dy_53=5'(y-12'd804);
 wire [39:0] region_53=hit_53?{STATIC,8'd53,8'd26,6'(label_dx_53/7'd26),2'd1,6'(label_dx_53%7'd26+7'd0),6'(label_dy_53)}:40'd0;
 wire hit_54=((1'b1) && x>=1106 && x<1142 && y>=804 && y<830);
 // Only selected inside [1106,1142) x [804,830); truncated coordinates are exact there.
 wire [5:0] label_dx_54=6'(x-12'd1106);
 wire [4:0] label_dy_54=5'(y-12'd804);
 wire [39:0] region_54=hit_54?{STATIC,8'd54,8'd26,6'(label_dx_54/6'd18),2'd1,6'(label_dx_54%6'd18+6'd4),6'(label_dy_54)}:40'd0;
 wire hit_55=((1'b1) && x>=770 && x<824 && y>=812 && y<830);
 // Only selected inside [770,824) x [812,830); truncated coordinates are exact there.
 wire [5:0] label_dx_55=6'(x-12'd770);
 wire [4:0] label_dy_55=5'(y-12'd812);
 wire [39:0] region_55=hit_55?{KEYSTATUS,8'd55,8'd18,6'(label_dx_55/6'd18),2'd0,6'(label_dx_55%6'd18+6'd0),6'(label_dy_55)}:40'd0;
 wire hit_56=((1'b1) && x>=71 && x<110 && y>=974 && y<992);
 // Only selected inside [71,110) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_56=6'(x-12'd71);
 wire [4:0] label_dy_56=5'(y-12'd974);
 wire [39:0] region_56=hit_56?{KEY,8'd0,8'd18,6'(label_dx_56/6'd13),2'd3,6'(label_dx_56%6'd13+6'd2),6'(label_dy_56)}:40'd0;
 wire hit_57=((1'b1) && x>=167 && x<206 && y>=974 && y<992);
 // Only selected inside [167,206) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_57=6'(x-12'd167);
 wire [4:0] label_dy_57=5'(y-12'd974);
 wire [39:0] region_57=hit_57?{KEY,8'd2,8'd18,6'(label_dx_57/6'd13),2'd3,6'(label_dx_57%6'd13+6'd2),6'(label_dy_57)}:40'd0;
 wire hit_58=((1'b1) && x>=263 && x<302 && y>=974 && y<992);
 // Only selected inside [263,302) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_58=6'(x-12'd263);
 wire [4:0] label_dy_58=5'(y-12'd974);
 wire [39:0] region_58=hit_58?{KEY,8'd4,8'd18,6'(label_dx_58/6'd13),2'd3,6'(label_dx_58%6'd13+6'd2),6'(label_dy_58)}:40'd0;
 wire hit_59=((1'b1) && x>=359 && x<398 && y>=974 && y<992);
 // Only selected inside [359,398) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_59=6'(x-12'd359);
 wire [4:0] label_dy_59=5'(y-12'd974);
 wire [39:0] region_59=hit_59?{KEY,8'd5,8'd18,6'(label_dx_59/6'd13),2'd3,6'(label_dx_59%6'd13+6'd2),6'(label_dy_59)}:40'd0;
 wire hit_60=((1'b1) && x>=455 && x<494 && y>=974 && y<992);
 // Only selected inside [455,494) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_60=6'(x-12'd455);
 wire [4:0] label_dy_60=5'(y-12'd974);
 wire [39:0] region_60=hit_60?{KEY,8'd7,8'd18,6'(label_dx_60/6'd13),2'd3,6'(label_dx_60%6'd13+6'd2),6'(label_dy_60)}:40'd0;
 wire hit_61=((1'b1) && x>=551 && x<590 && y>=974 && y<992);
 // Only selected inside [551,590) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_61=6'(x-12'd551);
 wire [4:0] label_dy_61=5'(y-12'd974);
 wire [39:0] region_61=hit_61?{KEY,8'd9,8'd18,6'(label_dx_61/6'd13),2'd3,6'(label_dx_61%6'd13+6'd2),6'(label_dy_61)}:40'd0;
 wire hit_62=((1'b1) && x>=647 && x<686 && y>=974 && y<992);
 // Only selected inside [647,686) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_62=6'(x-12'd647);
 wire [4:0] label_dy_62=5'(y-12'd974);
 wire [39:0] region_62=hit_62?{KEY,8'd11,8'd18,6'(label_dx_62/6'd13),2'd3,6'(label_dx_62%6'd13+6'd2),6'(label_dy_62)}:40'd0;
 wire hit_63=((1'b1) && x>=743 && x<782 && y>=974 && y<992);
 // Only selected inside [743,782) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_63=6'(x-12'd743);
 wire [4:0] label_dy_63=5'(y-12'd974);
 wire [39:0] region_63=hit_63?{KEY,8'd12,8'd18,6'(label_dx_63/6'd13),2'd3,6'(label_dx_63%6'd13+6'd2),6'(label_dy_63)}:40'd0;
 wire hit_64=((1'b1) && x>=839 && x<878 && y>=974 && y<992);
 // Only selected inside [839,878) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_64=6'(x-12'd839);
 wire [4:0] label_dy_64=5'(y-12'd974);
 wire [39:0] region_64=hit_64?{KEY,8'd14,8'd18,6'(label_dx_64/6'd13),2'd3,6'(label_dx_64%6'd13+6'd2),6'(label_dy_64)}:40'd0;
 wire hit_65=((1'b1) && x>=126 && x<156 && y>=921 && y<935);
 // Only selected inside [126,156) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_65=5'(x-12'd126);
 wire [3:0] label_dy_65=4'(y-12'd921);
 wire [39:0] region_65=hit_65?{KEY,8'd1,8'd14,6'(label_dx_65/6'd10),2'd0,6'(label_dx_65%6'd10+6'd2),6'(label_dy_65)}:40'd0;
 wire hit_66=((1'b1) && x>=222 && x<252 && y>=921 && y<935);
 // Only selected inside [222,252) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_66=5'(x-12'd222);
 wire [3:0] label_dy_66=4'(y-12'd921);
 wire [39:0] region_66=hit_66?{KEY,8'd3,8'd14,6'(label_dx_66/6'd10),2'd0,6'(label_dx_66%6'd10+6'd2),6'(label_dy_66)}:40'd0;
 wire hit_67=((1'b1) && x>=414 && x<444 && y>=921 && y<935);
 // Only selected inside [414,444) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_67=5'(x-12'd414);
 wire [3:0] label_dy_67=4'(y-12'd921);
 wire [39:0] region_67=hit_67?{KEY,8'd6,8'd14,6'(label_dx_67/6'd10),2'd0,6'(label_dx_67%6'd10+6'd2),6'(label_dy_67)}:40'd0;
 wire hit_68=((1'b1) && x>=510 && x<540 && y>=921 && y<935);
 // Only selected inside [510,540) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_68=5'(x-12'd510);
 wire [3:0] label_dy_68=4'(y-12'd921);
 wire [39:0] region_68=hit_68?{KEY,8'd8,8'd14,6'(label_dx_68/6'd10),2'd0,6'(label_dx_68%6'd10+6'd2),6'(label_dy_68)}:40'd0;
 wire hit_69=((1'b1) && x>=702 && x<732 && y>=921 && y<935);
 // Only selected inside [702,732) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_69=5'(x-12'd702);
 wire [3:0] label_dy_69=4'(y-12'd921);
 wire [39:0] region_69=hit_69?{KEY,8'd10,8'd14,6'(label_dx_69/6'd10),2'd0,6'(label_dx_69%6'd10+6'd2),6'(label_dy_69)}:40'd0;
 wire hit_70=((1'b1) && x>=798 && x<828 && y>=921 && y<935);
 // Only selected inside [798,828) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_70=5'(x-12'd798);
 wire [3:0] label_dy_70=4'(y-12'd921);
 wire [39:0] region_70=hit_70?{KEY,8'd13,8'd14,6'(label_dx_70/6'd10),2'd0,6'(label_dx_70%6'd10+6'd2),6'(label_dy_70)}:40'd0;
 wire hit_71=((1'b1) && x>=874 && x<898 && y>=858 && y<870);
 // Only selected inside [874,898) x [858,870); truncated coordinates are exact there.
 wire [4:0] label_dx_71=5'(x-12'd874);
 wire [3:0] label_dy_71=4'(y-12'd858);
 wire [39:0] region_71=hit_71?{KEY,8'd15,8'd12,6'(label_dx_71/6'd8),2'd0,6'(label_dx_71%6'd8+6'd2),6'(label_dy_71)}:40'd0;
 wire hit_72=((1'b1) && x>=1714 && x<1768 && y>=812 && y<830);
 // Only selected inside [1714,1768) x [812,830); truncated coordinates are exact there.
 wire [5:0] label_dx_72=6'(x-12'd1714);
 wire [4:0] label_dy_72=5'(y-12'd812);
 wire [39:0] region_72=hit_72?{KEYSTATUS,8'd72,8'd18,6'(label_dx_72/6'd18),2'd0,6'(label_dx_72%6'd18+6'd0),6'(label_dy_72)}:40'd0;
 wire hit_73=((1'b1) && x>=1015 && x<1054 && y>=974 && y<992);
 // Only selected inside [1015,1054) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_73=6'(x-12'd1015);
 wire [4:0] label_dy_73=5'(y-12'd974);
 wire [39:0] region_73=hit_73?{KEY,8'd16,8'd18,6'(label_dx_73/6'd13),2'd3,6'(label_dx_73%6'd13+6'd2),6'(label_dy_73)}:40'd0;
 wire hit_74=((1'b1) && x>=1111 && x<1150 && y>=974 && y<992);
 // Only selected inside [1111,1150) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_74=6'(x-12'd1111);
 wire [4:0] label_dy_74=5'(y-12'd974);
 wire [39:0] region_74=hit_74?{KEY,8'd18,8'd18,6'(label_dx_74/6'd13),2'd3,6'(label_dx_74%6'd13+6'd2),6'(label_dy_74)}:40'd0;
 wire hit_75=((1'b1) && x>=1207 && x<1246 && y>=974 && y<992);
 // Only selected inside [1207,1246) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_75=6'(x-12'd1207);
 wire [4:0] label_dy_75=5'(y-12'd974);
 wire [39:0] region_75=hit_75?{KEY,8'd20,8'd18,6'(label_dx_75/6'd13),2'd3,6'(label_dx_75%6'd13+6'd2),6'(label_dy_75)}:40'd0;
 wire hit_76=((1'b1) && x>=1303 && x<1342 && y>=974 && y<992);
 // Only selected inside [1303,1342) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_76=6'(x-12'd1303);
 wire [4:0] label_dy_76=5'(y-12'd974);
 wire [39:0] region_76=hit_76?{KEY,8'd21,8'd18,6'(label_dx_76/6'd13),2'd3,6'(label_dx_76%6'd13+6'd2),6'(label_dy_76)}:40'd0;
 wire hit_77=((1'b1) && x>=1399 && x<1438 && y>=974 && y<992);
 // Only selected inside [1399,1438) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_77=6'(x-12'd1399);
 wire [4:0] label_dy_77=5'(y-12'd974);
 wire [39:0] region_77=hit_77?{KEY,8'd23,8'd18,6'(label_dx_77/6'd13),2'd3,6'(label_dx_77%6'd13+6'd2),6'(label_dy_77)}:40'd0;
 wire hit_78=((1'b1) && x>=1495 && x<1534 && y>=974 && y<992);
 // Only selected inside [1495,1534) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_78=6'(x-12'd1495);
 wire [4:0] label_dy_78=5'(y-12'd974);
 wire [39:0] region_78=hit_78?{KEY,8'd25,8'd18,6'(label_dx_78/6'd13),2'd3,6'(label_dx_78%6'd13+6'd2),6'(label_dy_78)}:40'd0;
 wire hit_79=((1'b1) && x>=1591 && x<1630 && y>=974 && y<992);
 // Only selected inside [1591,1630) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_79=6'(x-12'd1591);
 wire [4:0] label_dy_79=5'(y-12'd974);
 wire [39:0] region_79=hit_79?{KEY,8'd27,8'd18,6'(label_dx_79/6'd13),2'd3,6'(label_dx_79%6'd13+6'd2),6'(label_dy_79)}:40'd0;
 wire hit_80=((1'b1) && x>=1687 && x<1726 && y>=974 && y<992);
 // Only selected inside [1687,1726) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_80=6'(x-12'd1687);
 wire [4:0] label_dy_80=5'(y-12'd974);
 wire [39:0] region_80=hit_80?{KEY,8'd28,8'd18,6'(label_dx_80/6'd13),2'd3,6'(label_dx_80%6'd13+6'd2),6'(label_dy_80)}:40'd0;
 wire hit_81=((1'b1) && x>=1783 && x<1822 && y>=974 && y<992);
 // Only selected inside [1783,1822) x [974,992); truncated coordinates are exact there.
 wire [5:0] label_dx_81=6'(x-12'd1783);
 wire [4:0] label_dy_81=5'(y-12'd974);
 wire [39:0] region_81=hit_81?{KEY,8'd30,8'd18,6'(label_dx_81/6'd13),2'd3,6'(label_dx_81%6'd13+6'd2),6'(label_dy_81)}:40'd0;
 wire hit_82=((1'b1) && x>=1070 && x<1100 && y>=921 && y<935);
 // Only selected inside [1070,1100) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_82=5'(x-12'd1070);
 wire [3:0] label_dy_82=4'(y-12'd921);
 wire [39:0] region_82=hit_82?{KEY,8'd17,8'd14,6'(label_dx_82/6'd10),2'd0,6'(label_dx_82%6'd10+6'd2),6'(label_dy_82)}:40'd0;
 wire hit_83=((1'b1) && x>=1166 && x<1196 && y>=921 && y<935);
 // Only selected inside [1166,1196) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_83=5'(x-12'd1166);
 wire [3:0] label_dy_83=4'(y-12'd921);
 wire [39:0] region_83=hit_83?{KEY,8'd19,8'd14,6'(label_dx_83/6'd10),2'd0,6'(label_dx_83%6'd10+6'd2),6'(label_dy_83)}:40'd0;
 wire hit_84=((1'b1) && x>=1358 && x<1388 && y>=921 && y<935);
 // Only selected inside [1358,1388) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_84=5'(x-12'd1358);
 wire [3:0] label_dy_84=4'(y-12'd921);
 wire [39:0] region_84=hit_84?{KEY,8'd22,8'd14,6'(label_dx_84/6'd10),2'd0,6'(label_dx_84%6'd10+6'd2),6'(label_dy_84)}:40'd0;
 wire hit_85=((1'b1) && x>=1454 && x<1484 && y>=921 && y<935);
 // Only selected inside [1454,1484) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_85=5'(x-12'd1454);
 wire [3:0] label_dy_85=4'(y-12'd921);
 wire [39:0] region_85=hit_85?{KEY,8'd24,8'd14,6'(label_dx_85/6'd10),2'd0,6'(label_dx_85%6'd10+6'd2),6'(label_dy_85)}:40'd0;
 wire hit_86=((1'b1) && x>=1646 && x<1676 && y>=921 && y<935);
 // Only selected inside [1646,1676) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_86=5'(x-12'd1646);
 wire [3:0] label_dy_86=4'(y-12'd921);
 wire [39:0] region_86=hit_86?{KEY,8'd26,8'd14,6'(label_dx_86/6'd10),2'd0,6'(label_dx_86%6'd10+6'd2),6'(label_dy_86)}:40'd0;
 wire hit_87=((1'b1) && x>=1742 && x<1772 && y>=921 && y<935);
 // Only selected inside [1742,1772) x [921,935); truncated coordinates are exact there.
 wire [4:0] label_dx_87=5'(x-12'd1742);
 wire [3:0] label_dy_87=4'(y-12'd921);
 wire [39:0] region_87=hit_87?{KEY,8'd29,8'd14,6'(label_dx_87/6'd10),2'd0,6'(label_dx_87%6'd10+6'd2),6'(label_dy_87)}:40'd0;
 wire hit_88=((1'b1) && x>=1818 && x<1842 && y>=858 && y<870);
 // Only selected inside [1818,1842) x [858,870); truncated coordinates are exact there.
 wire [4:0] label_dx_88=5'(x-12'd1818);
 wire [3:0] label_dy_88=4'(y-12'd858);
 wire [39:0] region_88=hit_88?{KEY,8'd31,8'd12,6'(label_dx_88/6'd8),2'd0,6'(label_dx_88%6'd8+6'd2),6'(label_dy_88)}:40'd0;
 wire hit_89=(!env_valid && (1'b1) && x>=926 && x<986 && y>=330 && y<350);
 // Only selected inside [926,986) x [330,350); truncated coordinates are exact there.
 wire [5:0] label_dx_89=6'(x-12'd926);
 wire [4:0] label_dy_89=5'(y-12'd330);
 wire [39:0] region_89=hit_89?{STATIC,8'd89,8'd20,6'(label_dx_89/6'd20),2'd0,6'(label_dx_89%6'd20+6'd0),6'(label_dy_89)}:40'd0;
 wire [39:0] attributes_comb=(((((((region_q[0] | region_q[1]) | (region_q[2] | region_q[3])) | ((region_q[4] | region_q[5]) | (region_q[6] | region_q[7]))) | (((region_q[8] | region_q[9]) | (region_q[10] | region_q[11])) | ((region_q[12] | region_q[13]) | (region_q[14] | region_q[15])))) | ((((region_q[16] | region_q[17]) | (region_q[18] | region_q[19])) | ((region_q[20] | region_q[21]) | (region_q[22] | region_q[23]))) | (((region_q[24] | region_q[25]) | (region_q[26] | region_q[27])) | ((region_q[28] | region_q[29]) | (region_q[30] | region_q[31]))))) | (((((region_q[32] | region_q[33]) | (region_q[34] | region_q[35])) | ((region_q[36] | region_q[37]) | (region_q[38] | region_q[39]))) | (((region_q[40] | region_q[41]) | (region_q[42] | region_q[43])) | ((region_q[44] | region_q[45]) | (region_q[46] | region_q[47])))) | ((((region_q[48] | region_q[49]) | (region_q[50] | region_q[51])) | ((region_q[52] | region_q[53]) | (region_q[54] | region_q[55]))) | (((region_q[56] | region_q[57]) | (region_q[58] | region_q[59])) | ((region_q[60] | region_q[61]) | (region_q[62] | region_q[63])))))) | (((((region_q[64] | region_q[65]) | (region_q[66] | region_q[67])) | ((region_q[68] | region_q[69]) | (region_q[70] | region_q[71]))) | (((region_q[72] | region_q[73]) | (region_q[74] | region_q[75])) | ((region_q[76] | region_q[77]) | (region_q[78] | region_q[79])))) | ((((region_q[80] | region_q[81]) | (region_q[82] | region_q[83])) | ((region_q[84] | region_q[85]) | (region_q[86] | region_q[87]))) | (region_q[88] | region_q[89]))));
 assign {kind,argument,font_size,pos,tone,col,row}=attr_char;
 reg [39:0] region_q[0:89],attr_pipe[0:14];reg [39:0] attr_char,attr_glyph;
 integer stage_i;
 always @(posedge clk)begin
  region_q[0]<=region_0;
  region_q[1]<=region_1;
  region_q[2]<=region_2;
  region_q[3]<=region_3;
  region_q[4]<=region_4;
  region_q[5]<=region_5;
  region_q[6]<=region_6;
  region_q[7]<=region_7;
  region_q[8]<=region_8;
  region_q[9]<=region_9;
  region_q[10]<=region_10;
  region_q[11]<=region_11;
  region_q[12]<=region_12;
  region_q[13]<=region_13;
  region_q[14]<=region_14;
  region_q[15]<=region_15;
  region_q[16]<=region_16;
  region_q[17]<=region_17;
  region_q[18]<=region_18;
  region_q[19]<=region_19;
  region_q[20]<=region_20;
  region_q[21]<=region_21;
  region_q[22]<=region_22;
  region_q[23]<=region_23;
  region_q[24]<=region_24;
  region_q[25]<=region_25;
  region_q[26]<=region_26;
  region_q[27]<=region_27;
  region_q[28]<=region_28;
  region_q[29]<=region_29;
  region_q[30]<=region_30;
  region_q[31]<=region_31;
  region_q[32]<=region_32;
  region_q[33]<=region_33;
  region_q[34]<=region_34;
  region_q[35]<=region_35;
  region_q[36]<=region_36;
  region_q[37]<=region_37;
  region_q[38]<=region_38;
  region_q[39]<=region_39;
  region_q[40]<=region_40;
  region_q[41]<=region_41;
  region_q[42]<=region_42;
  region_q[43]<=region_43;
  region_q[44]<=region_44;
  region_q[45]<=region_45;
  region_q[46]<=region_46;
  region_q[47]<=region_47;
  region_q[48]<=region_48;
  region_q[49]<=region_49;
  region_q[50]<=region_50;
  region_q[51]<=region_51;
  region_q[52]<=region_52;
  region_q[53]<=region_53;
  region_q[54]<=region_54;
  region_q[55]<=region_55;
  region_q[56]<=region_56;
  region_q[57]<=region_57;
  region_q[58]<=region_58;
  region_q[59]<=region_59;
  region_q[60]<=region_60;
  region_q[61]<=region_61;
  region_q[62]<=region_62;
  region_q[63]<=region_63;
  region_q[64]<=region_64;
  region_q[65]<=region_65;
  region_q[66]<=region_66;
  region_q[67]<=region_67;
  region_q[68]<=region_68;
  region_q[69]<=region_69;
  region_q[70]<=region_70;
  region_q[71]<=region_71;
  region_q[72]<=region_72;
  region_q[73]<=region_73;
  region_q[74]<=region_74;
  region_q[75]<=region_75;
  region_q[76]<=region_76;
  region_q[77]<=region_77;
  region_q[78]<=region_78;
  region_q[79]<=region_79;
  region_q[80]<=region_80;
  region_q[81]<=region_81;
  region_q[82]<=region_82;
  region_q[83]<=region_83;
  region_q[84]<=region_84;
  region_q[85]<=region_85;
  region_q[86]<=region_86;
  region_q[87]<=region_87;
  region_q[88]<=region_88;
  region_q[89]<=region_89;

  attr_pipe[0]<=attributes_comb;
  for(stage_i=1;stage_i<15;stage_i=stage_i+1)attr_pipe[stage_i]<=attr_pipe[stage_i-1];
  attr_char<=attr_pipe[14];attr_glyph<=attr_char;
 end


 always @* begin
  numeric_value=0;numeric_place=0;
  case(kind)
   VOICES:begin numeric_value={26'd0,c_voice_count};numeric_place=pos==0?1:0;end
   VOICEID:begin numeric_value={27'd0,char_status[450+:5]}+1;numeric_place=pos==0?1:0;end
   SAMPLE:begin numeric_value=SAMPLE_RATE/1000;numeric_place=pos==0?1:0;end
   AXIS:begin numeric_value=axis_frequency(32'(argument));numeric_place=pos<5?4-32'(pos):0;end
   PEAK:begin numeric_value={16'd0,char_hz};numeric_place=pos<5?4-32'(pos):0;end
   default:begin end
  endcase
 end

 localparam LABEL_LATENCY=22;
 function automatic [35:0] bcd_step(input [35:0] v);
 reg [19:0] n;integer d;begin n=v[19:0];
 for(d=0;d<5;d=d+1)if(n[d*4+:4]>=5)n[d*4+:4]=n[d*4+:4]+4'd3;
 bcd_step={v[34:20],1'b0,n[18:0],v[35]};end endfunction
 function automatic [19:0] const_bcd(input integer v);
 integer d,n;begin n=v;for(d=0;d<5;d=d+1)begin const_bcd[d*4+:4]=4'(n%10);n=n/10;end end endfunction
 function automatic [7:0] two_digits(input [5:0] v);
 begin two_digits={4'(v/6'd10),4'(v%6'd10)};end endfunction
 function automatic [6:0] pick_key_note(input [511:0] snapshot,input [4:0] key);
 begin case(key)
 5'd0:pick_key_note=snapshot[82+:7];
 5'd1:pick_key_note=snapshot[89+:7];
 5'd2:pick_key_note=snapshot[96+:7];
 5'd3:pick_key_note=snapshot[103+:7];
 5'd4:pick_key_note=snapshot[110+:7];
 5'd5:pick_key_note=snapshot[117+:7];
 5'd6:pick_key_note=snapshot[124+:7];
 5'd7:pick_key_note=snapshot[131+:7];
 5'd8:pick_key_note=snapshot[138+:7];
 5'd9:pick_key_note=snapshot[145+:7];
 5'd10:pick_key_note=snapshot[152+:7];
 5'd11:pick_key_note=snapshot[159+:7];
 5'd12:pick_key_note=snapshot[166+:7];
 5'd13:pick_key_note=snapshot[173+:7];
 5'd14:pick_key_note=snapshot[180+:7];
 5'd15:pick_key_note=snapshot[187+:7];
 5'd16:pick_key_note=snapshot[194+:7];
 5'd17:pick_key_note=snapshot[201+:7];
 5'd18:pick_key_note=snapshot[208+:7];
 5'd19:pick_key_note=snapshot[215+:7];
 5'd20:pick_key_note=snapshot[222+:7];
 5'd21:pick_key_note=snapshot[229+:7];
 5'd22:pick_key_note=snapshot[236+:7];
 5'd23:pick_key_note=snapshot[243+:7];
 5'd24:pick_key_note=snapshot[250+:7];
 5'd25:pick_key_note=snapshot[257+:7];
 5'd26:pick_key_note=snapshot[264+:7];
 5'd27:pick_key_note=snapshot[271+:7];
 5'd28:pick_key_note=snapshot[278+:7];
 5'd29:pick_key_note=snapshot[285+:7];
 5'd30:pick_key_note=snapshot[292+:7];
 5'd31:pick_key_note=snapshot[299+:7];
 endcase end endfunction
 // Select the current label's note after region/attribute registration.
 // Keep the original capture at stage16; only unused mapping metadata is dropped.
 reg [6:0] char_key_note,key_note_pipe[0:13];integer note_stage;
 always @(posedge clk)begin
  key_note_pipe[0]<=pick_key_note(status_pipe[1],attr_pipe[0][32:28]);
  for(note_stage=1;note_stage<14;note_stage=note_stage+1)
   key_note_pipe[note_stage]<=key_note_pipe[note_stage-1];
 end
 // Double-dabble stages stay in flip-flops: as distributed-RAM shift chains
 // their first write-data pin failed hold against the status registers.
 (* syn_srlstyle="registers" *) reg [35:0] peak_bcd_pipe[0:15];
 (* syn_srlstyle="registers" *) reg [35:0] completed_bcd_pipe[0:15];
 reg [511:0] status_pipe[0:15],char_status;
 // First status stage in preserved flip-flops of its own: merged with the
 // scene's identical pipeline registers, the distributed-RAM delay chain
 // took its write data from high-fanout scene registers and failed DI hold.
 (* syn_preserve=1,syn_srlstyle="registers" *) reg [511:0] status_first;
 // guide_state (status bits 490..492) follows status_pipe in flip-flops.
 (* syn_srlstyle="registers" *) reg [2:0] guide_pipe[1:15];
 wire [511:0] status_tail={status_pipe[15][511:493],guide_pipe[15],status_pipe[15][489:0]};
 reg [28:0] control_pipe[0:15],char_control;
 reg [19:0] char_peak_bcd,char_completed_bcd;
 reg [5:0] c_voice_count,c_target_count,c_pressed_count,c_wrong_count;
 wire char_live,char_peak_valid,char_direct,char_signal,char_mixed;
 wire [15:0] char_hz;wire signed [5:0] char_shift;wire [1:0] char_range;
 assign {char_live,char_peak_valid,char_hz,char_direct,char_signal,char_mixed,char_shift,char_range}=char_control;
 wire c_note_valid=char_live && char_status[3] && char_status[11+:7]>=36 && char_status[11+:7]<=96;
 wire c_voices_valid=char_live && char_status[4];
 wire c_env_valid=char_live && char_status[5];
 wire c_keys_valid=char_live && char_status[0];
 wire c_mapping_valid=char_live && char_status[1];
 wire c_mode_valid=char_live && char_status[455] && char_status[456+:2]!=3;
 wire [1:0] c_mode=char_status[456+:2];wire [2:0] c_guide_state=char_status[490+:3];
 wire [511:0] count_status=status_tail;wire [28:0] count_control=control_pipe[15];
 wire count_keys_valid=count_control[28] && count_status[0];
 wire count_guide_valid=count_control[28] && count_status[455] && count_status[456+:2]==2;
 wire count_target_valid=count_guide_valid && count_keys_valid && (count_status[490+:3]==2 || count_status[490+:3]==3);
 wire [31:0] count_actual=count_keys_valid?count_status[18+:32]:32'd0;
 wire [31:0] count_targets=count_target_valid?count_status[458+:32]:32'd0;
 integer meta_i;
 always @(posedge clk)begin
  peak_bcd_pipe[0]<=bcd_step({peak_hz,20'd0});
  completed_bcd_pipe[0]<=bcd_step({status_data[493+:16],20'd0});
  status_first<=status_data;
  control_pipe[0]<={status_live,peak_valid,peak_hz,xy_direct,xy_signal,xy_mixed,xy_shift,spectrum_range};
  for(meta_i=1;meta_i<16;meta_i=meta_i+1)begin
   peak_bcd_pipe[meta_i]<=bcd_step(peak_bcd_pipe[meta_i-1]);
   completed_bcd_pipe[meta_i]<=bcd_step(completed_bcd_pipe[meta_i-1]);
   guide_pipe[meta_i]<=meta_i<2?status_first[490+:3]:guide_pipe[meta_i-1];
   if(meta_i<2)status_pipe[meta_i]<=status_first;
   else status_pipe[meta_i]<={status_pipe[meta_i-1][511:306],224'b0,status_pipe[meta_i-1][81:0]};
   control_pipe[meta_i]<=control_pipe[meta_i-1];
  end
  char_status<=status_tail;char_control<=control_pipe[15];
  char_key_note<=key_note_pipe[13];
  char_peak_bcd<=peak_bcd_pipe[15][19:0];char_completed_bcd<=completed_bcd_pipe[15][19:0];
  c_voice_count<=count_voices(count_status[50+:32]);
  c_target_count<=count_voices(count_targets & ~count_actual);
  c_pressed_count<=count_voices(count_actual);
  c_wrong_count<=count_voices(count_target_valid?(count_actual & ~count_targets):32'd0);
 end
 function automatic [19:0] axis_bcd(input [1:0] range_sel,input [7:0] tick);
 begin case({range_sel,tick})
 10'd0:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd1*64'd0)/48);
 10'd1:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd1*64'd1)/48);
 10'd2:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd1*64'd2)/48);
 10'd3:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd1*64'd3)/48);
 10'd4:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd1*64'd4)/48);
 10'd5:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd1*64'd5)/48);
 10'd6:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd1*64'd6)/48);
 10'd256:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd2*64'd0)/48);
 10'd257:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd2*64'd1)/48);
 10'd258:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd2*64'd2)/48);
 10'd259:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd2*64'd3)/48);
 10'd260:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd2*64'd4)/48);
 10'd261:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd2*64'd5)/48);
 10'd262:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd2*64'd6)/48);
 10'd512:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd3*64'd0)/48);
 10'd513:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd3*64'd1)/48);
 10'd514:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd3*64'd2)/48);
 10'd515:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd3*64'd3)/48);
 10'd516:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd3*64'd4)/48);
 10'd517:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd3*64'd5)/48);
 10'd518:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd3*64'd6)/48);
 10'd768:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd4*64'd0)/48);
 10'd769:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd4*64'd1)/48);
 10'd770:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd4*64'd2)/48);
 10'd771:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd4*64'd3)/48);
 10'd772:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd4*64'd4)/48);
 10'd773:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd4*64'd5)/48);
 10'd774:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd4*64'd6)/48);
 default:axis_bcd=0;endcase end endfunction
 // Axis arguments and range are ready at the existing char-status edge.
 // Register their BCD before the shared digit selector, retaining21 clocks.
 reg [15:0] completed_character_q[0:4];
 // Trim and ASCII conversion share the existing char-status capture edge.
 always @(posedge clk)begin
  completed_character_q[0]<=16'd48+16'(completed_bcd_pipe[15][0+:4]);
  completed_character_q[1]<=(status_pipe[15][493+:16] < 16'd10 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][4+:4]));
  completed_character_q[2]<=(status_pipe[15][493+:16] < 16'd100 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][8+:4]));
  completed_character_q[3]<=(status_pipe[15][493+:16] < 16'd1000 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][12+:4]));
  completed_character_q[4]<=(status_pipe[15][493+:16] < 16'd10000 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][16+:4]));
 end
 reg [19:0] axis_bcd_q;
 always @(posedge clk)axis_bcd_q<=axis_bcd(control_pipe[15][1:0],attr_pipe[14][35:28]);
 reg [19:0] numeric_bcd;
 always @* begin
  numeric_bcd=0;
  case(kind)
   VOICES:numeric_bcd={12'd0,two_digits(c_voice_count)};
   VOICEID:numeric_bcd={12'd0,two_digits({1'b0,char_status[450+:5]}+6'd1)};
   SAMPLE:numeric_bcd=const_bcd(SAMPLE_RATE/1000);
   AXIS:numeric_bcd=axis_bcd_q;
   PEAK:numeric_bcd=char_peak_bcd;
   default:begin end
  endcase
 end
 function automatic [3:0] selected_bcd_digit(input [19:0] value,input [2:0] place);
 begin case(place)
  0:selected_bcd_digit=value[3:0];1:selected_bcd_digit=value[7:4];
  2:selected_bcd_digit=value[11:8];3:selected_bcd_digit=value[15:12];
  4:selected_bcd_digit=value[19:16];default:selected_bcd_digit=0;
 endcase end endfunction
 function automatic bcd_digit_visible(input [19:0] value,input [2:0] place);
 begin case(place)
  1:bcd_digit_visible=|value[19:4];2:bcd_digit_visible=|value[19:8];
  3:bcd_digit_visible=|value[19:12];4:bcd_digit_visible=|value[19:16];
  default:bcd_digit_visible=1;
 endcase end endfunction
 wire [15:0] digit_value={12'd3,selected_bcd_digit(numeric_bcd,numeric_place)};
 wire [15:0] trimmed_value=bcd_digit_visible(numeric_bcd,numeric_place)?digit_value:16'd32;

 always_comb begin
  ch_next=16'd32;
  case(kind)
   STATIC:ch_next=static_char({argument,pos},c_mode_valid,c_mode,c_guide_state,c_keys_valid,c_target_count,c_pressed_count,c_wrong_count,char_status[493+:16],char_completed_bcd);
   KEY:ch_next=key_char(32'(argument),32'(pos));
   TIMBRE:ch_next=timbre_char(32'(pos));
   NOTE:ch_next=c_note_valid?note_char(char_status[11+:7],32'(pos)):(pos==0?16'd45:16'd32);
   XY:ch_next=xy_char(32'(pos));
   KEYSTATUS:if(!c_keys_valid)case(pos)0:ch_next=16'h672a;1:ch_next=16'h63a5;2:ch_next=16'h5165;default:ch_next=32;endcase
   VOICES:begin
    if(pos<2)ch_next=c_voices_valid?digit_value:(pos==0?16'd45:16'd32);
    else case(pos)3:ch_next=47;5:ch_next=51;6:ch_next=50;default:ch_next=32;endcase
   end
   VOICEID:if(pos<2)ch_next=c_env_valid?digit_value:(pos==0?16'd45:16'd32);
   SAMPLE:if(pos<2)ch_next=digit_value;else case(pos)3:ch_next=107;4:ch_next=72;5:ch_next=122;default:ch_next=32;endcase
   AXIS:if(pos<5)ch_next=trimmed_value;else case(pos)6:ch_next=72;7:ch_next=122;default:ch_next=32;endcase
   PEAK:if(pos<5)ch_next=char_peak_valid?trimmed_value:(pos==0?16'd45:16'd32);else case(pos)6:ch_next=72;7:ch_next=122;default:ch_next=32;endcase
   default:begin end
  endcase
 end
 always @(posedge clk)begin coverage<=visible_addr?font_rom[font_addr_q]:2'd0;color<=color_addr;end
 always @* ink=|coverage;
 wire unused_labels=^{xy_shift};
endmodule
`default_nettype wire

`default_nettype none
// The sparse ROM registers an8-bit index; a small dense descriptor supplies
// the exact key/base, registered once more together with the full 24-bit key
// comparison that rejects all unsupported characters.
module pre_visual_glyph_index(input wire clk,input wire[7:0] font_size,input wire[15:0] character,
 output wire[16:0] base,output wire found);
 localparam HASH_BITS=12,WORDS=4096;
 wire[23:0] key={font_size,character};
 wire[HASH_BITS-1:0] address;
 (* syn_keep=1 *) wire[HASH_BITS*6-1:0] parity_group;
 assign parity_group[0]=^(key[0+:4] & 4'hb);
 assign parity_group[1]=^(key[4+:4] & 4'hd);
 assign parity_group[2]=^(key[8+:4] & 4'h5);
 assign parity_group[3]=^(key[12+:4] & 4'h7);
 assign parity_group[4]=^(key[16+:4] & 4'ha);
 assign parity_group[5]=^(key[20+:4] & 4'hb);
 assign address[0]=^parity_group[0+:6];
 assign parity_group[6]=^(key[0+:4] & 4'h2);
 assign parity_group[7]=^(key[4+:4] & 4'h1);
 assign parity_group[8]=^(key[8+:4] & 4'h8);
 assign parity_group[9]=^(key[12+:4] & 4'ha);
 assign parity_group[10]=^(key[16+:4] & 4'h8);
 assign parity_group[11]=^(key[20+:4] & 4'h5);
 assign address[1]=^parity_group[6+:6];
 assign parity_group[12]=^(key[0+:4] & 4'h3);
 assign parity_group[13]=^(key[4+:4] & 4'h0);
 assign parity_group[14]=^(key[8+:4] & 4'h0);
 assign parity_group[15]=^(key[12+:4] & 4'hb);
 assign parity_group[16]=^(key[16+:4] & 4'h3);
 assign parity_group[17]=^(key[20+:4] & 4'ha);
 assign address[2]=^parity_group[12+:6];
 assign parity_group[18]=^(key[0+:4] & 4'hf);
 assign parity_group[19]=^(key[4+:4] & 4'he);
 assign parity_group[20]=^(key[8+:4] & 4'h3);
 assign parity_group[21]=^(key[12+:4] & 4'hf);
 assign parity_group[22]=^(key[16+:4] & 4'ha);
 assign parity_group[23]=^(key[20+:4] & 4'hf);
 assign address[3]=^parity_group[18+:6];
 assign parity_group[24]=^(key[0+:4] & 4'hb);
 assign parity_group[25]=^(key[4+:4] & 4'h7);
 assign parity_group[26]=^(key[8+:4] & 4'ha);
 assign parity_group[27]=^(key[12+:4] & 4'h8);
 assign parity_group[28]=^(key[16+:4] & 4'hd);
 assign parity_group[29]=^(key[20+:4] & 4'ha);
 assign address[4]=^parity_group[24+:6];
 assign parity_group[30]=^(key[0+:4] & 4'ha);
 assign parity_group[31]=^(key[4+:4] & 4'h0);
 assign parity_group[32]=^(key[8+:4] & 4'he);
 assign parity_group[33]=^(key[12+:4] & 4'he);
 assign parity_group[34]=^(key[16+:4] & 4'h6);
 assign parity_group[35]=^(key[20+:4] & 4'he);
 assign address[5]=^parity_group[30+:6];
 assign parity_group[36]=^(key[0+:4] & 4'he);
 assign parity_group[37]=^(key[4+:4] & 4'h8);
 assign parity_group[38]=^(key[8+:4] & 4'h2);
 assign parity_group[39]=^(key[12+:4] & 4'h1);
 assign parity_group[40]=^(key[16+:4] & 4'h6);
 assign parity_group[41]=^(key[20+:4] & 4'h6);
 assign address[6]=^parity_group[36+:6];
 assign parity_group[42]=^(key[0+:4] & 4'h2);
 assign parity_group[43]=^(key[4+:4] & 4'h8);
 assign parity_group[44]=^(key[8+:4] & 4'h9);
 assign parity_group[45]=^(key[12+:4] & 4'hb);
 assign parity_group[46]=^(key[16+:4] & 4'h4);
 assign parity_group[47]=^(key[20+:4] & 4'h3);
 assign address[7]=^parity_group[42+:6];
 assign parity_group[48]=^(key[0+:4] & 4'he);
 assign parity_group[49]=^(key[4+:4] & 4'h9);
 assign parity_group[50]=^(key[8+:4] & 4'h8);
 assign parity_group[51]=^(key[12+:4] & 4'ha);
 assign parity_group[52]=^(key[16+:4] & 4'h7);
 assign parity_group[53]=^(key[20+:4] & 4'hb);
 assign address[8]=^parity_group[48+:6];
 assign parity_group[54]=^(key[0+:4] & 4'h9);
 assign parity_group[55]=^(key[4+:4] & 4'he);
 assign parity_group[56]=^(key[8+:4] & 4'hb);
 assign parity_group[57]=^(key[12+:4] & 4'hc);
 assign parity_group[58]=^(key[16+:4] & 4'h2);
 assign parity_group[59]=^(key[20+:4] & 4'he);
 assign address[9]=^parity_group[54+:6];
 assign parity_group[60]=^(key[0+:4] & 4'h6);
 assign parity_group[61]=^(key[4+:4] & 4'hf);
 assign parity_group[62]=^(key[8+:4] & 4'h3);
 assign parity_group[63]=^(key[12+:4] & 4'h0);
 assign parity_group[64]=^(key[16+:4] & 4'h7);
 assign parity_group[65]=^(key[20+:4] & 4'h0);
 assign address[10]=^parity_group[60+:6];
 assign parity_group[66]=^(key[0+:4] & 4'h7);
 assign parity_group[67]=^(key[4+:4] & 4'h3);
 assign parity_group[68]=^(key[8+:4] & 4'h3);
 assign parity_group[69]=^(key[12+:4] & 4'hd);
 assign parity_group[70]=^(key[16+:4] & 4'h5);
 assign parity_group[71]=^(key[20+:4] & 4'h4);
 assign address[11]=^parity_group[66+:6];
 (* syn_romstyle="block_rom" *) reg[7:0] sparse_index[0:WORDS-1];
 (* syn_romstyle="logic" *) reg[40:0] descriptors[0:255];
 reg[7:0] index_q;reg[23:0] key_q;
 wire[40:0] descriptor=descriptors[index_q];
 initial begin
  $readmemh("assets/display_glyph_index.hex",sparse_index);
  $readmemh("assets/display_glyph_descriptors.hex",descriptors);
 end
 reg[16:0] base_q;reg found_q;
 always @(posedge clk)begin
  index_q<=sparse_index[address];key_q<=key;
  // One extra clock between the descriptor lookup and the font-ROM adder.
  base_q<=descriptor[16:0];found_q<=index_q!=0 && descriptor[40:17]==key_q;
 end
 assign base=base_q;
 assign found=found_q;
endmodule
`default_nettype wire
