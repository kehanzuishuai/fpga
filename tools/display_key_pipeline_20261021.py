"""One exact key shader shared across both boards; preserve overlap priority."""
def add_keys(add):
 add('keyboard local coordinates','''
 board=sx<960?0:1;base=sx<960?48:992;
 key_x=sx-base;work_hit=0;key_kind=0;kx=0;idx=0;
 ''',True)
 add('white key slot','''
 fraction=key_x[9:0]%10'd96;k=key_x[9:0]/10'd96;
 ''',True)
 # All black candidates are disjoint. K16 has the highest original draw order.
 masks='''
 white_hit=key_x>=0 && key_x<864 && sy>=846 && sy<1006 && rounded(fraction,sy,1,846,93,160,6);
 upper_hit=rounded(key_x,sy,818,848,42,38,6);
 '''
 for n,gap in enumerate([1,2,4,5,7,8]):
  left=gap*96-26
  masks+=f'black_mask[{n}]=rounded(key_x,sy,{left},846,52,102,5);\n'
 add('key shape masks',masks,True)
 black_x=' | '.join(f'(black_mask[{n}]?13\'sd{gap*96-26}:13\'sd0)' for n,gap in enumerate([1,2,4,5,7,8]))
 black_idx=' | '.join(f'(black_mask[{n}]?7\'sd{index}:7\'sd0)' for n,index in enumerate([1,3,6,8,10,13]))
 select=f'''work_hit=white_hit || (|black_mask) || upper_hit;
 if(upper_hit)begin key_kind=2;kx=818;idx=board*16+15;end
 else if(|black_mask)begin key_kind=1;kx={black_x};idx=board*16+({black_idx});end
 else begin key_kind=0;kx=k*96+1;idx=board*16+white_key(k);end
 key_x=key_x-kx;
 '''
 add('visible key selection',select,True)
 add('physical key and release amount','''if(work_hit)begin
 pressed=shown_keys[idx];
 amount=pressed?7:!guide_mode && !auto_mode && status_live && status_data[0]?32'(key_trails[idx*3+:3]):0;
 end''',True)
 add('key shade quotients','''if(work_hit)begin
 if(key_kind==0)begin sx_part=key_abs(8'(key_x-46))/8'd5;sy_part=8'(sy-846)/8'd20;end
 else if(key_kind==1)begin sx_part=key_abs(8'(key_x-26))/8'd3;sy_part=8'(sy-846)/8'd10;end
 else begin sx_part=8'(sy-848)>>1;sy_part=0;end
 light=key_x;if(92-key_x<light)light=92-key_x;
 key_top_edge=8'(sy)-8'd78;key_bottom_edge=8'd237-8'(sy);
 end''',True)
 add('key shade and vertical lip distance','''if(work_hit)begin
 shade=clamp(sx_part+sy_part,0,18);
 light={5'd0,min_key_edges(light[7:0],key_top_edge,key_bottom_edge)};
 end''',True)
 add('key base color','''if(work_hit)begin
 if(key_kind==0)begin rr=251-shade;gg=249-shade;bb=245-shade;end
 else if(key_kind==1)begin rr=38-shade;gg=48-shade;bb=55-shade;end
 else begin rr=119-shade;gg=148-shade;bb=173-shade;end
 nlight=clamp(5-light,0,5)*amount;
 end''',True)
 add('key tint products','''if(work_hit)begin
 if(key_kind==0)begin
 nr=(158-shade-rr)*amount;ng=((board==0?226:244)-shade-gg)*amount;nb=((board==0?249:212)-shade-bb)*amount;
 end else if(key_kind==1)begin
 nr=((board==0?115:105)-rr)*amount;ng=((board==0?182:200)-gg)*amount;nb=((board==0?227:189)-bb)*amount;
 end else begin
 nr=((board==0?161:157)-rr)*amount;ng=((board==0?222:236)-gg)*amount;nb=((board==0?248:220)-bb)*amount;
 end
 end''',True)
 add('key tint magnitudes','''if(work_hit)begin
 nr_negative=nr<0;ng_negative=ng<0;nb_negative=nb<0;
 nr_abs=nr_negative?-nr:nr;ng_abs=ng_negative?-ng:ng;nb_abs=nb_negative?-nb:nb;
 end''',True)
 add('key tint quotients','''if(work_hit)begin
 nr_abs=unsigned_divide7(nr_abs);ng_abs=unsigned_divide7(ng_abs);nb_abs=unsigned_divide7(nb_abs);light=unsigned_divide7({5'd0,6'(nlight)});
 end''',True)
 add('key tint addition','''if(work_hit)begin
 rr=nr_negative?rr-nr_abs:rr+nr_abs;gg=ng_negative?gg-ng_abs:gg+ng_abs;bb=nb_negative?bb-nb_abs:bb+nb_abs;
 end''',True)
 add('white key inner light','''if(work_hit && key_kind==0)begin
 rr=rr+light*7;gg=gg+light*5;bb=bb+light*4;
 end''',True)
 add('key bevel','''if(work_hit)begin
 if(key_kind==0 && (key_x==1 || sy==847))begin rr=239;gg=252;bb=255;end
 if(key_kind==1 && (key_x==1 || sy==847))begin rr=93;gg=112;bb=131;end
 if(key_kind==2 && !rounded(key_x,sy,1,849,40,36,5))begin rr=169;gg=208;bb=230;end
 end''',True)
 add('key lower edge','''if(work_hit)begin
 if(key_kind==0 && sy>=1001)begin rr=(13'(rr)*13'sd7)>>>3;gg=(13'(gg)*13'sd7)>>>3;bb=(13'(bb)*13'sd7)>>>3;end
 if(key_kind==1 && sy>=942)begin rr=rr>>>1;gg=gg>>>1;bb=bb>>>1;end
 end''',True)
 add('guidance key interior and marker','''if(work_hit)begin
 if(key_kind==0)begin
  guide_inner=rounded(key_x,sy,4,850,85,152,2);
  guide_marker=key_x>=42 && key_x<50 && sy>=990 && sy<997;
 end else if(key_kind==1)begin
  guide_inner=rounded(key_x,sy,4,850,44,94,1);
  guide_marker=key_x>=22 && key_x<30 && sy>=932 && sy<939;
 end else begin
  guide_inner=rounded(key_x,sy,4,852,34,30,2);
  guide_marker=key_x>=17 && key_x<25 && sy>=870 && sy<877;
 end
 end''',True)
 add('guidance key colors','''if(work_hit && guide_mode && target_valid)begin
 if(physical[idx] && !targets[idx])begin rr=222;gg=139;bb=131;end
 if(targets[idx] && !guide_inner)begin rr=255;gg=224;bb=159;end
 if(targets[idx] && guide_marker)begin rr=255;gg=221;bb=148;end
 end''',True)
 for board in range(2):
  add(f'board {board} identity',f'''if(rounded(sx,sy,{52+board*944},811,12,12,6))begin rr=status_live && status_data[0]?128:117;gg=status_live && status_data[0]?244:132;bb=status_live && status_data[0]?{224 if board==0 else 199}:143;end''',True)
