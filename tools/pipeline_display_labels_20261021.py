"""Exact text raster pipeline: regions, decimal conversion, glyph and ROM."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1];A=R/'audit/display_integration_20261021/timing_repair'
p=R/'src/display/visual_labels.sv';b=A/'visual_labels.before_pipeline.sv'
if not b.exists():b.write_bytes(p.read_bytes())
s=b.read_text()
s=s.replace('module visual_labels #','(* syn_srlstyle="distributed_ram" *)\nmodule visual_labels #')
# Balanced popcount; same integer result for every 32-bit input.
start=s.index(' function automatic [5:0] count_voices');end=s.index(' function automatic [31:0] decimal_power',start)
s=s[:start]+''' function automatic [5:0] count_voices(input [31:0] value);
 reg [1:0] p2[0:15];reg [2:0] p4[0:7];reg [3:0] p8[0:3];reg [4:0] p16[0:1];integer i;
 begin
 for(i=0;i<16;i=i+1)p2[i]={1'b0,value[i*2]}+{1'b0,value[i*2+1]};
 for(i=0;i<8;i=i+1)p4[i]={1'b0,p2[i*2]}+{1'b0,p2[i*2+1]};
 for(i=0;i<4;i=i+1)p8[i]={1'b0,p4[i*2]}+{1'b0,p4[i*2+1]};
 for(i=0;i<2;i=i+1)p16[i]={1'b0,p8[i*2]}+{1'b0,p8[i*2+1]};
 count_voices={1'b0,p16[0]}+{1'b0,p16[1]};end endfunction
'''+s[end:]
# Content helpers consume the same pixel's delayed snapshot.
renames={'status_data':'char_status','status_live':'char_live','mapping_valid':'c_mapping_valid',
 'xy_direct':'char_direct','xy_signal':'char_signal','xy_mixed':'char_mixed'}
for fn in ['key_char','timbre_char','xy_char']:
 pattern=r' function automatic .*?\b'+fn+r'\(.*?endfunction'
 # Bound the search to the individual function (no spanning earlier helpers).
 m=next(m for m in re.finditer(r' function automatic .*?endfunction',s,re.S) if re.search(r'\b'+fn+r'\(',m[0]))
 v=re.sub(r'\b('+ '|'.join(renames)+r')\b',lambda m:renames[m[0]],m[0]);s=s[:m.start()]+v+s[m.end():]
s=s.replace('note=char_status[82+key*7+:7];','note=char_key_note;')
s=s.replace('input [15:0] completed_events);','input [15:0] completed_events,input [19:0] completed_bcd);')
s=s.replace("64'(spectrum_range)+1", "64'(char_range)+1")
for place in range(5):
 replacement=f"16'd48+16'(completed_bcd[{place*4}+:4])"
 if place:replacement=f"(completed_events < 16'd{10**place} ? 16'd32 : {replacement})"
 s=s.replace(f"decimal_trim({{16'd0,completed_events}},{place})",replacement)
# The geometry is still computed directly from the original raw coordinates.
# Register region results before the balanced OR, then align to the BCD pipeline.
s=s.replace(' wire [39:0] attributes=', ' wire [39:0] attributes_comb=')
a=s.index(' wire [39:0] attributes_comb=');z=s.index('\n',a)
s=s[:a]+re.sub(r'\bregion_(\d+)\b',lambda m:f'region_q[{m[1]}]',s[a:z])+s[z:]
s=s.replace(' assign {kind,argument,font_size,pos,tone,col,row}=attributes;',
 ''' assign {kind,argument,font_size,pos,tone,col,row}=attr_char;
 reg [39:0] region_q[0:89],attr_pipe[0:14];reg [39:0] attr_char,attr_glyph;
 integer stage_i;
 always @(posedge clk)begin
'''+''.join(f'  region_q[{i}]<=region_{i};\n' for i in range(90))+'''
  attr_pipe[0]<=attributes_comb;
  for(stage_i=1;stage_i<15;stage_i=stage_i+1)attr_pipe[stage_i]<=attr_pipe[stage_i-1];
  attr_char<=attr_pipe[14];attr_glyph<=attr_char;
 end
''')
# A fully pipelined, exact binary-to-BCD conversion avoids division in the pixel
# character path. The same latency carries all dynamic content and its geometry.
pipeline='''
 localparam LABEL_LATENCY=21;
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
__KEY_CASES__
 endcase end endfunction
 reg [6:0] char_key_note;
 reg [35:0] peak_bcd_pipe[0:15],completed_bcd_pipe[0:15];
 reg [511:0] status_pipe[0:15],char_status;
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
 wire [511:0] count_status=status_pipe[15];wire [28:0] count_control=control_pipe[15];
 wire count_keys_valid=count_control[28] && count_status[0];
 wire count_guide_valid=count_control[28] && count_status[455] && count_status[456+:2]==2;
 wire count_target_valid=count_guide_valid && count_keys_valid && (count_status[490+:3]==2 || count_status[490+:3]==3);
 wire [31:0] count_actual=count_keys_valid?count_status[18+:32]:32'd0;
 wire [31:0] count_targets=count_target_valid?count_status[458+:32]:32'd0;
 integer meta_i;
 always @(posedge clk)begin
  peak_bcd_pipe[0]<=bcd_step({peak_hz,20'd0});
  completed_bcd_pipe[0]<=bcd_step({status_data[493+:16],20'd0});
  status_pipe[0]<=status_data;
  control_pipe[0]<={status_live,peak_valid,peak_hz,xy_direct,xy_signal,xy_mixed,xy_shift,spectrum_range};
  for(meta_i=1;meta_i<16;meta_i=meta_i+1)begin
   peak_bcd_pipe[meta_i]<=bcd_step(peak_bcd_pipe[meta_i-1]);
   completed_bcd_pipe[meta_i]<=bcd_step(completed_bcd_pipe[meta_i-1]);
   status_pipe[meta_i]<=status_pipe[meta_i-1];control_pipe[meta_i]<=control_pipe[meta_i-1];
  end
  char_status<=status_pipe[15];char_control<=control_pipe[15];
  char_key_note<=pick_key_note(status_pipe[15],attr_pipe[14][32:28]);
  char_peak_bcd<=peak_bcd_pipe[15][19:0];char_completed_bcd<=completed_bcd_pipe[15][19:0];
  c_voice_count<=count_voices(count_status[50+:32]);
  c_target_count<=count_voices(count_targets & ~count_actual);
  c_pressed_count<=count_voices(count_actual);
  c_wrong_count<=count_voices(count_target_valid?(count_actual & ~count_targets):32'd0);
 end
 function automatic [19:0] axis_bcd(input [1:0] range_sel,input [7:0] tick);
 begin case({range_sel,tick})
'''
pipeline=pipeline.replace('__KEY_CASES__','\n'.join(f" 5'd{k}:pick_key_note=snapshot[{82+k*7}+:7];" for k in range(32)))
# All possible tick arguments in the unchanged region descriptors.
ticks=sorted(set(int(x) for x in re.findall(r"\{AXIS,8'd(\d+)",s)))
for r in range(4):
 for tick in ticks:
  pipeline+=f" 10'd{r*256+tick}:axis_bcd=const_bcd((64'(SAMPLE_RATE)*64'd{r+1}*64'd{tick})/48);\n"
pipeline+=' default:axis_bcd=0;endcase end endfunction\n'
pipeline+=''' reg [19:0] numeric_bcd;
 always @* begin
  numeric_bcd=0;
  case(kind)
   VOICES:numeric_bcd={12'd0,two_digits(c_voice_count)};
   VOICEID:numeric_bcd={12'd0,two_digits({1'b0,char_status[450+:5]}+6'd1)};
   SAMPLE:numeric_bcd=const_bcd(SAMPLE_RATE/1000);
   AXIS:numeric_bcd=axis_bcd(char_range,argument);
   PEAK:numeric_bcd=char_peak_bcd;
   default:begin end
  endcase
 end
 wire [15:0] digit_value=16'd48+16'(numeric_bcd[numeric_place*4+:4]);
 wire [15:0] trimmed_value=(numeric_place>0 && (numeric_bcd>>(numeric_place*4))==0)?16'd32:digit_value;
'''
# Replace the old combinational decimal arithmetic, leave its exact trimming.
s=s.replace(' wire [15:0] digit_value=decimal(numeric_value,numeric_place);\n wire [15:0] trimmed_value=decimal_trim(numeric_value,numeric_place);',pipeline)
start=s.index(' always @* begin\n  numeric_value=');end=s.index(' always @(posedge clk)begin\n  coverage<=',start)
content=s[start:end]
content=content.replace('always @* begin\n  ch=', 'always @* begin\n  ch_next=')
content=re.sub(r'\bch\b','ch_next',content)
mapping={x:'c_'+x for x in ['note_valid','voices_valid','env_valid','keys_valid','mode_valid','mode','guide_state','target_count','pressed_count','wrong_count','voice_count']}
mapping.update(status_data='char_status',peak_valid='char_peak_valid',peak_hz='char_hz')
# Do not rename the raw-input sources inside the newly inserted metadata pipeline.
pre,pipe,post=content.partition(' localparam LABEL_LATENCY=21;')
pipe_body,sep,charpart=post.partition(' always @* begin\n  ch_next=')
def rename(t):return re.sub(r'\b('+ '|'.join(mapping)+r')\b',lambda m:mapping[m[0]],t)
pre=rename(pre);charpart=rename(charpart)
charpart=charpart.replace('char_status[493+:16]);','char_status[493+:16],char_completed_bcd);')
content=pre+pipe+pipe_body+sep.replace('always @*','always_comb')+charpart
s=s[:start]+content+s[end:]
s=s.replace('reg [15:0] ch;','reg [15:0] ch,ch_next;')
# Glyph selection is separated from character selection and row multiplication.
s=s.replace('case({font_size,ch})','case({attr_glyph[27:20],ch})')
a=s.index(' wire [16:0] font_addr=');z=s.index('\n',s.index(' wire font_visible=',a))
s=s[:a]+''' reg [16:0] base_q,font_addr_q;reg [11:0] row_product_q;reg [5:0] col_q;
 reg visible_q,visible_addr;reg [23:0] color_q,color_addr;
 always @(posedge clk)begin
  ch<=ch_next;
  base_q<=font_base;row_product_q<=12'(attr_glyph[5:0])*12'(attr_glyph[27:20]);col_q<=attr_glyph[11:6];
  visible_q<=font_found && attr_glyph[5:0]<attr_glyph[27:20] && attr_glyph[11:6]<attr_glyph[27:20];
  case(attr_glyph[13:12])1:color_q<=24'hfaf8f1;2:color_q<=24'hf4f4ec;3:color_q<=24'h4d6269;default:color_q<=24'he6e9e3;endcase
  font_addr_q<=base_q+17'(row_product_q)+17'(col_q);visible_addr<=visible_q;color_addr<=color_q;
 end
'''+s[z:]
a=s.index(' always @(posedge clk)begin\n  coverage<=');z=s.index(' always @* ink=',a)
s=s[:a]+''' always @(posedge clk)begin coverage<=visible_addr?font_rom[font_addr_q]:2'd0;color<=color_addr;end
'''+s[z:]
from display_glyph_index_20261023 import index_labels
s=index_labels(s,R)
from display_bcd_select_20261023 import select_bcd
s=select_bcd(s)
from display_routed_fixes_20261023 import label_fixes
s=label_fixes(s)
from display_hybrid_shift_20261023 import distributed_shifts
from display_routed_fixes_20261023 import stage_axis_digits
s=distributed_shifts(stage_axis_digits(s))
from display_routed_fixes_20261023 import stage_completed_digits
s=stage_completed_digits(s)
p.write_text(s)
print('Generated exact 21-clock label raster pipeline')
