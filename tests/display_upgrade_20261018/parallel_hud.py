from pathlib import Path
R=Path(__file__).resolve().parents[2];p=R/'src/display/piano_status_overlay.sv';s=p.read_text()
a=s.index('   if(pos<5)ch=');b=s.index('\n  end else if(x<392',a)
case={i:f'instrument_name[{127-8*i}-:8]' for i in range(5)}
def string(c,start,value):
 for i,ch in enumerate(value):c[start+i]=f'8\'d{ord(ch)}'
string(case,7,'VOICES=');string(case,18,'NOTE=');string(case,28,'MIDI=')
case.update({14:"8'(48+32'(voices)/10)",15:"8'(48+32'(voices)%10)",23:"note_valid?note_letter:8'd45",24:"note_valid?note_accidental:8'd45",25:"note_valid?note_octave:8'd45",33:"note_valid?8'(48+32'(note)/100):8'd45",34:"note_valid?8'(48+(32'(note)/10)%10):8'd45",35:"note_valid?8'(48+32'(note)%10):8'd45"})
def emit(c):return '   case(pos)\n'+''.join(f'    {i}:ch={v};\n' for i,v in sorted(c.items()))+"    default:ch=8'd32;\n   endcase"
s=s[:a]+emit(case)+s[b:]
a=s.index('   if(pos<5)ch=',s.index('end else if(x<392'));b=s.index('\n  end\n  bits=',a)
case={i:f"MAPPING_CONFIRMED?8'd{ord('KEYS='[i])}:8'd{ord('RAWS='[i])}" for i in range(5)}
case.update({5+i:f'hexchar(keys[{15-4*i}-:4])' for i in range(4)})
case.update({16+i:f'hexchar(peak[{23-4*i}-:4])' for i in range(6)})
string(case,11,'PEAK=');string(case,24,'STAGE=');string(case,33,'MAP=')
case.update({30:'hexchar(stage)',37:"MAPPING_CONFIRMED?8'd49:8'd48"})
s=s[:a]+emit(case)+s[b:]
s=s.replace('integer pos,col,row,noteclass;','reg [5:0] pos;reg [2:0] col,row;integer noteclass;')
s=s.replace("pos=32'(x)>>3;col=32'(x)&7;row=32'(y)-INFO_Y;","pos=x[8:3];col=x[2:0];row=3'(y-INFO_Y);")
s=s.replace("pos=32'(x)>>3;col=32'(x)&7;row=32'(y)-DETAIL_Y;","pos=x[8:3];col=x[2:0];row=3'(y-DETAIL_Y);")
s=s.replace('bits[34-(row*5+col)]',"bits[6'd34-({3'd0,row}*6'd5+{3'd0,col})]")
p.write_text(s)
p=R/'src/display/audio_visualizer.sv';s=p.read_text();a=s.index(' wire show_text=');b=s.index(' // Register RGB/control',a)
s=s[:a]+''' reg status_ink_d,key_area_d,key_on_d;
 reg [7:0] render_r_d,render_g_d,render_b_d;
 reg render_de_d,render_hs_d,render_vs_d;
 always @(posedge pixel_clk or negedge display_rst_n)
 if(!display_rst_n)begin
  status_ink_d<=0;key_area_d<=0;key_on_d<=0;
  render_r_d<=0;render_g_d<=0;render_b_d<=0;
  render_de_d<=0;render_hs_d<=0;render_vs_d<=0;
 end else begin
  status_ink_d<=status_ink;key_area_d<=key_area;key_on_d<=key_on;
  render_r_d<=r;render_g_d<=g;render_b_d<=b;
  render_de_d<=render_de;render_hs_d<=render_hs;render_vs_d<=render_vs;
 end
 wire show_text=STATUS_ENABLE!=0 && status_ink_d;
 wire show_key=STATUS_ENABLE!=0 && key_area_d;
''' +s[b:]
s=s.replace('de_d<=render_de;hs_d<=render_hs;vs_d<=render_vs;','de_d<=render_de_d;hs_d<=render_hs_d;vs_d<=render_vs_d;')
for c in ['r','g','b']:
 s=s.replace('(key_on?', '(key_on_d?').replace(f'):{c});',f'):render_{c}_d);')
p.write_text(s)
