"""Exact fixed-latency pipeline for the delivered procedural scene shader."""
from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[1];A=R/'audit/display_integration_20261021/timing_repair';A.mkdir(exist_ok=True)
p=R/'src/display/visual_scene.sv'
if (A/'visual_scene.before_pipeline.sv').exists():old=(A/'visual_scene.before_pipeline.sv').read_text()
else:
 old=p.read_text();(A/'visual_scene.before_pipeline.sv').write_bytes(p.read_bytes())
scene=old.split('module visual_light_motion')[0]
functions='\n'.join(re.findall(r' function automatic .*?endfunction',scene,re.S))
functions=functions.replace('rounded(input integer sx,sy,x0,y0,w,h,r)',
 'rounded(input signed [12:0] sx,sy,x0,y0,w,h,r)')
functions=functions.replace('integer ab(input integer v)','signed [13:0] ab(input signed [13:0] v)')
functions+='\n function automatic [7:0] key_abs(input signed [7:0] v);begin key_abs=v<0?-v:v;end endfunction\n'
functions+='\n function automatic [3:0] rim_light(input [3:0] r);begin case(r)\n'
functions+='\n'.join(f" 4'd{r}:rim_light=4'd{r*r//13};" for r in range(14))
functions+='\n default:rim_light=0;endcase end endfunction\n'
assert all((n*2341)>>14==n//7 for n in range(2048))
functions+='''\n function automatic [10:0] unsigned_divide7(input [10:0] n);
 reg [22:0] p;begin p=23'(n)*23'd2341;unsigned_divide7=11'(p>>14);end endfunction\n'''
functions+=' function automatic [7:0] min_key_edges(input [7:0] horizontal,top_edge,bottom_edge);\n  reg [7:0] vertical;begin\n   vertical=top_edge<bottom_edge?top_edge:bottom_edge;\n   min_key_edges=horizontal<vertical?horizontal:vertical;\n  end\n endfunction\n'
functions+=" function automatic [11:0] div13_seed(input [5:0] hi);begin case(hi)\n  6'd0:div13_seed=12'd0;\n  6'd1:div13_seed=12'd38;\n  6'd2:div13_seed=12'd76;\n  6'd3:div13_seed=12'd117;\n  6'd4:div13_seed=12'd155;\n  6'd5:div13_seed=12'd196;\n  6'd6:div13_seed=12'd234;\n  6'd7:div13_seed=12'd275;\n  6'd8:div13_seed=12'd313;\n  6'd9:div13_seed=12'd354;\n  6'd10:div13_seed=12'd392;\n  6'd11:div13_seed=12'd433;\n  6'd12:div13_seed=12'd471;\n  6'd13:div13_seed=12'd512;\n  6'd14:div13_seed=12'd550;\n  6'd15:div13_seed=12'd588;\n  6'd16:div13_seed=12'd629;\n  6'd17:div13_seed=12'd667;\n  6'd18:div13_seed=12'd708;\n  6'd19:div13_seed=12'd746;\n  6'd20:div13_seed=12'd787;\n  6'd21:div13_seed=12'd825;\n  6'd22:div13_seed=12'd866;\n  6'd23:div13_seed=12'd904;\n  6'd24:div13_seed=12'd945;\n  6'd25:div13_seed=12'd983;\n  6'd26:div13_seed=12'd1024;\n  6'd27:div13_seed=12'd1062;\n  6'd28:div13_seed=12'd1100;\n  6'd29:div13_seed=12'd1141;\n  6'd30:div13_seed=12'd1179;\n  6'd31:div13_seed=12'd1220;\n  6'd32:div13_seed=12'd1258;\n  6'd33:div13_seed=12'd1299;\n  6'd34:div13_seed=12'd1337;\n  6'd35:div13_seed=12'd1378;\n  6'd36:div13_seed=12'd1416;\n  6'd37:div13_seed=12'd1457;\n  6'd38:div13_seed=12'd1495;\n  6'd39:div13_seed=12'd1536;\n  6'd40:div13_seed=12'd1574;\n  6'd41:div13_seed=12'd1612;\n  6'd42:div13_seed=12'd1653;\n  6'd43:div13_seed=12'd1691;\n  6'd44:div13_seed=12'd1732;\n  6'd45:div13_seed=12'd1770;\n  6'd46:div13_seed=12'd1811;\n  6'd47:div13_seed=12'd1849;\n  6'd48:div13_seed=12'd1890;\n  6'd49:div13_seed=12'd1928;\n  6'd50:div13_seed=12'd1969;\n  6'd51:div13_seed=12'd2007;\n  6'd52:div13_seed=12'd2048;\n  6'd53:div13_seed=12'd2086;\n  6'd54:div13_seed=12'd2124;\n  6'd55:div13_seed=12'd2165;\n  6'd56:div13_seed=12'd2203;\n  6'd57:div13_seed=12'd2244;\n  6'd58:div13_seed=12'd2282;\n  6'd59:div13_seed=12'd2323;\n  6'd60:div13_seed=12'd2361;\n  6'd61:div13_seed=12'd2402;\n  6'd62:div13_seed=12'd2440;\n  6'd63:div13_seed=12'd2481;\n  default:div13_seed=0;endcase end endfunction\n function automatic [7:0] div13_finish(input [11:0] seed,input [4:0] lo);\n  reg [5:0] residual;reg [1:0] correction;begin\n   residual=6'(seed[3:0])+6'(lo);\n   case(residual)\n    6'd0:correction=2'd0;\n    6'd1:correction=2'd0;\n    6'd2:correction=2'd0;\n    6'd3:correction=2'd0;\n    6'd4:correction=2'd0;\n    6'd5:correction=2'd0;\n    6'd6:correction=2'd0;\n    6'd7:correction=2'd0;\n    6'd8:correction=2'd0;\n    6'd9:correction=2'd0;\n    6'd10:correction=2'd0;\n    6'd11:correction=2'd0;\n    6'd12:correction=2'd0;\n    6'd13:correction=2'd1;\n    6'd14:correction=2'd1;\n    6'd15:correction=2'd1;\n    6'd16:correction=2'd1;\n    6'd17:correction=2'd1;\n    6'd18:correction=2'd1;\n    6'd19:correction=2'd1;\n    6'd20:correction=2'd1;\n    6'd21:correction=2'd1;\n    6'd22:correction=2'd1;\n    6'd23:correction=2'd1;\n    6'd24:correction=2'd1;\n    6'd25:correction=2'd1;\n    6'd26:correction=2'd2;\n    6'd27:correction=2'd2;\n    6'd28:correction=2'd2;\n    6'd29:correction=2'd2;\n    6'd30:correction=2'd2;\n    6'd31:correction=2'd2;\n    6'd32:correction=2'd2;\n    6'd33:correction=2'd2;\n    6'd34:correction=2'd2;\n    6'd35:correction=2'd2;\n    6'd36:correction=2'd2;\n    6'd37:correction=2'd2;\n    6'd38:correction=2'd2;\n    6'd39:correction=2'd3;\n    6'd40:correction=2'd3;\n    6'd41:correction=2'd3;\n    6'd42:correction=2'd3;\n    6'd43:correction=2'd3;\n    default:correction=0;endcase\n   div13_finish=seed[11:4]+8'(correction);\n  end\n endfunction\n function automatic [10:0] div5_seed(input [4:0] hi);begin case(hi)\n  5'd0:div5_seed=11'd0;\n  5'd1:div5_seed=11'd50;\n  5'd2:div5_seed=11'd100;\n  5'd3:div5_seed=11'd153;\n  5'd4:div5_seed=11'd203;\n  5'd5:div5_seed=11'd256;\n  5'd6:div5_seed=11'd306;\n  5'd7:div5_seed=11'd356;\n  5'd8:div5_seed=11'd409;\n  5'd9:div5_seed=11'd459;\n  5'd10:div5_seed=11'd512;\n  5'd11:div5_seed=11'd562;\n  5'd12:div5_seed=11'd612;\n  5'd13:div5_seed=11'd665;\n  5'd14:div5_seed=11'd715;\n  5'd15:div5_seed=11'd768;\n  5'd16:div5_seed=11'd818;\n  5'd17:div5_seed=11'd868;\n  5'd18:div5_seed=11'd921;\n  5'd19:div5_seed=11'd971;\n  5'd20:div5_seed=11'd1024;\n  5'd21:div5_seed=11'd1074;\n  5'd22:div5_seed=11'd1124;\n  5'd23:div5_seed=11'd1177;\n  5'd24:div5_seed=11'd1227;\n  5'd25:div5_seed=11'd1280;\n  5'd26:div5_seed=11'd1330;\n  5'd27:div5_seed=11'd1380;\n  5'd28:div5_seed=11'd1433;\n  5'd29:div5_seed=11'd1483;\n  5'd30:div5_seed=11'd1536;\n  5'd31:div5_seed=11'd1586;\n  default:div5_seed=0;endcase end endfunction\n function automatic [7:0] div5_finish(input [10:0] seed,input [4:0] lo);\n  reg [5:0] residual;reg [2:0] correction;begin\n   residual=6'(seed[2:0])+6'(lo);\n   case(residual)\n    6'd0:correction=3'd0;\n    6'd1:correction=3'd0;\n    6'd2:correction=3'd0;\n    6'd3:correction=3'd0;\n    6'd4:correction=3'd0;\n    6'd5:correction=3'd1;\n    6'd6:correction=3'd1;\n    6'd7:correction=3'd1;\n    6'd8:correction=3'd1;\n    6'd9:correction=3'd1;\n    6'd10:correction=3'd2;\n    6'd11:correction=3'd2;\n    6'd12:correction=3'd2;\n    6'd13:correction=3'd2;\n    6'd14:correction=3'd2;\n    6'd15:correction=3'd3;\n    6'd16:correction=3'd3;\n    6'd17:correction=3'd3;\n    6'd18:correction=3'd3;\n    6'd19:correction=3'd3;\n    6'd20:correction=3'd4;\n    6'd21:correction=3'd4;\n    6'd22:correction=3'd4;\n    6'd23:correction=3'd4;\n    6'd24:correction=3'd4;\n    6'd25:correction=3'd5;\n    6'd26:correction=3'd5;\n    6'd27:correction=3'd5;\n    6'd28:correction=3'd5;\n    6'd29:correction=3'd5;\n    6'd30:correction=3'd6;\n    6'd31:correction=3'd6;\n    6'd32:correction=3'd6;\n    6'd33:correction=3'd6;\n    6'd34:correction=3'd6;\n    6'd35:correction=3'd7;\n    default:correction=0;endcase\n   div5_finish=seed[10:3]+8'(correction);\n  end\n endfunction\n"
chunks=[]
def add(name,code,material=False):
 if material:code='if(MATERIAL_SAMPLE==0)begin\n'+code+'\nend'
 chunks.append((name,code))
add('pane selection',old[old.index("  sx=32'(x)"):old.index('  // Soft warm rim')])
add('pane local coordinates','pane_x=sx-px;pane_y=sy-py;')
pane_shapes=[('pane_hit',0,28),('halo_outer',-7,35),('halo_middle',-4,32),('halo_inner',-2,30),('pane_bevel',1,27)]
functions+='''\n function automatic [12:0] round_geometry(input signed [12:0] sx,sy,x0,y0,w,h,r);
 reg [5:0] dx,dy;begin
 dx=6'(sx<x0+r?x0+r-sx:sx>=x0+w-r?sx-(x0+w-r-1):0);
 dy=6'(sy<y0+r?y0+r-sy:sy>=y0+h-r?sy-(y0+h-r-1):0);
 round_geometry={sx>=x0 && sx<x0+w && sy>=y0 && sy<y0+h,dx,dy};
 end endfunction
 function automatic round_finish(input [12:0] geometry,input [5:0] radius);
 reg [6:0] boundary;begin boundary=circle_limit(radius,geometry[11:6]);round_finish=geometry[12] && boundary[6] && geometry[5:0]<=boundary[5:0];end endfunction
'''
add('pane corner geometry','\n'.join(f'{name}_geometry=round_geometry(pane_x,pane_y,{off},{off},pw-({2*off}),ph-({2*off}),{radius});' for name,off,radius in pane_shapes))
add('pane masks','''
 pane_hit=rounded(pane_x,pane_y,0,0,pw,ph,28);
 halo_outer=rounded(pane_x,pane_y,-7,-7,pw+14,ph+14,35);
 halo_middle=rounded(pane_x,pane_y,-4,-4,pw+8,ph+8,32);
 halo_inner=rounded(pane_x,pane_y,-2,-2,pw+4,ph+4,30);
 pane_bevel=!rounded(pane_x,pane_y,1,1,pw-2,ph-2,27);
 pane_right=pw-1-pane_x;pane_bottom=ph-1-pane_y;
 ''')
chunks[-1]=(chunks[-1][0],'\n'.join(f'{name}={"!" if name=="pane_bevel" else ""}round_finish({name}_geometry,6\'d{radius});' for name,off,radius in pane_shapes)+'\npane_right=pw-1-pane_x;pane_bottom=ph-1-pane_y;')
add('pane color and edge distances','''
 if(halo_outer)begin rr=rr+3;gg=gg+2;bb=bb+1;end
 if(halo_middle)begin rr=rr+5;gg=gg+4;bb=bb+2;end
 if(halo_inner)begin rr=rr+7;gg=gg+5;bb=bb+3;end
 if(pane_hit)begin
  edge_depth=pane_y;if(pane_bottom<edge_depth)edge_depth=pane_bottom;
  horizontal_edge=pane_x;if(pane_right<horizontal_edge)horizontal_edge=pane_right;
  rr=(fr*6+br+221)/8;gg=(fg*6+bg+225)/8;bb=(fb*6+bl+225)/8;
 end''')
add('nearest pane edge and material sum','''
 if(pane_hit && horizontal_edge<edge_depth)edge_depth=horizontal_edge;
 channel_sum=rr+gg+bb;
 sx_div13_seed=div13_seed(pane_x[10:5]);ox_div13_seed=div13_seed(pane_right[10:5]);
 sy_div5_seed=div5_seed(pane_y[9:5]);oy_div5_seed=div5_seed(pane_bottom[9:5]);

 case(pw)
 1872:begin center_upper=1123;center_lower=748;end
 724:begin center_upper=434;center_lower=289;end
 392:begin center_upper=235;center_lower=156;end
 928:begin center_upper=556;center_lower=371;end
 1320:begin center_upper=792;center_lower=528;end
 default:begin center_upper=0;center_lower=0;end
 endcase
 ''')
add('material coordinate quotients','''
 // These quotients are consumed only for pane_hit: distances are nonnegative.
 sx_part=13'(div13_finish(sx_div13_seed,pane_x[4:0]));sy_part=13'(div5_finish(sy_div5_seed,pane_y[4:0]));
 ox_part=13'(div13_finish(ox_div13_seed,pane_right[4:0]));oy_part=13'(div5_finish(oy_div5_seed,pane_bottom[4:0]));
 glint_center=sy<py+5?px+center_upper+dx:px+center_lower+dy;
 if(pane_hit)begin absorption=clamp($signed({1'b0,channel_sum/10'd3})-139,0,120);rim=clamp(13-edge_depth,0,13);end''')
add('reflection bounds','''
 if(pane_hit)begin
  rr=rr-absorption;gg=gg-absorption;bb=bb-absorption;
  rim=32'(rim_light(4'(rim)));
  shine=clamp(42-sx_part-sy_part,0,42);opposed=clamp(34-ox_part-oy_part,0,34);
  glint_distance=sx-glint_center;
 end''')
add('reflection mix preparation','if(pane_hit)begin light=shine+opposed;glint=clamp(80-ab(glint_distance)/2,0,80);end')
add('reflection component scalars','if(pane_hit)begin light_third=light[6:0]/7\'d3;rim_green=(rim*5)/2;end')
add('reflection mix','''if(pane_hit)begin
 rr=rr+rim*3+light_third;gg=gg+rim_green+light_third;bb=bb+rim*2+light/4;
end''')
add('bevel glint','''if(pane_hit && (sy<py+5 || sy>=py+ph-5))begin
 rr=rr+glint/2;gg=gg+glint*3/8;bb=bb+glint/4;
end''')
add('bevel edge','''if(pane_hit)begin
 if(pane_bevel)begin rr=(rr+255)/2;gg=(gg+246)/2;bb=(bb+222)/2;end
 shade=clamp(52-(sy-py),0,52)/8;
end''')
add('caption absorption','if(pane_hit)begin rr=rr-shade;gg=gg-shade;bb=bb-shade;end')
begin=old.index('  if(MATERIAL_SAMPLE==0)begin')+len('  if(MATERIAL_SAMPLE==0)begin')
end=old.index('  // Two physical keyboards')
wells=[(42,186,688,274,18),(782,186,688,274,18),(1522,186,356,282,18),(42,550,1836,176,18),(42,830,892,208,18),(986,830,892,208,18),(24,752,1872,24,12)]
well_masks='\n'.join(f'well_hits[{i}]=rounded(sx,sy,{",".join(map(str,shape))});' for i,shape in enumerate(wells))
sound_masks='\n'.join(f'sound_hits[{i}]=rounded(sx,sy,{54+i*12},{76-(25 if i==2 else 17 if i in [1,3] else 8)},7,{50 if i==2 else 34 if i in [1,3] else 16},3);' for i in range(5))
add('plot well and header masks',well_masks+'\n'+sound_masks+'\nheader_divider=sy>=48 && sy<105 && (sx==430 || sx==710 || sx==950 || sx==1200 || sx==1510);',True)
add('plot wells and header','''if((|well_hits[5:0]) || (guide_mode && well_hits[6]))begin
 rr=fr*3/8+26;gg=fg*3/8+30;bb=fb*3/8+30;end
 if(header_divider)begin rr=109;gg=134;bb=150;end
 if(|sound_hits)begin rr=180;gg=244;bb=238;end''',True)
from display_key_pipeline_20261021 import add_keys
add_keys(add)
voice_start=old.index('  // 32 actual voices')
meter_start=old.index('  // Linear input level meters')
add('voice shape masks','\n'.join(f'voice_hits[{i}]=rounded(sx,sy,{1192+i%8*27},{226+i//8*41},21,30,3);' for i in range(32)),True)
add('voice activity','''if(|voice_hits)begin
 rr=114;gg=133;bb=134;
 if(status_live && status_data[4] && |(voice_hits & status_data[50+:32]))begin rr=176;gg=246;bb=220;end
 end''',True)
meter_end=old.index('  rr=clamp(rr,0,255);')
meters=old[meter_start:meter_end];assert meters.rstrip().endswith('end\n  end')
meters=meters.rstrip()[:-len('  end')]
meter_hits=[];meter_low=[];meter_high=[]
for i in range(16):
 for left,level in [(1424,434),(1444,442)]:
  hit=f'(sx>={left} && sx<{left+13} && sy>={414-i*12} && sy<{422-i*12})'
  meter_hits.append(hit)
  (meter_high if i>=12 else meter_low).append(f'({hit} && status_data[{level}+:8]>8\'d{i*16})')
add('meter masks','meter_hit='+ ' || '.join(meter_hits)+';\nmeter_low='+ ' || '.join(meter_low)+';\nmeter_high='+ ' || '.join(meter_high)+';',True)
add('level meters','''if(meter_hit)begin rr=57;gg=75;bb=74;end
 if(status_live && status_data[6])begin
 if(meter_low)begin rr=163;gg=239;bb=207;end
 if(meter_high)begin rr=243;gg=229;bb=174;end
 end''',True)
add('channel clipping','rr=clamp(rr,0,255);gg=clamp(gg,0,255);bb=clamp(bb,0,255);')
fields={}
def group(width,names,signed=True):
 for n in names.split(','):fields[n]=('logic '+('signed ' if signed else '')+f'[{width-1}:0]')
group(13,'sx,sy,px,py,pw,ph,light,kx,base,edge_depth,sx_part,sy_part,ox_part,oy_part,center_upper,center_lower,fraction,key_x,pane_x,pane_y,horizontal_edge,pane_right,pane_bottom,glint_center,glint_distance')
group(7,'light_third,rim_green',False)
group(8,'key_top_edge,key_bottom_edge',False)
group(12,'sx_div13_seed,ox_div13_seed',False)
group(11,'sy_div5_seed,oy_div5_seed',False)
group(11,'nr_abs,ng_abs,nb_abs',False)
group(10,'channel_sum',False);group(6,'black_mask',False)
group(12,'rr,gg,bb,nr,ng,nb,nlight')
group(10,'dx,dy,rim')
group(8,'shine,opposed,shade,glint')
group(2,'key_kind',False);group(9,'absorption');group(5,'k');group(7,'idx');group(3,'board')
group(8,'br,bg,bl,fr,fg,fb',False);group(3,'amount',False)
group(13,','.join(name+'_geometry' for name,_,_ in pane_shapes),False)
group(32,'voice_hits',False)
group(7,'well_hits',False);group(5,'sound_hits',False)
for n in ['header_divider','meter_hit','meter_low','meter_high']:fields[n]='logic'
for n in ['pane_hit','work_hit','pressed','status_live','guide_inner','guide_marker','halo_outer','halo_middle','halo_inner','pane_bevel','white_hit','upper_hit','nr_negative','ng_negative','nb_negative']:fields[n]='logic'
fields['status_data']='logic [511:0]';fields['key_trails']='logic [95:0]'
metadata=scene[scene.index(' wire mode_valid='):scene.index(' reg pressed;')]
metadata=re.sub(r'\b(status_live|status_data)\b',lambda m:'incoming.'+m[0],metadata)
stages=[]
for n,(name,code) in enumerate(chunks):
 colors="  br=32'(sharp_rgb[23:16]);bg=32'(sharp_rgb[15:8]);bl=32'(sharp_rgb[7:0]);\n  fr=32'(frost_rgb[23:16]);fg=32'(frost_rgb[15:8]);fb=32'(frost_rgb[7:0]);\n  rr=br;gg=bg;bb=bl;"
 if n==0:
  assert colors in code
  code=code.replace(colors,'if(BACKGROUND_LATENCY==0)begin\n'+colors+'\nend')
 elif n in [1,2,3,4]:code=f'if(BACKGROUND_LATENCY=={n})begin\n'+colors+'\nend\n'+code
 code=re.sub(r'\b('+ '|'.join(fields)+r')\b',lambda m:'d.'+m[0],code)
 code=code.replace('d.key_trails[','incoming_trails[').replace('d.status_data[','incoming_status[')
 stages.append(f''' begin:STAGE_{n} // {name}
  pixel_state incoming,d,q;
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming={"input_state" if n==0 else f"STAGE_{n-1}.q"};
{metadata}
  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys{" or x or y or drift_x or drift_y or sharp_rgb or frost_rgb" if n==0 else " or sharp_rgb or frost_rgb" if n in [1,2,3,4] else ""}) begin
   d=incoming;
{code}
  end
  always @(posedge clk)q<=d;
 end''')
header=old[:old.index(' function automatic')]
header=header.replace('output reg [23:0] rgb','output wire [23:0] rgb').replace('input wire [23:0] sharp_rgb,frost_rgb);','input wire [23:0] sharp_rgb,frost_rgb,input wire clk);')
header=header.replace('input wire clk);','input wire clk) /* synthesis syn_srlstyle="distributed_ram" */;')
header=header.replace('parameter MATERIAL_SAMPLE=0','parameter MATERIAL_SAMPLE=0,parameter BACKGROUND_LATENCY=0')
generated=header+'\n'+functions+f'\n localparam PIPE_STAGES={len(chunks)};\n typedef struct packed {{\n'
generated+='\n'.join(f'  {t} {n};' for n,t in fields.items())+'\n } pixel_state;\n'
generated+=''' pixel_state input_state;
 always @* begin input_state='0;input_state.status_data=status_data;input_state.status_live=status_live;input_state.key_trails=key_trails;end
 generate
'''+ '\n'.join(stages)+'''
 endgenerate
'''+f' assign rgb={{STAGE_{len(chunks)-1}.q.rr[7:0],STAGE_{len(chunks)-1}.q.gg[7:0],STAGE_{len(chunks)-1}.q.bb[7:0]}};\nendmodule\n'
# Preserve the exact integer easing samples. One registered ROM lookup replaces
# the long combinational curve; the only changed sample is inside vertical blank.
def eased(phase,half):
 t=phase if phase<=half else half*2-phase
 u=(t*255//half)&255;square=(u*u)&65535;curve=(square*(765-u*2))&((1<<26)-1)
 return (((curve>>16)*192)//253-96)&1023
for axis,half,period in [('x',330,660),('y',435,870)]:
 (R/f'assets/display_drift_{axis}.hex').write_text(''.join(f'{eased(i%period,half):03x}\n' for i in range(1024)))
generated+='''// Exact 22s/29s motion. ROMs settle during vertical blank before active video.
module visual_light_motion(input wire clk,rst_n,frame_tick,
 output reg signed [9:0] drift_x,drift_y);
 reg [9:0] phase_x,phase_y;
 (* syn_romstyle="block_rom" *) reg [9:0] easing_x[0:1023],easing_y[0:1023];
 initial begin
  $readmemh("assets/display_drift_x.hex",easing_x);
  $readmemh("assets/display_drift_y.hex",easing_y);
 end
 always @(posedge clk)begin drift_x<=easing_x[phase_x];drift_y<=easing_y[phase_y];end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin phase_x<=0;phase_y<=217;end
 else if(frame_tick)begin
  phase_x<=phase_x==659?10'd0:phase_x+1'b1;
  phase_y<=phase_y==869?10'd0:phase_y+1'b1;
 end
endmodule
`default_nettype wire
'''
from display_well_geometry_20261023 import retime_wells
generated=retime_wells(generated)
from display_routed_fixes_20261023 import register_shifts
generated=register_shifts(generated)
from display_hybrid_shift_20261023 import protect_scene_voices
generated=protect_scene_voices(generated)
from display_voice_pixel_20261023 import select_voice_pixel
from display_pane_geometry_20261023 import prepare_pane_geometry
generated=prepare_pane_geometry(select_voice_pixel(generated))
p.write_text(generated)
(A/'SCENE_PIPELINE.json').write_text(json.dumps({'stages':len(chunks),'chunks':[name for name,_ in chunks]},indent=2))
print('Generated',len(chunks),'exact scene pipeline stages')
