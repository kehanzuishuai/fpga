`default_nettype none
// Square 128x128 bitmap. Copy 512 paired 16-bit samples, subtract frame mean,
// apply ONE power-of-two gain to BOTH axes, then Bresenham-connect every pair.
// Never independently normalize axes (which would falsify amplitude ratios).
module visual_xy_plot(
 input wire clk,rst_n,start,
 output wire [8:0] sample_addr,input wire [48:0] sample_data,
 output reg sample_release,output wire busy,
 output wire copy_valid,output wire [8:0] copy_index,
 input wire [13:0] pixel_addr,output reg pixel,
 output reg signal_valid,output reg direct_mode,mixed_mode,
 output reg signed [5:0] scale_shift
);
 localparam [3:0] IDLE=0,CLEAR=1,COPY=2,PEAK=3,GAIN=4,READ_POINT=5,WAIT_POINT=6,BEGIN_LINE=7,DRAW_LINE=8;
 wire [15:0] unused_wave=sample_data[48:33];
 reg [3:0] state;
 reg [13:0] clear_index;
 reg [9:0] index;
 reg primed;
 reg signed [15:0] xs[0:511],ys[0:511];
 reg bitmap[0:16383];
 reg signed [25:0] sum_x,sum_y;
 reg signed [16:0] mean_x,mean_y;
 reg signed [15:0] xq,yq;
 reg [16:0] peak;
 reg [6:0] line_x,line_y,target_x,target_y,previous_x,previous_y;
 reg [7:0] delta_x,delta_y;reg x_positive,y_positive;
 reg signed [9:0] error;
 wire signed [10:0] twice_error={error,1'b0};
 wire step_x=twice_error>= -$signed({3'b0,delta_y});
 wire step_y=twice_error<= $signed({3'b0,delta_x});
 wire signed [16:0] centered_x=$signed({xq[15],xq})-mean_x;
 wire signed [16:0] centered_y=$signed({yq[15],yq})-mean_y;
 wire [16:0] ax=centered_x[16]?17'(-centered_x):17'(centered_x);
 wire [16:0] ay=centered_y[16]?17'(-centered_y):17'(centered_y);
 wire [16:0] candidate=ax>ay?ax:ay;
 wire [16:0] next_peak=candidate>peak?candidate:peak;
 wire signed [25:0] next_sum_x=sum_x+{{10{sample_data[31]}},sample_data[31:16]};
 wire signed [25:0] next_sum_y=sum_y+{{10{sample_data[15]}},sample_data[15:0]};
 wire [6:0] mapped_x=coordinate(centered_x,scale_shift);
 wire [6:0] mapped_y=7'(8'd128-{1'b0,coordinate(centered_y,scale_shift)});
 assign busy=state!=IDLE;
 assign sample_addr=index[8:0];
 assign copy_valid=state==COPY && primed;
 assign copy_index=index[8:0]-9'd1;
 function automatic [6:0] coordinate(input signed [16:0] value,input signed [5:0] shift);
  reg signed [31:0] z;
  begin z={{15{value[16]}},value};
   if(shift>=0)z=z>>>shift;else z=z<<<(-shift);
   if(z>63)z=63;else if(z< -63)z=-63;
   coordinate=7'(z+64);
  end
 endfunction
 function automatic signed [5:0] gain_shift(input [16:0] p);
  integer k,e;begin e=0;for(k=0;k<17;k=k+1)if(p[k])e=k;gain_shift=6'(e-5);end
 endfunction
 always @(posedge clk)begin
  pixel<=bitmap[pixel_addr];
  xq<=xs[index[8:0]];yq<=ys[index[8:0]];
  if(state==CLEAR)bitmap[clear_index]<=0;
  if(state==COPY && primed)begin xs[copy_index]<=sample_data[31:16];ys[copy_index]<=sample_data[15:0];end
  if(state==DRAW_LINE)bitmap[{line_y,line_x}]<=1;
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=IDLE;clear_index<=0;index<=0;primed<=0;sum_x<=0;sum_y<=0;mean_x<=0;mean_y<=0;
  peak<=0;signal_valid<=0;direct_mode<=0;mixed_mode<=0;scale_shift<=0;sample_release<=0;
  line_x<=0;line_y<=0;target_x<=0;target_y<=0;previous_x<=0;previous_y<=0;
  delta_x<=0;delta_y<=0;x_positive<=0;y_positive<=0;error<=0;
 end else begin
  sample_release<=0;
  case(state)
   IDLE:if(start)begin state<=CLEAR;clear_index<=0;signal_valid<=0;mixed_mode<=0;end
   CLEAR:if(clear_index==16383)begin state<=COPY;index<=0;primed<=0;sum_x<=0;sum_y<=0;end else clear_index<=clear_index+1'b1;
   COPY:begin
    primed<=1;index<=index+1'b1;
    if(primed)begin
     sum_x<=next_sum_x;sum_y<=next_sum_y;
     if(index==1)direct_mode<=sample_data[32];
     else if(sample_data[32]!=direct_mode)mixed_mode<=1;
     if(index==512)begin
      mean_x<=17'(next_sum_x>>>9);mean_y<=17'(next_sum_y>>>9);
      sample_release<=1;state<=PEAK;index<=0;primed<=0;peak<=0;
     end
    end
   end
   PEAK:begin
    primed<=1;index<=index+1'b1;
    if(primed)begin peak<=next_peak;
     if(index==512)begin state<=GAIN;end
    end
   end
   GAIN:begin
    scale_shift<=gain_shift(peak);signal_valid<=peak>=8 && !mixed_mode;
    index<=0;state<=(peak>=8 && !mixed_mode)?READ_POINT:IDLE;
   end
   READ_POINT:state<=WAIT_POINT;
   WAIT_POINT:state<=BEGIN_LINE;
   BEGIN_LINE:begin
    target_x<=mapped_x;target_y<=mapped_y;
    line_x<=index==0?mapped_x:previous_x;line_y<=index==0?mapped_y:previous_y;
    delta_x<={1'b0,(mapped_x>previous_x?mapped_x-previous_x:previous_x-mapped_x)};
    delta_y<={1'b0,(mapped_y>previous_y?mapped_y-previous_y:previous_y-mapped_y)};
    x_positive<=mapped_x>=previous_x;y_positive<=mapped_y>=previous_y;
    error<=$signed({3'b0,(mapped_x>previous_x?mapped_x-previous_x:previous_x-mapped_x)})-
           $signed({3'b0,(mapped_y>previous_y?mapped_y-previous_y:previous_y-mapped_y)});
    state<=DRAW_LINE;
   end
   DRAW_LINE:begin
    if(line_x==target_x && line_y==target_y)begin
     previous_x<=target_x;previous_y<=target_y;
     if(index==511)state<=IDLE;else begin index<=index+1'b1;state<=READ_POINT;end
    end else begin
     if(step_x)line_x<=x_positive?line_x+1'b1:line_x-1'b1;
     if(step_y)line_y<=y_positive?line_y+1'b1:line_y-1'b1;
     if(step_x && step_y)error<=error+$signed({2'b0,delta_x})-$signed({2'b0,delta_y});
     else if(step_x)error<=error-$signed({2'b0,delta_y});
     else if(step_y)error<=error+$signed({2'b0,delta_x});
    end
   end
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire
