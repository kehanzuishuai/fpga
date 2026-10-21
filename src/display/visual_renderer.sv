`default_nettype none
// Original instrument aesthetic; 640x360 logical coordinates at exact 3x scale.
// X/Y is square, DC-removed and normalized jointly. No changes to audio path.
module visual_renderer #(parameter LOGN=11,SAMPLE_RATE=48000)(
 input wire clk,rst_n,input wire [11:0] x,y,input wire de,hs,vs,blank_start,
 input wire wave_pending,spec_pending,input wire [48:0] wave_data,input wire [36:0] spec_data,
 output wire [8:0] wave_addr,output wire [LOGN-2:0] spec_addr,
 output wire wave_release,output reg spec_release,
 output reg [7:0] red,green,blue,output reg out_de,out_hs,out_vs
);
 reg [7:0] wave[0:255],spectrum[0:511];
 reg [2:0] state;
 localparam WAIT_BLANK=0,XY_START=1,XY_WAIT=2,SPEC_START=3,SPEC_COPY=4;
 reg [15:0] counter;reg [1:0] read_primed;reg primed,initialized;reg [7:0] pool_peak;
 reg [36:0] peak_power;reg [LOGN-2:0] peak_bin;reg [15:0] peak_hz;reg peak_valid;
 wire [15:0] prev_count=counter-16'd3;
 reg [36:0] spec_data_d,spec_data_d1;
 wire new_peak=primed && prev_count!=0 && spec_data_d>peak_power;
 wire [LOGN-2:0] candidate_bin=new_peak?prev_count[LOGN-2:0]:peak_bin;
 wire [15:0] candidate_hz=16'((64'(candidate_bin)*64'(SAMPLE_RATE)+(64'd1<<(LOGN-1)))>>LOGN);
 function [5:0] power_exponent(input [36:0] p);
  reg [63:0] v;reg [5:0] e;
  begin
   v={27'd0,p};e=0;
   if(|v[63:32])begin e[5]=1;v=v>>32;end
   if(|v[31:16])begin e[4]=1;v=v>>16;end
   if(|v[15:8])begin e[3]=1;v=v>>8;end
   if(|v[7:4])begin e[2]=1;v=v>>4;end
   if(|v[3:2])begin e[1]=1;v=v>>2;end
   if(v[1])e[0]=1;
   power_exponent=e;
  end
 endfunction
 reg [7:0] spec_height;reg [5:0] spec_exponent;
 always @(posedge clk)begin
  spec_exponent<=power_exponent(spec_data);
  spec_height<={2'd0,spec_exponent}+{1'b0,spec_exponent,1'b0};
  spec_data_d1<=spec_data;spec_data_d<=spec_data_d1;
 end
 assign spec_addr=counter[LOGN-2:0];
 wire [8:0] bar_index=9'(prev_count>>(LOGN-10));
 localparam [15:0] POOL_MASK=16'((1<<(LOGN-10))-1);
 wire pool_first=(prev_count & POOL_MASK)==0;
 wire pool_last=(prev_count & POOL_MASK)==POOL_MASK;
 wire [7:0] pool_value=(pool_first || spec_height>pool_peak)?spec_height:pool_peak;
 reg xy_start;wire xy_busy,xy_copy;wire [8:0] xy_copy_index;
 wire phase_pixel,xy_signal,xy_direct,xy_mixed;wire signed [5:0] xy_shift;
 wire [9:0] logical_x=10'(x/12'd3),logical_y=10'(y/12'd3);
 wire [13:0] phase_read={7'(logical_y-32),7'(logical_x-448)};
 visual_xy_plot xy_plot(.clk(clk),.rst_n(rst_n),.start(xy_start),
  .sample_addr(wave_addr),.sample_data(wave_data),.sample_release(wave_release),.busy(xy_busy),
  .copy_valid(xy_copy),.copy_index(xy_copy_index),.pixel_addr(phase_read),.pixel(phase_pixel),
  .signal_valid(xy_signal),.direct_mode(xy_direct),.mixed_mode(xy_mixed),.scale_shift(xy_shift));
 reg [7:0] wave_sample,wave_previous,spectrum_sample;
 reg [9:0] draw_x,draw_y;reg draw_de,draw_hs,draw_vs;
 always @(posedge clk)begin
  wave_sample<=wave[logical_x[7:0]];
  wave_previous<=wave[logical_x[7:0]-8'd1];
  spectrum_sample<=spectrum[9'(logical_x-64)];
  if(xy_copy && !xy_copy_index[0])wave[xy_copy_index[8:1]]<=wave_data[48:41];
  if(state==SPEC_COPY && primed && pool_last)spectrum[bar_index]<=pool_value;
 end
 wire [7:0] wave_y=8'd160-8'((wave_sample^8'h80)>>1);
 wire [7:0] wave_prev_y=8'd160-8'((wave_previous^8'h80)>>1);
 wire [7:0] wave_min=wave_y<wave_prev_y?wave_y:wave_prev_y;
 wire [7:0] wave_max=wave_y>wave_prev_y?wave_y:wave_prev_y;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=WAIT_BLANK;counter<=0;read_primed<=0;primed<=0;initialized<=0;pool_peak<=0;
  peak_power<=0;peak_bin<=0;peak_hz<=0;peak_valid<=0;xy_start<=0;spec_release<=0;
 end else begin
  xy_start<=0;spec_release<=0;
  case(state)
   WAIT_BLANK:if(blank_start)begin
    if(wave_pending)begin xy_start<=1;state<=XY_START;end else state<=SPEC_START;
   end
   XY_START:state<=XY_WAIT;
   XY_WAIT:if(!xy_busy)state<=SPEC_START;
   SPEC_START:begin counter<=0;read_primed<=0;primed<=0;peak_power<=0;peak_bin<=0;state<=spec_pending?SPEC_COPY:WAIT_BLANK;end
   SPEC_COPY:begin
    read_primed<={read_primed[0],1'b1};primed<=read_primed[1];
    if(primed)pool_peak<=pool_value;
    if(new_peak)begin peak_power<=spec_data_d;peak_bin<=prev_count[LOGN-2:0];end
    if(counter==((1<<(LOGN-1))+2))begin
     peak_hz<=candidate_hz;peak_valid<=new_peak || peak_power!=0;
     spec_release<=1;initialized<=1;state<=WAIT_BLANK;
    end else counter<=counter+1'b1;
   end
   default:state<=WAIT_BLANK;
  endcase
 end
 reg [7:0] base_r,base_g,base_b,gradient;
 reg grid_hit,axis_hit,wave_hit,phase_hit,spectrum_hit;
 reg base_de,base_hs,base_vs,delay_de,delay_hs,delay_vs;
 wire label_ink;
 visual_labels #(.SAMPLE_RATE(SAMPLE_RATE)) labels(
  .x(draw_x),.y(draw_y),.peak_valid(peak_valid),.peak_hz(peak_hz),
  .xy_direct(xy_direct),.xy_signal(xy_signal),.xy_mixed(xy_mixed),.xy_shift(xy_shift),.ink(label_ink),.clk(clk),.rst_n(rst_n));
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  base_de<=0;base_hs<=0;base_vs<=0;
  gradient<=0;grid_hit<=0;axis_hit<=0;wave_hit<=0;phase_hit<=0;spectrum_hit<=0;
  draw_x<=0;draw_y<=0;draw_de<=0;draw_hs<=0;draw_vs<=0;
 end else begin
  draw_x<=logical_x;draw_y<=logical_y;draw_de<=de;draw_hs<=hs;draw_vs<=vs;
  base_de<=draw_de;base_hs<=draw_hs;base_vs<=draw_vs;
  gradient<=draw_x[8:1];
  grid_hit<=draw_de && (draw_x[5:0]==0 || draw_y[5:0]==0);
  axis_hit<=draw_de && ((draw_x<256 && draw_y==96) || (draw_x>=64 && draw_x<576 && draw_y==328) ||
     (draw_x>=448 && draw_x<576 && draw_y==96) ||
     (draw_x==512 && draw_y>=32 && draw_y<160));
  wave_hit<=draw_de && initialized && draw_x<256 && draw_y>=32 && draw_y<161 && draw_x!=0 &&
    ((draw_y>={2'b0,wave_y} && draw_y<={2'b0,wave_prev_y}) ||
     (draw_y<={2'b0,wave_y} && draw_y>={2'b0,wave_prev_y}));
  phase_hit<=draw_de && xy_signal && draw_x>=448 && draw_x<576 && draw_y>=32 && draw_y<160 && phase_pixel;
  spectrum_hit<=draw_de && initialized && draw_x>=64 && draw_x<576 && draw_y>=210 && draw_y<328 && (10'd328-draw_y)<{2'b0,spectrum_sample};
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin base_r<=0;base_g<=0;base_b<=0;end
 else begin
  base_r<=3;base_g<=8;base_b<=16;
  if(grid_hit)begin base_r<=12;base_g<=22;base_b<=32;end
  if(axis_hit)begin base_r<=36;base_g<=48;base_b<=64;end
  if(wave_hit)begin base_r<=32;base_g<=255;base_b<=96;end
  if(phase_hit)begin base_r<=32;base_g<=210;base_b<=255;end
  if(spectrum_hit)begin base_r<=gradient;base_g<=96;base_b<=8'd255-gradient;end
 end
 // Match the two label lookup stages with graphics and raster controls.
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  delay_de<=0;delay_hs<=0;delay_vs<=0;
  red<=0;green<=0;blue<=0;out_de<=0;out_hs<=0;out_vs<=0;
 end else begin
  delay_de<=base_de;delay_hs<=base_hs;delay_vs<=base_vs;
  red<=delay_de && label_ink?8'd180:base_r;
  green<=delay_de && label_ink?8'd210:base_g;
  blue<=delay_de && label_ink?8'd224:base_b;
  out_de<=delay_de;out_hs<=delay_hs;out_vs<=delay_vs;
 end
 initial if(LOGN<10 || LOGN>12)$fatal(1,"LOGN10..12");
endmodule
`default_nettype wire
