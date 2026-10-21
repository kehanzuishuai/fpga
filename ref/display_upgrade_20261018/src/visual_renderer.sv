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
 reg [15:0] counter;reg primed,initialized;reg [7:0] pool_peak;
 reg [36:0] peak_power;reg [LOGN-2:0] peak_bin;reg [15:0] peak_hz;reg peak_valid;
 wire [15:0] prev_count=counter-1'b1;
 wire new_peak=prev_count!=0 && spec_data>peak_power;
 wire [LOGN-2:0] candidate_bin=new_peak?prev_count[LOGN-2:0]:peak_bin;
 wire [15:0] candidate_hz=16'((64'(candidate_bin)*64'(SAMPLE_RATE)+(64'd1<<(LOGN-1)))>>LOGN);
 function [7:0] power_height(input [36:0] p);
  integer k,e;begin e=0;for(k=0;k<37;k=k+1)if(p[k])e=k;power_height=8'(e*3);end
 endfunction
 wire [7:0] spec_height=power_height(spec_data);
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
  state<=WAIT_BLANK;counter<=0;primed<=0;initialized<=0;pool_peak<=0;
  peak_power<=0;peak_bin<=0;peak_hz<=0;peak_valid<=0;xy_start<=0;spec_release<=0;
 end else begin
  xy_start<=0;spec_release<=0;
  case(state)
   WAIT_BLANK:if(blank_start)begin
    if(wave_pending)begin xy_start<=1;state<=XY_START;end else state<=SPEC_START;
   end
   XY_START:state<=XY_WAIT;
   XY_WAIT:if(!xy_busy)state<=SPEC_START;
   SPEC_START:begin counter<=0;primed<=0;peak_power<=0;peak_bin<=0;state<=spec_pending?SPEC_COPY:WAIT_BLANK;end
   SPEC_COPY:begin
    primed<=1;
    if(primed)pool_peak<=pool_value;
    if(primed && new_peak)begin peak_power<=spec_data;peak_bin<=prev_count[LOGN-2:0];end
    if(counter==(1<<(LOGN-1)))begin
     peak_hz<=candidate_hz;peak_valid<=new_peak || peak_power!=0;
     spec_release<=1;initialized<=1;state<=WAIT_BLANK;
    end else counter<=counter+1'b1;
   end
   default:state<=WAIT_BLANK;
  endcase
 end
 wire label_ink;
 visual_labels #(.SAMPLE_RATE(SAMPLE_RATE)) labels(
  .x(draw_x),.y(draw_y),.peak_valid(peak_valid),.peak_hz(peak_hz),
  .xy_direct(xy_direct),.xy_signal(xy_signal),.xy_mixed(xy_mixed),.xy_shift(xy_shift),.ink(label_ink));
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  red<=0;green<=0;blue<=0;out_de<=0;out_hs<=0;out_vs<=0;
  draw_x<=0;draw_y<=0;draw_de<=0;draw_hs<=0;draw_vs<=0;
 end else begin
  draw_x<=logical_x;draw_y<=logical_y;draw_de<=de;draw_hs<=hs;draw_vs<=vs;
  out_de<=draw_de;out_hs<=draw_hs;out_vs<=draw_vs;
  red<=3;green<=8;blue<=16;
  if(draw_de)begin
   if(draw_x[5:0]==0 || draw_y[5:0]==0)begin red<=12;green<=22;blue<=32;end
   if((draw_x<256 && draw_y==96) || (draw_x>=64 && draw_x<576 && draw_y==328) ||
     (draw_x>=448 && draw_x<576 && draw_y==96) ||
     (draw_x==512 && draw_y>=32 && draw_y<160))begin red<=36;green<=48;blue<=64;end
   if(initialized && draw_x<256 && draw_y>=32 && draw_y<161 && draw_y>={2'b0,wave_min} && draw_y<={2'b0,wave_max} && draw_x!=0)
    begin red<=32;green<=255;blue<=96;end
   if(xy_signal && draw_x>=448 && draw_x<576 && draw_y>=32 && draw_y<160 && phase_pixel)
    begin red<=32;green<=210;blue<=255;end
   if(initialized && draw_x>=64 && draw_x<576 && draw_y>=210 && draw_y<328 && (10'd328-draw_y)<{2'b0,spectrum_sample})
    begin red<=draw_x[8:1];green<=96;blue<=8'd255-draw_x[8:1];end
   if(label_ink)begin red<=180;green<=210;blue<=224;end
  end
 end
 initial if(LOGN<10 || LOGN>12)$fatal(1,"LOGN10..12");
endmodule
`default_nettype wire
