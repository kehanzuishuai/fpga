`default_nettype none
// Native 1920x1080 coordinates. No logical-pixel upscaling.
// X/Y is square, DC-removed and normalized jointly. No changes to audio path.
(* syn_srlstyle="registers" *)
module visual_renderer #(parameter LOGN=11,SAMPLE_RATE=48000)(
 input wire clk,rst_n,input wire [11:0] x,y,input wire de,hs,vs,blank_start,
 input wire wave_pending,spec_pending,input wire [48:0] wave_data,input wire [36:0] spec_data,
 output wire [8:0] wave_addr,output wire [LOGN-2:0] spec_addr,
 output wire wave_release,output reg spec_release,
 output wire [7:0] red,green,blue,output reg out_de,out_hs,out_vs,input wire status_live,input wire [511:0] status_data
);
 // Keep the intended renderer/encoder boundary during whole-project mapping.
 (* syn_preserve=1,syn_keep=1 *) reg [7:0] rgb_red,rgb_green,rgb_blue;
 assign red=rgb_red;assign green=rgb_green;assign blue=rgb_blue;
 reg signed [15:0] wave[0:1023];reg [7:0] spectrum[0:511];
 reg wave_front,wave_back,wave_ready,wave_initialized;
 reg [2:0] state;
 localparam WAIT_BLANK=0,SPEC_COPY=4,SPEC_SCAN=5;
 reg [15:0] counter;reg primed,initialized;reg [7:0] pool_peak;
 reg [36:0] peak_power;reg [LOGN-2:0] peak_bin;reg [15:0] peak_hz;reg peak_valid;
 reg [1:0] spectrum_range,shrink_candidate;
 reg [1:0] shrink_count;
 reg [LOGN-2:0] highest_bin;
 wire [15:0] prev_count=counter-1'b1;
 wire new_peak=prev_count!=0 && spec_data>peak_power;
 // SCAN preparation clock uses the final registered peak bin.
 wire [15:0] candidate_hz=16'((64'(peak_bin)*64'(SAMPLE_RATE)+(64'd1<<(LOGN-1)))>>LOGN);
 // Second pass over the same frozen FFT: retain components within ~36dB of
 // the strongest non-DC bin. Two-bin margin, four Nyquist-quarter ranges.
 reg [24:0] significant_floor;
 // Peak stops changing before SCAN's first primed bin: one preparation clock
 // preserves the final COPY bin while removing a compare from the scan path.
 always @(posedge clk)significant_floor<=peak_power[36:12]!=0?peak_power[36:12]:25'd1;
 wire significant=prev_count!=0 && ((|spec_data[36:25]) || spec_data[24:0]>=significant_floor);
 // Factor the two-bit range selection outside the late significance mux.
 function automatic [1:0] range_for_bin(input [LOGN-2:0] bin);
 begin range_for_bin=bin<=((1<<(LOGN-3))-2)?2'd0:
  bin<=((1<<(LOGN-2))-2)?2'd1:bin<=(3*(1<<(LOGN-3))-2)?2'd2:2'd3;
 end endfunction
 wire [1:0] desired_range=significant?range_for_bin(prev_count[LOGN-2:0]):range_for_bin(highest_bin);
 function [7:0] power_height(input [36:0] p);
  integer k;begin
   // Mutually exclusive highest-one terms, combined as an OR tree. Constants
   // encode3*log2 directly, avoiding a37-way priority chain followed by*3.
   power_height=0;
   for(k=1;k<37;k=k+1)
    if(p[k] && (p>>(k+1))==0)power_height=power_height | 8'(k*3);
  end
 endfunction
 reg [7:0] spec_height;reg [15:0] pool_count;reg pool_valid;
 always @(posedge clk)begin spec_height<=power_height(spec_data);pool_count<=prev_count;end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)pool_valid<=0;else pool_valid<=state==SPEC_COPY && primed;
 assign spec_addr=counter[LOGN-2:0];
 wire [8:0] bar_index=9'(pool_count>>(LOGN-10));
 localparam [15:0] POOL_MASK=16'((1<<(LOGN-10))-1);
 wire pool_first=(pool_count & POOL_MASK)==0;
 wire pool_last=(pool_count & POOL_MASK)==POOL_MASK;
 wire [7:0] pool_value=(pool_first || spec_height>pool_peak)?spec_height:pool_peak;
 reg xy_start;wire xy_busy,xy_copy,xy_ready;wire [8:0] xy_copy_index;
 wire phase_pixel,xy_signal,xy_direct,xy_mixed;wire signed [5:0] xy_shift;
 wire [7:0] phase_x=8'(x-1572),phase_y=8'(y-198);
 wire [15:0] phase_read={phase_y,phase_x};
 visual_xy_plot #(.COORD_BITS(8),.SPAN(256)) xy_plot(.clk(clk),.rst_n(rst_n),.start(xy_start),.publish(blank_start),
  .sample_addr(wave_addr),.sample_data(wave_data),.sample_release(wave_release),.busy(xy_busy),
  .ready(xy_ready),.copy_valid(xy_copy),.copy_index(xy_copy_index),.pixel_addr(phase_read),.pixel(phase_pixel),
  .signal_valid(xy_signal),.direct_mode(xy_direct),.mixed_mode(xy_mixed),.scale_shift(xy_shift));
 reg signed [15:0] wave_sample,wave_previous,wave_sample_q,wave_next_q;
 reg [9:0] wave_fraction_q;
 reg [7:0] spectrum_sample,spectrum_sample_q;
 reg [11:0] stage_x,stage_y;reg stage_de,stage_hs,stage_vs;
 wire [23:0] sharp_rgb,frost_rgb;
 visual_background scenery(clk,x,y,sharp_rgb,frost_rgb);
 reg [11:0] draw_x,draw_y;reg draw_de,draw_hs,draw_vs;
 wire [11:0] local_wave_x=x>=80?x-12'd80:12'd0;
 // Exact index/remainder for all 4096 local X values. The four zero
 // fraction bits are reconstructed after the ROM, avoiding a wide divider.
 (* syn_romstyle="block_rom" *) reg [14:0] wave_position_rom[0:4095];
 reg [14:0] wave_position_q;
 initial $readmemh("assets/display_wave_position.hex",wave_position_rom);
 always @(posedge clk)wave_position_q<=wave_position_rom[local_wave_x];
 wire [8:0] wave_index=wave_position_q[14:6];
 wire [8:0] next_index=wave_index==511?9'd511:wave_index+9'd1;
 wire [11:0] spectrum_local_x=x>=80?x-12'd80:12'd0;
 reg [15:0] spectrum_numerator;reg [32:0] spectrum_reciprocal;
 always @(posedge clk)begin
  spectrum_numerator<=16'(spectrum_local_x)*(16'(spectrum_range)+16'd1)*16'd4;
  spectrum_reciprocal<=33'(spectrum_numerator)*33'd76261;
 end
 wire [8:0] spectrum_index=9'(spectrum_reciprocal>>22);
 always @(posedge clk)begin
  wave_sample_q<=wave[{wave_front,wave_index}];
  wave_next_q<=wave[{wave_front,next_index}];
  wave_fraction_q<={wave_position_q[5:0],4'd0};
  spectrum_sample_q<=spectrum[spectrum_index];
  wave_previous<=wave_sample;spectrum_sample<=spectrum_sample_q;
  if(xy_copy)wave[{wave_back,xy_copy_index}]<=wave_data[48:33];
  if(pool_valid && pool_last)spectrum[bar_index]<=pool_value;
 end
 // Five additional clocks relative to the original waveform result:
 // index ROM + products + sum + magnitude + reciprocal + restored sign.
 reg signed [26:0] wave_product_a,wave_product_b,wave_sum;
 wire [26:0] wave_absolute_bits;wire [15:0] wave_restored_bits;
 visual_conditional_negate #(.WIDTH(27),.GROUP_BITS(6)) magnitude_prefix(wave_sum,wave_sum[26],wave_absolute_bits);
 visual_conditional_negate #(.WIDTH(16),.GROUP_BITS(4)) restore_prefix(wave_reciprocal[41:26],wave_reciprocal_negative,wave_restored_bits);

 reg [20:0] wave_magnitude;reg wave_negative,wave_reciprocal_negative;
 reg [41:0] wave_reciprocal;
 always @(posedge clk)begin
  wave_product_a<=$signed(wave_sample_q)*$signed(11'd624-{1'b0,wave_fraction_q});
  wave_product_b<=$signed(wave_next_q)*$signed({1'b0,wave_fraction_q});
  wave_sum<=wave_product_a+wave_product_b;
  wave_magnitude<=wave_absolute_bits[24:4];wave_negative<=wave_sum[26];
  wave_reciprocal<=42'(wave_magnitude)*42'd1720741;wave_reciprocal_negative<=wave_negative;
  wave_sample<=wave_restored_bits;
 end
 wire signed [31:0] scaled_sample=($signed(wave_sample)*32'sd102)>>>15;
 wire signed [31:0] scaled_previous=($signed(wave_previous)*32'sd102)>>>15;
 reg [11:0] wave_y,wave_prev_y;
 always @(posedge clk)begin
  wave_y<=12'(32'sd322-scaled_sample);wave_prev_y<=12'(32'sd322-scaled_previous);
 end
 wire [11:0] wave_min=wave_y<wave_prev_y?wave_y:wave_prev_y;
 wire [11:0] wave_max=wave_y>wave_prev_y?wave_y:wave_prev_y;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=WAIT_BLANK;counter<=0;primed<=0;initialized<=0;pool_peak<=0;
  peak_power<=0;peak_bin<=0;peak_hz<=0;peak_valid<=0;xy_start<=0;spec_release<=0;
  spectrum_range<=0;shrink_count<=0;shrink_candidate<=0;highest_bin<=0;
  wave_front<=0;wave_back<=1;wave_ready<=0;wave_initialized<=0;
 end else begin
  xy_start<=0;spec_release<=0;
  // The final delayed bin is pooled on SCAN's unprimed first clock, before
  // publication. Native RAM decode and max pooling have separate registers.
  if(pool_valid)pool_peak<=pool_value;
  if(xy_copy && xy_copy_index==511)wave_ready<=1;
  if(blank_start && xy_ready)begin wave_front<=wave_back;wave_back<=wave_front;wave_initialized<=wave_ready;wave_ready<=0;end
  case(state)
   WAIT_BLANK:if(blank_start)begin
    if(wave_pending && (!xy_busy || xy_ready))xy_start<=1;
    counter<=0;primed<=0;peak_power<=0;peak_bin<=0;
    if(spec_pending)state<=SPEC_COPY;
   end
   SPEC_COPY:begin
    primed<=1;
    if(primed && new_peak)begin peak_power<=spec_data;peak_bin<=prev_count[LOGN-2:0];end
    if(counter==(1<<(LOGN-1)))begin
     peak_valid<=new_peak || peak_power!=0;
     counter<=0;primed<=0;highest_bin<=0;state<=SPEC_SCAN;
    end else counter<=counter+1'b1;
   end
   SPEC_SCAN:begin
    // Final COPY bin is already in peak_bin. Use the existing preparation
    // clock for Hz conversion; scan/release timing and final metadata agree.
    if(!primed)peak_hz<=candidate_hz;
    primed<=1;
    if(primed && significant)highest_bin<=prev_count[LOGN-2:0];
    if(counter==(1<<(LOGN-1)))begin
     // Grow immediately; shrink only after four consecutive matching snapshots.
     if(peak_power!=0)begin
      if(desired_range>spectrum_range)begin spectrum_range<=desired_range;shrink_count<=0;end
      else if(desired_range==spectrum_range)shrink_count<=0;
      else if(shrink_candidate!=desired_range)begin shrink_candidate<=desired_range;shrink_count<=1;end
      else if(shrink_count==3)begin spectrum_range<=desired_range;shrink_count<=0;end
      else shrink_count<=shrink_count+2'd1;
     end else shrink_count<=0;
     spec_release<=1;initialized<=1;state<=WAIT_BLANK;
    end else counter<=counter+1'b1;
   end
   default:state<=WAIT_BLANK;
  endcase
 end
 wire label_ink;wire [1:0] label_coverage;wire [23:0] label_color,scene_color;
 function automatic [9:0] text_weighted_sum(input [7:0] bg,fg,input [1:0] coverage);
  reg [9:0] b,f;begin
   b={2'b0,bg};f={2'b0,fg};
   case(coverage)
    0:text_weighted_sum=b+(b<<1)+10'd1;
    1:text_weighted_sum=(b<<1)+f+10'd1;
    2:text_weighted_sum=b+(f<<1)+10'd1;
    3:text_weighted_sum=f+(f<<1)+10'd1;
   endcase
  end
 endfunction
 function automatic [7:0] text_divide_three(input [9:0] rounded_sum);
  reg [19:0] product;begin
   // ceil(2^11/3)=683 gives the exact quotient for every sum in 0..766.
   product={10'd0,rounded_sum}*20'd683;text_divide_three=product[18:11];
  end
 endfunction
 wire signed [9:0] drift_x,drift_y;
 visual_light_motion lighting(clk,rst_n,blank_start,drift_x,drift_y);
 // Cosmetic release tail only: incoming key bits remain the physical truth.
 reg [95:0] key_trails;integer tail_key;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)key_trails<=0;
 else if(blank_start)begin
  for(tail_key=0;tail_key<32;tail_key=tail_key+1)begin
   if(!status_live || !status_data[0])key_trails[tail_key*3+:3]<=0;
   else if(status_data[18+tail_key])key_trails[tail_key*3+:3]<=7;
   else if(key_trails[tail_key*3+:3]>2)key_trails[tail_key*3+:3]<=key_trails[tail_key*3+:3]-3'd2;
   else key_trails[tail_key*3+:3]<=0;
  end
 end
 visual_scene #(.BACKGROUND_LATENCY(4)) scene(draw_x,draw_y,status_live,status_data,scene_color,drift_x,drift_y,key_trails,sharp_rgb,frost_rgb,clk);
 wire [31:0] env_index_full=draw_x<836?0:(32'(draw_x)-836)/21;
 wire [3:0] env_index=env_index_full>14?4'd14:env_index_full[3:0];
 wire [7:0] env_a=status_data[306+8*32'(env_index)+:8];
 wire [7:0] env_b=status_data[314+8*32'(env_index)+:8];
 wire [31:0] env_fraction=draw_x<836?0:(32'(draw_x)-836)%21;
 wire [31:0] env_level=(32'(env_a)*(21-env_fraction)+32'(env_b)*env_fraction)/21;
 wire [11:0] env_y=12'(432-env_level*200/255);
 wire unused_env_index=^env_index_full[31:4];
 reg phase_left,phase_aligned,phase_vertical;
 reg [255:0] phase_row;
 always @(posedge clk)begin
  phase_aligned<=phase_pixel;phase_left<=phase_aligned;
  phase_vertical<=0;
  if(stage_x>=1572 && stage_x<1828 && stage_y>=198 && stage_y<454)begin
   if(stage_y>198)phase_vertical<=phase_row[8'(stage_x-1572)];
   phase_row[8'(stage_x-1572)]<=phase_pixel;
  end
 end

 localparam SCENE_LATENCY=40;
 typedef struct packed {
  logic [11:0] x;
  logic [11:0] y;
  logic  de;
  logic  hs;
  logic  vs;
  logic [11:0] wave_min;
  logic [11:0] wave_max;
  logic [11:0] env_y;
  logic [7:0] spectrum_sample;
  logic  wave_initialized;
  logic  initialized;
  logic  phase_left;
  logic  phase_aligned;
  logic  phase_vertical;
  logic  xy_signal;
  logic  xy_direct;
  logic  xy_mixed;
  logic signed [5:0] xy_shift;
  logic  status_live;
  logic [511:0] status_data;
  logic [1:0] spectrum_range;
  logic [15:0] peak_hz;
  logic  peak_valid;
  logic plot_grid,spectrum_bar;
  logic [4:0] plot_flags;
  logic [23:0] spectrum_color;
 } pixel_info;
 pixel_info input_info,aligned;
 pixel_info info_pipe[0:SCENE_LATENCY-1];
 integer delay_pixel;
 always @* begin
  input_info='0;
  input_info.x=draw_x;
  input_info.y=draw_y;
  input_info.de=draw_de;
  input_info.hs=draw_hs;
  input_info.vs=draw_vs;
  input_info.wave_min=wave_min;
  input_info.wave_max=wave_max;
  input_info.env_y=env_y;
  input_info.spectrum_sample=spectrum_sample;
  input_info.wave_initialized=wave_initialized;
  input_info.initialized=initialized;
  input_info.phase_left=phase_left;
  input_info.phase_aligned=phase_aligned;
  input_info.phase_vertical=phase_vertical;
  input_info.xy_signal=xy_signal;
  input_info.xy_direct=xy_direct;
  input_info.xy_mixed=xy_mixed;
  input_info.xy_shift=xy_shift;
  input_info.status_live=status_live;
  input_info.status_data=status_data;
  input_info.spectrum_range=spectrum_range;
  input_info.peak_hz=peak_hz;
  input_info.peak_valid=peak_valid;
 end

 // Four arithmetic stages; inserted at descriptor stage4 without extra pixels.
 reg [11:0] overlay_x1,overlay_y1,grid_x1,grid_y1,env_x1,env_y1,phase_x1,phase_y1;
 (* syn_preserve=1,syn_keep=1 *) reg [9:0] gradient_pos1;reg [1:0] gradient_region1,gradient_region2,gradient_region3;
 wire spectrum_separator;
 visual_mod7_gap separator_gap(grid_x1,spectrum_separator);
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
   (overlay_x1>=80 && overlay_x1<704 && overlay_y1>=220 && overlay_y1<=424 && ((overlay_x1==12'd80 || overlay_x1==12'd158 || overlay_x1==12'd236 || overlay_x1==12'd314 || overlay_x1==12'd392 || overlay_x1==12'd470 || overlay_x1==12'd548 || overlay_x1==12'd626) || (overlay_y1==12'd220 || overlay_y1==12'd271 || overlay_y1==12'd322 || overlay_y1==12'd373 || overlay_y1==12'd424))) ||
   (overlay_x1>=836 && overlay_x1<=1151 && overlay_y1>=232 && overlay_y1<=432 && ((overlay_x1==12'd836 || overlay_x1==12'd899 || overlay_x1==12'd962 || overlay_x1==12'd1025 || overlay_x1==12'd1088 || overlay_x1==12'd1151) || (overlay_y1==12'd232 || overlay_y1==12'd282 || overlay_y1==12'd332 || overlay_y1==12'd382 || overlay_y1==12'd432))) ||
   (overlay_x1>=1540 && overlay_x1<=1860 && overlay_y1>=198 && overlay_y1<454 && (phase_x1[5:0]==0 || phase_y1[5:0]==0)) ||
   (overlay_x1>=80 && overlay_x1<1840 && overlay_y1>=584 && overlay_y1<=700 && ((overlay_x1==12'd80 || overlay_x1==12'd373 || overlay_x1==12'd666 || overlay_x1==12'd960 || overlay_x1==12'd1253 || overlay_x1==12'd1546 || overlay_x1==12'd1839) || (overlay_y1==12'd584 || overlay_y1==12'd613 || overlay_y1==12'd642 || overlay_y1==12'd671 || overlay_y1==12'd700)));
  spectrum_distance2<=12'd700-overlay_y1;
  spectrum_region2<=overlay_x1>=80 && overlay_x1<1840 && overlay_y1>=584 && overlay_y1<700 && !spectrum_separator;
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
 pixel_info overlay_ready,bar_ready;
 always @* begin overlay_ready=info_pipe[3];overlay_ready.plot_grid=grid4;overlay_ready.spectrum_color=spectrum_color4;end
 always @* begin bar_ready=info_pipe[4];bar_ready.spectrum_bar=spectrum_bar5;end
 pixel_info mask_source,plot_ready;
 assign mask_source=info_pipe[6];
 wire waveform_area=mask_source.wave_initialized && mask_source.x>=80 && mask_source.x<704 && mask_source.y>=208 && mask_source.y<=436;
 wire phase_area=mask_source.xy_signal && mask_source.x>=1572 && mask_source.x<1828 && mask_source.y>=198 && mask_source.y<454;
 always @* begin
  plot_ready=mask_source;
  plot_ready.plot_flags[0]=waveform_area && {1'b0,mask_source.y}+13'd3>={1'b0,mask_source.wave_min} && {1'b0,mask_source.y}<={1'b0,mask_source.wave_max}+13'd3;
  plot_ready.plot_flags[1]=waveform_area && {1'b0,mask_source.y}+13'd1>={1'b0,mask_source.wave_min} && {1'b0,mask_source.y}<={1'b0,mask_source.wave_max}+13'd1;
  plot_ready.plot_flags[2]=waveform_area && mask_source.y>=mask_source.wave_min && mask_source.y<=mask_source.wave_max;
  plot_ready.plot_flags[3]=phase_area && ((mask_source.phase_left && mask_source.x>1572) || mask_source.phase_vertical);
  plot_ready.plot_flags[4]=phase_area && mask_source.phase_aligned;
 end
 pixel_info spectrum_ready,waveform_ready;
 always @* begin spectrum_ready=info_pipe[1];spectrum_ready.spectrum_sample=spectrum_sample;end
 always @* begin waveform_ready=info_pipe[5];waveform_ready.wave_min=wave_min;waveform_ready.wave_max=wave_max;end
 always @(posedge clk)begin
  info_pipe[0]<=input_info;
  for(delay_pixel=1;delay_pixel<SCENE_LATENCY;delay_pixel=delay_pixel+1)
   if(delay_pixel==2)info_pipe[delay_pixel]<=spectrum_ready;else if(delay_pixel==4)info_pipe[delay_pixel]<=overlay_ready;else if(delay_pixel==5)info_pipe[delay_pixel]<=bar_ready;else if(delay_pixel==6)info_pipe[delay_pixel]<=waveform_ready;else if(delay_pixel==7)info_pipe[delay_pixel]<=plot_ready;else info_pipe[delay_pixel]<=info_pipe[delay_pixel-1];
 end
 assign aligned=info_pipe[SCENE_LATENCY-1];
 reg [SCENE_LATENCY-1:0] info_valid;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)info_valid<=0;else info_valid<={info_valid[SCENE_LATENCY-2:0],1'b1};
 wire raw_label_ink;wire [23:0] raw_label_color;wire [1:0] raw_label_coverage;
 visual_labels #(.SAMPLE_RATE(SAMPLE_RATE)) labels(
  .clk(clk),.x_early(stage_x),.y_early(stage_y),.peak_valid(peak_valid),.peak_hz(peak_hz),
  .xy_direct(xy_direct),.xy_signal(xy_signal),.xy_mixed(xy_mixed),.xy_shift(xy_shift),.ink(raw_label_ink),.status_live(status_live),.status_data(status_data),.color(raw_label_color),.coverage(raw_label_coverage),.spectrum_range(spectrum_range));
 // Labels start at the raw pixel; align their exact 22-clock result
 // to the scene and one-clock base-image register.
 reg [26:0] label_pipe[0:18];integer delay_label;
 always @(posedge clk)begin
  label_pipe[0]<={raw_label_ink,raw_label_color,raw_label_coverage};
  for(delay_label=1;delay_label<19;delay_label=delay_label+1)label_pipe[delay_label]<=label_pipe[delay_label-1];
 end
 assign {label_ink,label_color,label_coverage}=label_pipe[18];
 // The scene and descriptor arrive together; the exact font ROM adds one cycle. Delay the complete non-text image,
 // original scene blend base and all timing signals together.
 reg [7:0] base_red,base_green,base_blue;
 reg base_out_de,base_out_hs,base_out_vs;
 wire [23:0] early_label_color=label_pipe[17][25:2];
 wire [1:0] early_label_coverage=label_pipe[17][1:0];
 (* syn_preserve=1 *) reg [9:0] text_r_sum,text_g_sum,text_b_sum;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  rgb_red<=0;rgb_green<=0;rgb_blue<=0;out_de<=0;out_hs<=0;out_vs<=0;text_r_sum<=0;text_g_sum<=0;text_b_sum<=0;
 end else begin
  text_r_sum<=text_weighted_sum(scene_color[23:16],early_label_color[23:16],early_label_coverage);
  text_g_sum<=text_weighted_sum(scene_color[15:8],early_label_color[15:8],early_label_coverage);
  text_b_sum<=text_weighted_sum(scene_color[7:0],early_label_color[7:0],early_label_coverage);
  out_de<=base_out_de;out_hs<=base_out_hs;out_vs<=base_out_vs;
  {rgb_red,rgb_green,rgb_blue}<=base_out_de && label_ink?
   {text_divide_three(text_r_sum),text_divide_three(text_g_sum),text_divide_three(text_b_sum)}:{base_red,base_green,base_blue};
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  base_red<=0;base_green<=0;base_blue<=0;base_out_de<=0;base_out_hs<=0;base_out_vs<=0;
  draw_x<=0;draw_y<=0;draw_de<=0;draw_hs<=0;draw_vs<=0;
  stage_x<=0;stage_y<=0;stage_de<=0;stage_hs<=0;stage_vs<=0;
 end else begin
  stage_x<=x;stage_y<=y;stage_de<=de;stage_hs<=hs;stage_vs<=vs;
  draw_x<=stage_x;draw_y<=stage_y;draw_de<=stage_de;draw_hs<=stage_hs;draw_vs<=stage_vs;
  base_out_de<=aligned.de && info_valid[SCENE_LATENCY-1];base_out_hs<=aligned.hs;base_out_vs<=aligned.vs;
  base_red<=0;base_green<=0;base_blue<=0;
  if(aligned.de && info_valid[SCENE_LATENCY-1])begin
   {base_red,base_green,base_blue}<=scene_color;
   // Plot grids are confined to wells, with quiet single-pixel lines.
   if(aligned.plot_grid)begin
    base_red<=scene_color[23:16]+8'd15;base_green<=scene_color[15:8]+8'd15;base_blue<=scene_color[7:0]+8'd15;
   end
   if(aligned.plot_flags[0])begin base_red<=scene_color[23:16]+8'd12;base_green<=scene_color[15:8]+8'd23;base_blue<=scene_color[7:0]+8'd23;end
   if(aligned.plot_flags[1])begin base_red<=143;base_green<=210;base_blue<=216;end
   if(aligned.plot_flags[2])begin base_red<=211;base_green<=253;base_blue<=246;end
   // Branch frame_status: frame-constant status read directly.
   if(status_live && status_data[5] && aligned.x>=836 && aligned.x<=1151 && aligned.y>=220 && aligned.y<=434)begin
    if(aligned.y+3>=aligned.env_y && aligned.y<=aligned.env_y+3)begin base_red<=scene_color[23:16]+8'd13;base_green<=scene_color[15:8]+8'd20;base_blue<=scene_color[7:0]+8'd25;end
    if(aligned.y+1>=aligned.env_y && aligned.y<=aligned.env_y+1)begin base_red<=201;base_green<=247;base_blue<=225;end
    if(aligned.y>aligned.env_y+3 && aligned.y<432)begin
     base_red<=scene_color[23:16]+8'((432-32'(aligned.y))/10);
     base_green<=scene_color[15:8]+8'((432-32'(aligned.y))/6);
     base_blue<=scene_color[7:0]+8'((432-32'(aligned.y))/5);
    end
   end
   if(aligned.plot_flags[3])begin base_red<=132;base_green<=208;base_blue<=223;end
   if(aligned.plot_flags[4])begin base_red<=175;base_green<=231;base_blue<=240;end
   if(aligned.initialized && aligned.spectrum_bar)begin
    {base_red,base_green,base_blue}<=aligned.spectrum_color;
   end
  end
 end
 initial if(LOGN<10 || LOGN>12)$fatal(1,"LOGN10..12");
endmodule
`default_nettype wire

