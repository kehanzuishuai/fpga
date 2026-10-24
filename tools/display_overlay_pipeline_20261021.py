"""Exact plot-overlay arithmetic, prepared before the final RGB selection."""
def pipeline_overlay(s):
    for divisor in [586,587]:
        reciprocal=((1<<25)+divisor-1)//divisor
        assert all((n*reciprocal)>>25==n//divisor for n in range(43951))
    assert all((n*38837)>>22==n//108 for n in range(29581))
    declaration='''
 // Four arithmetic stages; inserted at descriptor stage4 without extra pixels.
 reg [11:0] overlay_x1,overlay_y1,grid_x1,grid_y1,env_x1,env_y1,phase_x1,phase_y1;
 reg [9:0] gradient_pos1;reg [1:0] gradient_region1,gradient_region2,gradient_region3;
 reg [16:0] gradient_r2,gradient_g2,gradient_b2;
 reg [32:0] gradient_r3,gradient_g3,gradient_b3;
 localparam [32:0] GRADIENT_RECIP586=((33'd1<<25)+33'd585)/33'd586;
 localparam [32:0] GRADIENT_RECIP587=((33'd1<<25)+33'd586)/33'd587;
 reg [14:0] spectrum_height3;reg [8:0] spectrum_height4;
 reg [11:0] spectrum_distance2,spectrum_distance3,spectrum_distance4;
 reg spectrum_region2,spectrum_region3,spectrum_region4,grid2,grid3,grid4,spectrum_bar5;
 reg [23:0] spectrum_color4;
 always @(posedge clk)begin
  overlay_x1<=draw_x;overlay_y1<=draw_y;
  grid_x1<=draw_x-12'd80;grid_y1<=draw_y-12'd220;
  env_x1<=draw_x-12'd836;env_y1<=draw_y-12'd232;
  phase_x1<=draw_x-12'd1540;phase_y1<=draw_y-12'd198;
  if(draw_x<666)begin gradient_region1<=0;gradient_pos1<=10'(draw_x-12'd80);end
  else if(draw_x<1253)begin gradient_region1<=1;gradient_pos1<=10'(draw_x-12'd666);end
  else begin gradient_region1<=2;gradient_pos1<=10'(draw_x-12'd1253);end
  gradient_region2<=gradient_region1;
  case(gradient_region1)
   0:begin gradient_r2<=17'(gradient_pos1)*17'd28;gradient_g2<=17'(gradient_pos1)*17'd29;gradient_b2<=17'(gradient_pos1)*17'd46;end
   1:begin gradient_r2<=17'(gradient_pos1)*17'd75;gradient_g2<=17'(gradient_pos1)*17'd9;gradient_b2<=17'(gradient_pos1)*17'd18;end
   default:begin gradient_r2<=17'(gradient_pos1)*17'd7;gradient_g2<=17'(gradient_pos1)*17'd28;gradient_b2<=17'(gradient_pos1)*17'd11;end
  endcase
  grid2<=
   (overlay_x1>=80 && overlay_x1<704 && overlay_y1>=220 && overlay_y1<=424 && (grid_x1%12'd78==0 || grid_y1%12'd51==0)) ||
   (overlay_x1>=836 && overlay_x1<=1151 && overlay_y1>=232 && overlay_y1<=432 && (env_x1%12'd63==0 || env_y1%12'd50==0)) ||
   (overlay_x1>=1540 && overlay_x1<=1860 && overlay_y1>=198 && overlay_y1<454 && (phase_x1[5:0]==0 || phase_y1[5:0]==0)) ||
   (overlay_x1>=80 && overlay_x1<1840 && overlay_y1>=584 && overlay_y1<=700 &&
    (overlay_x1==80 || overlay_x1==373 || overlay_x1==666 || overlay_x1==960 || overlay_x1==1253 || overlay_x1==1546 || overlay_x1==1839 || (overlay_y1-12'd584)%12'd29==0));
  spectrum_distance2<=12'd700-overlay_y1;
  spectrum_region2<=overlay_x1>=80 && overlay_x1<1840 && overlay_y1>=584 && overlay_y1<700 && grid_x1%12'd7!=6;
  gradient_region3<=gradient_region2;
  if(gradient_region2==0)begin gradient_r3<=33'(gradient_r2)*GRADIENT_RECIP586;gradient_g3<=33'(gradient_g2)*GRADIENT_RECIP586;gradient_b3<=33'(gradient_b2)*GRADIENT_RECIP586;end
  else begin gradient_r3<=33'(gradient_r2)*GRADIENT_RECIP587;gradient_g3<=33'(gradient_g2)*GRADIENT_RECIP587;gradient_b3<=33'(gradient_b2)*GRADIENT_RECIP587;end
  grid3<=grid2;grid4<=grid3;
  // The exact FFT address pipeline adds two clocks before this sample.
  spectrum_height3<=15'(spectrum_sample)*15'd116;
  spectrum_height4<=9'((31'(spectrum_height3)*31'd38837)>>22);
  spectrum_distance3<=spectrum_distance2;spectrum_region3<=spectrum_region2;
  spectrum_distance4<=spectrum_distance3;spectrum_region4<=spectrum_region3;
  spectrum_bar5<=spectrum_region4 && spectrum_distance4<{3'd0,spectrum_height4};
  case(gradient_region3)
   0:spectrum_color4<={8'(8'd142+8'(gradient_r3>>25)),8'(8'd210+8'(gradient_g3>>25)),8'(8'd249-8'(gradient_b3>>25))};
   1:spectrum_color4<={8'(8'd170+8'(gradient_r3>>25)),8'(8'd239-8'(gradient_g3>>25)),8'(8'd203-8'(gradient_b3>>25))};
   default:spectrum_color4<={8'(8'd245+8'(gradient_r3>>25)),8'(8'd230-8'(gradient_g3>>25)),8'(8'd185+8'(gradient_b3>>25))};
  endcase
 end
'''
    # Grid locations are finite, exact integer coordinates in the visible wells.
    eq=lambda name,values:'('+ ' || '.join(f'{name}==12\'d{v}' for v in values)+')'
    grid='''  grid2<=
   (overlay_x1>=80 && overlay_x1<704 && overlay_y1>=220 && overlay_y1<=424 && (__WX__ || __WY__)) ||
   (overlay_x1>=836 && overlay_x1<=1151 && overlay_y1>=232 && overlay_y1<=432 && (__EX__ || __EY__)) ||
   (overlay_x1>=1540 && overlay_x1<=1860 && overlay_y1>=198 && overlay_y1<454 && (phase_x1[5:0]==0 || phase_y1[5:0]==0)) ||
   (overlay_x1>=80 && overlay_x1<1840 && overlay_y1>=584 && overlay_y1<=700 && (__SX__ || __SY__));
'''
    for token,name,values in [('WX','overlay_x1',range(80,704,78)),('WY','overlay_y1',range(220,425,51)),
        ('EX','overlay_x1',range(836,1152,63)),('EY','overlay_y1',range(232,433,50)),
        ('SX','overlay_x1',[80,373,666,960,1253,1546,1839]),('SY','overlay_y1',range(584,701,29))]:
        grid=grid.replace('__'+token+'__',eq(name,values))
    a=declaration.index('  grid2<=');b=declaration.index('  spectrum_distance2<=',a)
    declaration=declaration[:a]+grid+declaration[b:]
    marker=' pixel_info spectrum_ready,waveform_ready;'
    assert marker in s
    s=s.replace(marker,declaration+''' pixel_info overlay_ready,bar_ready;
 always @* begin overlay_ready=info_pipe[3];overlay_ready.plot_grid=grid4;overlay_ready.spectrum_color=spectrum_color4;end
 always @* begin bar_ready=info_pipe[4];bar_ready.spectrum_bar=spectrum_bar5;end
'''+marker)
    s=s.replace('if(delay_pixel==5)', 'if(delay_pixel==4)info_pipe[delay_pixel]<=overlay_ready;else if(delay_pixel==5)info_pipe[delay_pixel]<=bar_ready;else if(delay_pixel==6)')
    a=s.index('   if((aligned.x>=80');b=s.index('begin\n    base_red<=scene_color',a)
    s=s[:a]+'   if(aligned.plot_grid)'+s[b:]
    a=s.index('   if(aligned.initialized && aligned.x>=80');b=s.index('\n  end\n end\n initial if(LOGN',a)
    s=s[:a]+'''   if(aligned.initialized && aligned.spectrum_bar)begin
    {base_red,base_green,base_blue}<=aligned.spectrum_color;
   end'''+s[b:]
    return s
