`default_nettype none
(* syn_srlstyle="distributed_ram" *)
module visual_labels #(parameter SAMPLE_RATE=48000)(
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
 visual_glyph_index glyph_index(clk,attr_glyph[27:20],ch,base_q,font_found);
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


 // Per-line label region engine (tools/labels_line_engine_20261024.py).
 // Regions crossing a line come from ln_region_rom in x order; only the current
 // and the next region are followed, and the glyph column/position are counted
 // instead of divided. ln_line_list gives the first entry of the line's list.
 localparam integer ln_RAW=8;
 wire [ln_RAW-1:0] ln_line_list=(y<12'd435 ? (y<12'd209 ? (y<12'd101 ? (y<12'd59 ? (y<12'd39 ? 8'd0 : (y<12'd47 ? 8'd1 : 8'd7)) : (y<12'd73 ? 8'd14 : (y<12'd89 ? 8'd16 : 8'd23))) : (y<12'd149 ? (y<12'd139 ? 8'd0 : (y<12'd147 ? 8'd29 : 8'd34)) : (y<12'd195 ? (y<12'd167 ? 8'd40 : 8'd0) : (y<12'd206 ? 8'd49 : 8'd51)))) : (y<12'd322 ? (y<12'd225 ? (y<12'd213 ? 8'd54 : (y<12'd222 ? 8'd58 : 8'd61)) : (y<12'd306 ? 8'd0 : (y<12'd313 ? 8'd63 : 8'd65))) : (y<12'd350 ? (y<12'd329 ? 8'd68 : (y<12'd330 ? 8'd0 : 8'd70)) : (y<12'd422 ? (y<12'd415 ? 8'd0 : 8'd72) : (y<12'd431 ? 8'd74 : 8'd77))))) : (y<12'd754 ? (y<12'd537 ? (y<12'd509 ? (y<12'd438 ? 8'd79 : (y<12'd449 ? 8'd82 : 8'd0)) : (y<12'd515 ? 8'd84 : (y<12'd535 ? 8'd88 : 8'd84))) : (y<12'd598 ? (y<12'd556 ? 8'd0 : (y<12'd572 ? 8'd94 : 8'd0)) : (y<12'd674 ? (y<12'd612 ? 8'd102 : 8'd0) : (y<12'd688 ? 8'd104 : 8'd0)))) : (y<12'd830 ? (y<12'd774 ? (y<12'd755 ? 8'd106 : (y<12'd773 ? 8'd111 : 8'd106)) : (y<12'd804 ? 8'd0 : (y<12'd812 ? 8'd122 : 8'd127))) : (y<12'd921 ? (y<12'd858 ? 8'd0 : (y<12'd870 ? 8'd134 : 8'd0)) : (y<12'd974 ? (y<12'd935 ? 8'd137 : 8'd0) : (y<12'd992 ? 8'd150 : 8'd0))))));
 // Entry: valid, x0, x1, y0, kind, argument, size, ln_wrap column, tone, column offset, condition.
 reg [70:0] ln_region_rom;reg [ln_RAW-1:0] ln_fetch_addr;
 always @(posedge clk)case(ln_fetch_addr)
   8'd1:ln_region_rom<={1'b1,11'd466,11'd506,12'd39,STATIC,8'd1,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd2:ln_region_rom<={1'b1,11'd746,11'd786,12'd39,STATIC,8'd3,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd3:ln_region_rom<={1'b1,11'd986,11'd1026,12'd39,STATIC,8'd5,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd4:ln_region_rom<={1'b1,11'd1236,11'd1316,12'd39,STATIC,8'd7,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd5:ln_region_rom<={1'b1,11'd1546,11'd1606,12'd39,STATIC,8'd9,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd7:ln_region_rom<={1'b1,11'd146,11'd314,12'd47,STATIC,8'd0,8'd42,6'd41,2'd1,6'd0,2'd0};
   8'd8:ln_region_rom<={1'b1,11'd466,11'd506,12'd39,STATIC,8'd1,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd9:ln_region_rom<={1'b1,11'd746,11'd786,12'd39,STATIC,8'd3,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd10:ln_region_rom<={1'b1,11'd986,11'd1026,12'd39,STATIC,8'd5,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd11:ln_region_rom<={1'b1,11'd1236,11'd1316,12'd39,STATIC,8'd7,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd12:ln_region_rom<={1'b1,11'd1546,11'd1606,12'd39,STATIC,8'd9,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd14:ln_region_rom<={1'b1,11'd146,11'd314,12'd47,STATIC,8'd0,8'd42,6'd41,2'd1,6'd0,2'd0};
   8'd16:ln_region_rom<={1'b1,11'd146,11'd314,12'd47,STATIC,8'd0,8'd42,6'd41,2'd1,6'd0,2'd0};
   8'd17:ln_region_rom<={1'b1,11'd466,11'd578,12'd73,STATIC,8'd2,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd18:ln_region_rom<={1'b1,11'd746,11'd830,12'd73,TIMBRE,8'd4,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd19:ln_region_rom<={1'b1,11'd986,11'd1046,12'd73,NOTE,8'd6,8'd28,6'd23,2'd2,6'd4,2'd0};
   8'd20:ln_region_rom<={1'b1,11'd1236,11'd1376,12'd73,VOICES,8'd8,8'd28,6'd23,2'd2,6'd4,2'd0};
   8'd21:ln_region_rom<={1'b1,11'd1546,11'd1666,12'd73,SAMPLE,8'd10,8'd28,6'd23,2'd1,6'd4,2'd0};
   8'd23:ln_region_rom<={1'b1,11'd466,11'd578,12'd73,STATIC,8'd2,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd24:ln_region_rom<={1'b1,11'd746,11'd830,12'd73,TIMBRE,8'd4,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd25:ln_region_rom<={1'b1,11'd986,11'd1046,12'd73,NOTE,8'd6,8'd28,6'd23,2'd2,6'd4,2'd0};
   8'd26:ln_region_rom<={1'b1,11'd1236,11'd1376,12'd73,VOICES,8'd8,8'd28,6'd23,2'd2,6'd4,2'd0};
   8'd27:ln_region_rom<={1'b1,11'd1546,11'd1666,12'd73,SAMPLE,8'd10,8'd28,6'd23,2'd1,6'd4,2'd0};
   8'd29:ln_region_rom<={1'b1,11'd52,11'd108,12'd139,STATIC,8'd11,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd30:ln_region_rom<={1'b1,11'd792,11'd892,12'd139,STATIC,8'd13,8'd28,6'd23,2'd1,6'd4,2'd0};
   8'd31:ln_region_rom<={1'b1,11'd892,11'd948,12'd139,STATIC,8'd14,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd32:ln_region_rom<={1'b1,11'd1534,11'd1646,12'd139,STATIC,8'd19,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd34:ln_region_rom<={1'b1,11'd52,11'd108,12'd139,STATIC,8'd11,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd35:ln_region_rom<={1'b1,11'd530,11'd642,12'd147,STATIC,8'd12,8'd20,6'd16,2'd0,6'd3,2'd0};
   8'd36:ln_region_rom<={1'b1,11'd792,11'd892,12'd139,STATIC,8'd13,8'd28,6'd23,2'd1,6'd4,2'd0};
   8'd37:ln_region_rom<={1'b1,11'd892,11'd948,12'd139,STATIC,8'd14,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd38:ln_region_rom<={1'b1,11'd1534,11'd1646,12'd139,STATIC,8'd19,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd40:ln_region_rom<={1'b1,11'd52,11'd108,12'd139,STATIC,8'd11,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd41:ln_region_rom<={1'b1,11'd530,11'd642,12'd147,STATIC,8'd12,8'd20,6'd16,2'd0,6'd3,2'd0};
   8'd42:ln_region_rom<={1'b1,11'd792,11'd892,12'd139,STATIC,8'd13,8'd28,6'd23,2'd1,6'd4,2'd0};
   8'd43:ln_region_rom<={1'b1,11'd892,11'd948,12'd139,STATIC,8'd14,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd44:ln_region_rom<={1'b1,11'd1228,11'd1264,12'd149,STATIC,8'd15,8'd18,6'd17,2'd0,6'd0,2'd0};
   8'd45:ln_region_rom<={1'b1,11'd1306,11'd1332,12'd149,VOICEID,8'd16,8'd18,6'd14,2'd0,6'd2,2'd0};
   8'd46:ln_region_rom<={1'b1,11'd1534,11'd1646,12'd139,STATIC,8'd19,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd47:ln_region_rom<={1'b1,11'd1772,11'd1826,12'd149,XY,8'd20,8'd18,6'd17,2'd0,6'd0,2'd0};
   8'd49:ln_region_rom<={1'b1,11'd1192,11'd1264,12'd195,STATIC,8'd17,8'd18,6'd17,2'd0,6'd0,2'd0};
   8'd51:ln_region_rom<={1'b1,11'd794,11'd805,12'd206,STATIC,8'd48,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd52:ln_region_rom<={1'b1,11'd1192,11'd1264,12'd195,STATIC,8'd17,8'd18,6'd17,2'd0,6'd0,2'd0};
   8'd54:ln_region_rom<={1'b1,11'd51,11'd73,12'd209,STATIC,8'd45,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd55:ln_region_rom<={1'b1,11'd794,11'd805,12'd206,STATIC,8'd48,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd56:ln_region_rom<={1'b1,11'd1192,11'd1264,12'd195,STATIC,8'd17,8'd18,6'd17,2'd0,6'd0,2'd0};
   8'd58:ln_region_rom<={1'b1,11'd51,11'd73,12'd209,STATIC,8'd45,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd59:ln_region_rom<={1'b1,11'd794,11'd805,12'd206,STATIC,8'd48,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd61:ln_region_rom<={1'b1,11'd51,11'd73,12'd209,STATIC,8'd45,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd63:ln_region_rom<={1'b1,11'd794,11'd827,12'd306,STATIC,8'd49,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd65:ln_region_rom<={1'b1,11'd55,11'd66,12'd313,STATIC,8'd46,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd66:ln_region_rom<={1'b1,11'd794,11'd827,12'd306,STATIC,8'd49,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd68:ln_region_rom<={1'b1,11'd55,11'd66,12'd313,STATIC,8'd46,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd70:ln_region_rom<={1'b1,11'd926,11'd986,12'd330,STATIC,8'd89,8'd20,6'd19,2'd0,6'd0,2'd2};
   8'd72:ln_region_rom<={1'b1,11'd51,11'd73,12'd415,STATIC,8'd47,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd74:ln_region_rom<={1'b1,11'd51,11'd73,12'd415,STATIC,8'd47,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd75:ln_region_rom<={1'b1,11'd794,11'd805,12'd422,STATIC,8'd50,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd77:ln_region_rom<={1'b1,11'd794,11'd805,12'd422,STATIC,8'd50,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd79:ln_region_rom<={1'b1,11'd794,11'd805,12'd422,STATIC,8'd50,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd80:ln_region_rom<={1'b1,11'd1420,11'd1450,12'd435,STATIC,8'd18,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd82:ln_region_rom<={1'b1,11'd1420,11'd1450,12'd435,STATIC,8'd18,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd84:ln_region_rom<={1'b1,11'd52,11'd108,12'd509,STATIC,8'd21,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd85:ln_region_rom<={1'b1,11'd108,11'd208,12'd509,STATIC,8'd22,8'd28,6'd23,2'd1,6'd4,2'd0};
   8'd86:ln_region_rom<={1'b1,11'd208,11'd264,12'd509,STATIC,8'd23,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd88:ln_region_rom<={1'b1,11'd52,11'd108,12'd509,STATIC,8'd21,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd89:ln_region_rom<={1'b1,11'd108,11'd208,12'd509,STATIC,8'd22,8'd28,6'd23,2'd1,6'd4,2'd0};
   8'd90:ln_region_rom<={1'b1,11'd208,11'd264,12'd509,STATIC,8'd23,8'd28,6'd27,2'd1,6'd0,2'd0};
   8'd91:ln_region_rom<={1'b1,11'd1482,11'd1522,12'd515,STATIC,8'd24,8'd20,6'd19,2'd0,6'd0,2'd0};
   8'd92:ln_region_rom<={1'b1,11'd1548,11'd1660,12'd515,PEAK,8'd25,8'd20,6'd16,2'd0,6'd3,2'd0};
   8'd94:ln_region_rom<={1'b1,11'd32,11'd120,12'd556,AXIS,8'd0,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd95:ln_region_rom<={1'b1,11'd325,11'd413,12'd556,AXIS,8'd1,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd96:ln_region_rom<={1'b1,11'd618,11'd706,12'd556,AXIS,8'd2,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd97:ln_region_rom<={1'b1,11'd912,11'd1000,12'd556,AXIS,8'd3,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd98:ln_region_rom<={1'b1,11'd1205,11'd1293,12'd556,AXIS,8'd4,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd99:ln_region_rom<={1'b1,11'd1498,11'd1586,12'd556,AXIS,8'd5,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd100:ln_region_rom<={1'b1,11'd1791,11'd1879,12'd556,AXIS,8'd6,8'd16,6'd12,2'd0,6'd2,2'd0};
   8'd102:ln_region_rom<={1'b1,11'd50,11'd64,12'd598,STATIC,8'd33,8'd14,6'd13,2'd0,6'd0,2'd0};
   8'd104:ln_region_rom<={1'b1,11'd50,11'd64,12'd674,STATIC,8'd34,8'd14,6'd13,2'd0,6'd0,2'd0};
   8'd106:ln_region_rom<={1'b1,11'd466,11'd494,12'd754,STATIC,8'd38,8'd20,6'd16,2'd2,6'd3,2'd1};
   8'd107:ln_region_rom<={1'b1,11'd716,11'd744,12'd754,STATIC,8'd40,8'd20,6'd16,2'd2,6'd3,2'd1};
   8'd108:ln_region_rom<={1'b1,11'd966,11'd994,12'd754,STATIC,8'd42,8'd20,6'd16,2'd2,6'd3,2'd1};
   8'd109:ln_region_rom<={1'b1,11'd1240,11'd1310,12'd754,STATIC,8'd44,8'd20,6'd16,2'd0,6'd3,2'd1};
   8'd111:ln_region_rom<={1'b1,11'd52,11'd142,12'd755,STATIC,8'd35,8'd18,6'd17,2'd1,6'd0,2'd1};
   8'd112:ln_region_rom<={1'b1,11'd400,11'd436,12'd755,STATIC,8'd37,8'd18,6'd17,2'd0,6'd0,2'd1};
   8'd113:ln_region_rom<={1'b1,11'd466,11'd494,12'd754,STATIC,8'd38,8'd20,6'd16,2'd2,6'd3,2'd1};
   8'd114:ln_region_rom<={1'b1,11'd650,11'd686,12'd755,STATIC,8'd39,8'd18,6'd17,2'd0,6'd0,2'd1};
   8'd115:ln_region_rom<={1'b1,11'd716,11'd744,12'd754,STATIC,8'd40,8'd20,6'd16,2'd2,6'd3,2'd1};
   8'd116:ln_region_rom<={1'b1,11'd900,11'd936,12'd755,STATIC,8'd41,8'd18,6'd17,2'd0,6'd0,2'd1};
   8'd117:ln_region_rom<={1'b1,11'd966,11'd994,12'd754,STATIC,8'd42,8'd20,6'd16,2'd2,6'd3,2'd1};
   8'd118:ln_region_rom<={1'b1,11'd1150,11'd1204,12'd755,STATIC,8'd43,8'd18,6'd17,2'd0,6'd0,2'd1};
   8'd119:ln_region_rom<={1'b1,11'd1240,11'd1310,12'd754,STATIC,8'd44,8'd20,6'd16,2'd0,6'd3,2'd1};
   8'd120:ln_region_rom<={1'b1,11'd1560,11'd1650,12'd755,STATIC,8'd36,8'd18,6'd17,2'd1,6'd0,2'd1};
   8'd122:ln_region_rom<={1'b1,11'd84,11'd162,12'd804,STATIC,8'd51,8'd26,6'd25,2'd1,6'd0,2'd0};
   8'd123:ln_region_rom<={1'b1,11'd162,11'd198,12'd804,STATIC,8'd52,8'd26,6'd21,2'd1,6'd4,2'd0};
   8'd124:ln_region_rom<={1'b1,11'd1028,11'd1106,12'd804,STATIC,8'd53,8'd26,6'd25,2'd1,6'd0,2'd0};
   8'd125:ln_region_rom<={1'b1,11'd1106,11'd1142,12'd804,STATIC,8'd54,8'd26,6'd21,2'd1,6'd4,2'd0};
   8'd127:ln_region_rom<={1'b1,11'd84,11'd162,12'd804,STATIC,8'd51,8'd26,6'd25,2'd1,6'd0,2'd0};
   8'd128:ln_region_rom<={1'b1,11'd162,11'd198,12'd804,STATIC,8'd52,8'd26,6'd21,2'd1,6'd4,2'd0};
   8'd129:ln_region_rom<={1'b1,11'd770,11'd824,12'd812,KEYSTATUS,8'd55,8'd18,6'd17,2'd0,6'd0,2'd0};
   8'd130:ln_region_rom<={1'b1,11'd1028,11'd1106,12'd804,STATIC,8'd53,8'd26,6'd25,2'd1,6'd0,2'd0};
   8'd131:ln_region_rom<={1'b1,11'd1106,11'd1142,12'd804,STATIC,8'd54,8'd26,6'd21,2'd1,6'd4,2'd0};
   8'd132:ln_region_rom<={1'b1,11'd1714,11'd1768,12'd812,KEYSTATUS,8'd72,8'd18,6'd17,2'd0,6'd0,2'd0};
   8'd134:ln_region_rom<={1'b1,11'd874,11'd898,12'd858,KEY,8'd15,8'd12,6'd9,2'd0,6'd2,2'd0};
   8'd135:ln_region_rom<={1'b1,11'd1818,11'd1842,12'd858,KEY,8'd31,8'd12,6'd9,2'd0,6'd2,2'd0};
   8'd137:ln_region_rom<={1'b1,11'd126,11'd156,12'd921,KEY,8'd1,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd138:ln_region_rom<={1'b1,11'd222,11'd252,12'd921,KEY,8'd3,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd139:ln_region_rom<={1'b1,11'd414,11'd444,12'd921,KEY,8'd6,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd140:ln_region_rom<={1'b1,11'd510,11'd540,12'd921,KEY,8'd8,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd141:ln_region_rom<={1'b1,11'd702,11'd732,12'd921,KEY,8'd10,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd142:ln_region_rom<={1'b1,11'd798,11'd828,12'd921,KEY,8'd13,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd143:ln_region_rom<={1'b1,11'd1070,11'd1100,12'd921,KEY,8'd17,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd144:ln_region_rom<={1'b1,11'd1166,11'd1196,12'd921,KEY,8'd19,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd145:ln_region_rom<={1'b1,11'd1358,11'd1388,12'd921,KEY,8'd22,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd146:ln_region_rom<={1'b1,11'd1454,11'd1484,12'd921,KEY,8'd24,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd147:ln_region_rom<={1'b1,11'd1646,11'd1676,12'd921,KEY,8'd26,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd148:ln_region_rom<={1'b1,11'd1742,11'd1772,12'd921,KEY,8'd29,8'd14,6'd11,2'd0,6'd2,2'd0};
   8'd150:ln_region_rom<={1'b1,11'd71,11'd110,12'd974,KEY,8'd0,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd151:ln_region_rom<={1'b1,11'd167,11'd206,12'd974,KEY,8'd2,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd152:ln_region_rom<={1'b1,11'd263,11'd302,12'd974,KEY,8'd4,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd153:ln_region_rom<={1'b1,11'd359,11'd398,12'd974,KEY,8'd5,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd154:ln_region_rom<={1'b1,11'd455,11'd494,12'd974,KEY,8'd7,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd155:ln_region_rom<={1'b1,11'd551,11'd590,12'd974,KEY,8'd9,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd156:ln_region_rom<={1'b1,11'd647,11'd686,12'd974,KEY,8'd11,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd157:ln_region_rom<={1'b1,11'd743,11'd782,12'd974,KEY,8'd12,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd158:ln_region_rom<={1'b1,11'd839,11'd878,12'd974,KEY,8'd14,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd159:ln_region_rom<={1'b1,11'd1015,11'd1054,12'd974,KEY,8'd16,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd160:ln_region_rom<={1'b1,11'd1111,11'd1150,12'd974,KEY,8'd18,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd161:ln_region_rom<={1'b1,11'd1207,11'd1246,12'd974,KEY,8'd20,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd162:ln_region_rom<={1'b1,11'd1303,11'd1342,12'd974,KEY,8'd21,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd163:ln_region_rom<={1'b1,11'd1399,11'd1438,12'd974,KEY,8'd23,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd164:ln_region_rom<={1'b1,11'd1495,11'd1534,12'd974,KEY,8'd25,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd165:ln_region_rom<={1'b1,11'd1591,11'd1630,12'd974,KEY,8'd27,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd166:ln_region_rom<={1'b1,11'd1687,11'd1726,12'd974,KEY,8'd28,8'd18,6'd14,2'd3,6'd2,2'd0};
   8'd167:ln_region_rom<={1'b1,11'd1783,11'd1822,12'd974,KEY,8'd30,8'd18,6'd14,2'd3,6'd2,2'd0};
   default:ln_region_rom<=71'd0;
  endcase
 wire ln_nxt_in=ln_region_rom[70];wire [10:0] ln_rom_x0=ln_region_rom[69:59],ln_rom_x1=ln_region_rom[58:48];wire [11:0] ln_rom_y0=ln_region_rom[47:36];
 reg ln_nxt_valid,ln_inside;reg [1:0] ln_load_wait;reg [11:0] ln_y_prev;
 reg [10:0] ln_nxt_x0,ln_nxt_x1,ln_cur_x1;reg [11:0] ln_nxt_y0,ln_cur_y0;reg [3:0] ln_nxt_kind,ln_cur_kind;reg [7:0] ln_nxt_arg,ln_cur_arg,ln_nxt_size,ln_cur_size;
 reg [5:0] ln_nxt_wrap,ln_cur_wrap,ln_nxt_off,ln_cur_off,ln_pos,ln_col;reg [1:0] ln_nxt_tone,ln_cur_tone,ln_nxt_cond,ln_cur_cond;
 initial begin ln_nxt_valid=0;ln_inside=0;ln_load_wait=0;ln_y_prev=12'hfff;ln_fetch_addr=0;ln_pos=0;ln_col=0;end
 wire ln_new_line=y!=ln_y_prev;
 wire ln_start=!ln_new_line && ln_nxt_valid && x=={1'b0,ln_nxt_x0};
 wire ln_stop=ln_inside && x=={1'b0,ln_cur_x1};
 wire ln_wrap=ln_col==ln_cur_wrap;
 wire ln_inside_next=!ln_new_line && (ln_start || (ln_inside && !ln_stop));
 wire [5:0] ln_pos_next=ln_start?6'd0:(ln_wrap?ln_pos+6'd1:ln_pos);
 wire [5:0] ln_col_next=ln_start?ln_nxt_off:(ln_wrap?ln_cur_off:ln_col+6'd1);
 wire [1:0] ln_cond_now=ln_start?ln_nxt_cond:ln_cur_cond;
 wire ln_cond_ok=ln_cond_now==2'd0 || (ln_cond_now==2'd1 && guide_mode) || (ln_cond_now==2'd2 && !env_valid);
 wire [11:0] ln_dy_now=y-(ln_start?ln_nxt_y0:ln_cur_y0);
 wire [39:0] ln_line_attributes=ln_inside_next && ln_cond_ok?{ln_start?ln_nxt_kind:ln_cur_kind,ln_start?ln_nxt_arg:ln_cur_arg,ln_start?ln_nxt_size:ln_cur_size,
  ln_pos_next,ln_start?ln_nxt_tone:ln_cur_tone,ln_col_next,ln_dy_now[5:0]}:40'd0;
 reg [39:0] ln_attributes_q;
 always @(posedge clk)begin
  ln_y_prev<=y;ln_attributes_q<=ln_line_attributes;
  ln_inside<=ln_inside_next;ln_pos<=ln_pos_next;ln_col<=ln_col_next;
  if(ln_start)begin
   ln_cur_x1<=ln_nxt_x1;ln_cur_y0<=ln_nxt_y0;ln_cur_kind<=ln_nxt_kind;ln_cur_arg<=ln_nxt_arg;ln_cur_size<=ln_nxt_size;
   ln_cur_wrap<=ln_nxt_wrap;ln_cur_tone<=ln_nxt_tone;ln_cur_off<=ln_nxt_off;ln_cur_cond<=ln_nxt_cond;
  end
  if(ln_new_line)begin ln_fetch_addr<=ln_line_list;ln_nxt_valid<=0;ln_load_wait<=2'd2;end
  else if(ln_start)begin ln_fetch_addr<=ln_fetch_addr+1'b1;ln_nxt_valid<=0;ln_load_wait<=2'd2;end
  else if(ln_load_wait!=0)begin
   ln_load_wait<=ln_load_wait-1'b1;
   if(ln_load_wait==2'd1)begin
    ln_nxt_valid<=ln_nxt_in;ln_nxt_x0<=ln_rom_x0;ln_nxt_x1<=ln_rom_x1;ln_nxt_y0<=ln_rom_y0;{ln_nxt_kind,ln_nxt_arg,ln_nxt_size,ln_nxt_wrap,ln_nxt_tone,ln_nxt_off,ln_nxt_cond}<=ln_region_rom[35:0];
   end
  end
 end
 wire [39:0] attributes_comb=ln_attributes_q;
 assign {kind,argument,font_size,pos,tone,col,row}=attr_char;
 reg [39:0] attr_pipe[0:14];reg [39:0] attr_char,attr_glyph;
 integer stage_i;
 always @(posedge clk)begin

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
  key_note_pipe[0]<=pick_key_note(status_data,attr_pipe[0][32:28]);
  for(note_stage=1;note_stage<14;note_stage=note_stage+1)
   key_note_pipe[note_stage]<=key_note_pipe[note_stage-1];
 end
 // Double-dabble stages stay in flip-flops: as distributed-RAM shift chains
 // their first write-data pin failed hold against the status registers.
 (* syn_srlstyle="registers" *) reg [35:0] peak_bcd_pipe[0:15];
 (* syn_srlstyle="registers" *) reg [35:0] completed_bcd_pipe[0:15];
 reg [511:0] char_status;
 // Branch frame_status: status and control inputs change only at blank_start;
 // read them directly (with the original bits 82..305 drop) instead of
 // through 16-stage delay pipes.
 wire [511:0] status_tail={status_data[511:306],224'b0,status_data[81:0]};
 wire [28:0] control_now={status_live,peak_valid,peak_hz,xy_direct,xy_signal,xy_mixed,xy_shift,spectrum_range};
 reg [28:0] char_control;
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
 wire [511:0] count_status=status_tail;wire [28:0] count_control=control_now;
 wire count_keys_valid=count_control[28] && count_status[0];
 wire count_guide_valid=count_control[28] && count_status[455] && count_status[456+:2]==2;
 wire count_target_valid=count_guide_valid && count_keys_valid && (count_status[490+:3]==2 || count_status[490+:3]==3);
 wire [31:0] count_actual=count_keys_valid?count_status[18+:32]:32'd0;
 wire [31:0] count_targets=count_target_valid?count_status[458+:32]:32'd0;
 integer meta_i;
 always @(posedge clk)begin
  peak_bcd_pipe[0]<=bcd_step({peak_hz,20'd0});
  completed_bcd_pipe[0]<=bcd_step({status_data[493+:16],20'd0});
  for(meta_i=1;meta_i<16;meta_i=meta_i+1)begin
   peak_bcd_pipe[meta_i]<=bcd_step(peak_bcd_pipe[meta_i-1]);
   completed_bcd_pipe[meta_i]<=bcd_step(completed_bcd_pipe[meta_i-1]);
  end
  char_status<=status_tail;char_control<=control_now;
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
  completed_character_q[1]<=(status_data[493+:16] < 16'd10 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][4+:4]));
  completed_character_q[2]<=(status_data[493+:16] < 16'd100 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][8+:4]));
  completed_character_q[3]<=(status_data[493+:16] < 16'd1000 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][12+:4]));
  completed_character_q[4]<=(status_data[493+:16] < 16'd10000 ? 16'd32 : 16'd48+16'(completed_bcd_pipe[15][16+:4]));
 end
 reg [19:0] axis_bcd_q;
 always @(posedge clk)axis_bcd_q<=axis_bcd(spectrum_range,attr_pipe[14][35:28]);
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
module visual_glyph_index(input wire clk,input wire[7:0] font_size,input wire[15:0] character,
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