`default_nettype none
// -value bit i equals value[i] XOR any(value[i-1:0]). Keep small group
// boundaries so prefix reductions do not become a long LUT ripple chain.
module visual_conditional_negate #(parameter WIDTH=27,GROUP_BITS=6)(
 input wire [WIDTH-1:0] value,input wire negative,output wire [WIDTH-1:0] result
);
 localparam GROUPS=(WIDTH-1)/GROUP_BITS;
 (* syn_keep=1 *) wire [GROUPS-1:0] group_any;
 genvar g,i;
 generate for(g=0;g<GROUPS;g=g+1)begin:G
  assign group_any[g]=|value[g*GROUP_BITS+:GROUP_BITS];
 end
 for(i=0;i<WIDTH;i=i+1)begin:B
  if(i==0)assign result[i]=value[i];
  else begin:N
   localparam PREVIOUS=i/GROUP_BITS,PARTIAL=i%GROUP_BITS;
   wire lower_any;
   if(PREVIOUS==0)assign lower_any=|value[i-1:0];
   else if(PARTIAL==0)assign lower_any=|group_any[PREVIOUS-1:0];
   else assign lower_any=(|group_any[PREVIOUS-1:0]) || (|value[i-1:PREVIOUS*GROUP_BITS]);
   assign result[i]=value[i] ^ (negative && lower_any);
  end
 end endgenerate
 initial if(WIDTH<=GROUP_BITS || GROUP_BITS<1)$fatal(1,"Invalid conditional-negation prefix geometry");
endmodule
`default_nettype wire

`default_nettype none
module visual_mod7_gap(input wire [11:0] value,output wire gap);
 (* syn_keep=1 *) wire [3:0] low_pair={1'b0,value[2:0]}+{1'b0,value[5:3]};
 (* syn_keep=1 *) wire [3:0] high_pair={1'b0,value[8:6]}+{1'b0,value[11:9]};
 wire [4:0] digit_sum={1'b0,low_pair}+{1'b0,high_pair};
 assign gap=digit_sum==5'd6 || digit_sum==5'd13 || digit_sum==5'd20 || digit_sum==5'd27;
endmodule
`default_nettype wire
