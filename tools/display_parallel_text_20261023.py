"""Parallel character candidates plus a kept balanced one-hot selection tree."""
def parallel_characters(s):
    if 'parallel_character_choice' in s:return s
    a=s.index(' always_comb begin\n  ch_next=16\'d32;\n  case(kind)')
    b=s.index(' always @(posedge clk)begin coverage<=',a)
    body=''' // Independent candidates avoid a deep priority mux across text kinds.
 reg [15:0] static_choice,key_choice,timbre_choice,note_choice,xy_choice;
 reg [15:0] keystatus_choice,voices_choice,voiceid_choice,sample_choice,axis_choice,peak_choice;
 always_comb begin
  // always_comb also tracks module state read inside the text functions.
  static_choice=static_char({argument,pos},c_mode_valid,c_mode,c_guide_state,c_keys_valid,c_target_count,c_pressed_count,c_wrong_count,char_status[493+:16],char_completed_bcd);
  key_choice=key_char(32'(argument),32'(pos));
  timbre_choice=timbre_char(32'(pos));
  note_choice=c_note_valid?note_char(char_status[11+:7],32'(pos)):(pos==0?16'd45:16'd32);
  xy_choice=xy_char(32'(pos));
  keystatus_choice=16'd32;
  if(!c_keys_valid)case(pos)0:keystatus_choice=16'h672a;1:keystatus_choice=16'h63a5;2:keystatus_choice=16'h5165;default:keystatus_choice=32;endcase
  voices_choice=16'd32;
  if(pos<2)voices_choice=c_voices_valid?digit_value:(pos==0?16'd45:16'd32);
  else case(pos)3:voices_choice=47;5:voices_choice=51;6:voices_choice=50;default:voices_choice=32;endcase
  voiceid_choice=pos<2?(c_env_valid?digit_value:(pos==0?16'd45:16'd32)):16'd32;
  sample_choice=16'd32;
  if(pos<2)sample_choice=digit_value;else case(pos)3:sample_choice=107;4:sample_choice=72;5:sample_choice=122;default:sample_choice=32;endcase
  axis_choice=16'd32;
  if(pos<5)axis_choice=trimmed_value;else case(pos)6:axis_choice=72;7:axis_choice=122;default:axis_choice=32;endcase
  peak_choice=16'd32;
  if(pos<5)peak_choice=char_peak_valid?trimmed_value:(pos==0?16'd45:16'd32);
  else case(pos)6:peak_choice=72;7:peak_choice=122;default:peak_choice=32;endcase
 end
 reg [11:0] character_select;
 always_comb begin
  character_select=12'd0;
  case(kind)
   STATIC:character_select[0]=1'b1;KEY:character_select[1]=1'b1;
   TIMBRE:character_select[2]=1'b1;NOTE:character_select[3]=1'b1;
   VOICES:character_select[4]=1'b1;VOICEID:character_select[5]=1'b1;
   SAMPLE:character_select[6]=1'b1;PEAK:character_select[7]=1'b1;
   XY:character_select[8]=1'b1;KEYSTATUS:character_select[9]=1'b1;
   AXIS:character_select[10]=1'b1;default:character_select[11]=1'b1;
  endcase
 end
 wire [15:0] parallel_character_choice[0:11];
 assign parallel_character_choice[0]=static_choice;
 assign parallel_character_choice[1]=key_choice;
 assign parallel_character_choice[2]=timbre_choice;
 assign parallel_character_choice[3]=note_choice;
 assign parallel_character_choice[4]=voices_choice;
 assign parallel_character_choice[5]=voiceid_choice;
 assign parallel_character_choice[6]=sample_choice;
 assign parallel_character_choice[7]=peak_choice;
 assign parallel_character_choice[8]=xy_choice;
 assign parallel_character_choice[9]=keystatus_choice;
 assign parallel_character_choice[10]=axis_choice;
 assign parallel_character_choice[11]=16'd32;
 (* syn_keep=1 *) wire [191:0] character_terms;
 (* syn_keep=1 *) wire [95:0] character_pairs;
 (* syn_keep=1 *) wire [47:0] character_quads;
 (* syn_keep=1 *) wire [31:0] character_halves;
 generate
  for(genvar ci=0;ci<12;ci=ci+1)begin:CHARACTER_TERM
   assign character_terms[ci*16+:16]=parallel_character_choice[ci]&{16{character_select[ci]}};
  end
  for(genvar ci=0;ci<6;ci=ci+1)begin:CHARACTER_PAIR
   assign character_pairs[ci*16+:16]=character_terms[ci*32+:16]|character_terms[ci*32+16+:16];
  end
  for(genvar ci=0;ci<3;ci=ci+1)begin:CHARACTER_QUAD
   assign character_quads[ci*16+:16]=character_pairs[ci*32+:16]|character_pairs[ci*32+16+:16];
  end
 endgenerate
 assign character_halves[15:0]=character_quads[15:0]|character_quads[31:16];
 assign character_halves[31:16]=character_quads[47:32];
 always_comb ch_next=character_halves[15:0]|character_halves[31:16];
'''
    return s[:a]+body+s[b:]
