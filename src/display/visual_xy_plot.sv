`default_nettype none
// Double-buffered native bitmap. Copy 512 paired samples, subtract frame mean,
// Apply one gain to both axes, Bresenham-connect, publish only at frame boundary.
// Never independently normalize axes (which would falsify amplitude ratios).
module visual_xy_plot #(parameter COORD_BITS=7,SPAN=128)(
 input wire clk,rst_n,start,publish,
 output wire [8:0] sample_addr,input wire [48:0] sample_data,
 output reg sample_release,output wire busy,ready,
 output wire copy_valid,output wire [8:0] copy_index,
 input wire [2*COORD_BITS-1:0] pixel_addr,output reg pixel,
 output reg signal_valid,output reg direct_mode,mixed_mode,
 output reg signed [5:0] scale_shift
);
 localparam [4:0] IDLE=0,CLEAR=1,COPY=2,PEAK=3,GAIN=4,READ_POINT=5,WAIT_POINT=6,BEGIN_LINE=7,DRAW_LINE=8,HOLD=9,SET_ERROR=10;
 localparam integer DEPTH=1<<(2*COORD_BITS);
 reg front,back,ready_signal,ready_mode,ready_mixed;
 reg signed [5:0] ready_shift;
 wire [15:0] unused_wave=sample_data[48:33];
 reg [4:0] state;reg [2:0] map_wait;
 reg [2*COORD_BITS-1:0] clear_index;
 (* syn_preserve=1 *) reg clear_last;
 reg [9:0] index;
 reg primed;
 reg signed [15:0] xs[0:511],ys[0:511];
 reg bitmap[0:2*DEPTH-1];
 reg signed [25:0] sum_x,sum_y;
 reg signed [16:0] mean_x,mean_y;
 reg signed [15:0] xq,yq;
 reg [16:0] peak;
 reg [COORD_BITS-1:0] line_x,line_y,target_x,target_y,previous_x,previous_y;
 reg [COORD_BITS:0] delta_x,delta_y;reg x_positive,y_positive;
 reg signed [COORD_BITS+2:0] error;
 wire signed [COORD_BITS+3:0] twice_error={error,1'b0};
 wire step_x=twice_error>= -$signed({3'b0,delta_y});
 wire step_y=twice_error<= $signed({3'b0,delta_x});
 wire signed [16:0] centered_x=$signed({xq[15],xq})-mean_x;
 wire signed [16:0] centered_y=$signed({yq[15],yq})-mean_y;
 wire [16:0] ax=centered_x[16]?17'(-centered_x):17'(centered_x);
 wire [16:0] ay=centered_y[16]?17'(-centered_y):17'(centered_y);
 reg [16:0] peak_ax,peak_ay;reg [2:0] peak_valid_pipe;
 reg [16:0] candidate;
 always @(posedge clk)begin
  peak_ax<=centered_x_q[16]?17'(-centered_x_q):17'(centered_x_q);
  peak_ay<=centered_y_q[16]?17'(-centered_y_q):17'(centered_y_q);
  candidate<=peak_ax>peak_ay?peak_ax:peak_ay;
  peak_valid_pipe<={peak_valid_pipe[1:0],state==PEAK && primed && index<=512};
 end
 wire [16:0] next_peak=candidate>peak?candidate:peak;
 wire signed [25:0] next_sum_x=sum_x+{{10{sample_data[31]}},sample_data[31:16]};
 wire signed [25:0] next_sum_y=sum_y+{{10{sample_data[15]}},sample_data[15:0]};
 // The magnitude is clamped before an exact reciprocal division by 63.
 // For 0<=n<=LIMIT, ceil(2^SHIFT/63) has error strictly below 1/63.
 localparam LIMIT=(SPAN/2-1)*63,MAG_BITS=$clog2(LIMIT+1);
 localparam RECIP_SHIFT=$clog2(LIMIT*62+1),RECIP=((1<<RECIP_SHIFT)+62)/63;
 localparam RECIP_BITS=$clog2(RECIP+1),PRODUCT_BITS=MAG_BITS+RECIP_BITS;
 reg signed [16:0] centered_x_q,centered_y_q;
 reg signed [31:0] product_x,product_y,shifted_x,shifted_y;
 reg [MAG_BITS-1:0] magnitude_x,magnitude_y;
 reg negative_x,negative_y,quotient_negative_x,quotient_negative_y;
 reg [PRODUCT_BITS-1:0] reciprocal_x,reciprocal_y;
 wire [COORD_BITS-1:0] quotient_x=COORD_BITS'(reciprocal_x>>RECIP_SHIFT);
 wire [COORD_BITS-1:0] quotient_y=COORD_BITS'(reciprocal_y>>RECIP_SHIFT);
 reg [COORD_BITS-1:0] mapped_x,mapped_y;
 always @(posedge clk)begin
  centered_x_q<=centered_x;centered_y_q<=centered_y;
  product_x<=32'($signed(centered_x_q))*32'(SPAN/2-1);
  product_y<=32'($signed(centered_y_q))*32'(SPAN/2-1);
  shifted_x<=ready_shift>=0?product_x>>>ready_shift:product_x<<<(-ready_shift);
  shifted_y<=ready_shift>=0?product_y>>>ready_shift:product_y<<<(-ready_shift);
  magnitude_x<=(shifted_x>LIMIT || shifted_x< -LIMIT)?MAG_BITS'(LIMIT):MAG_BITS'(shifted_x<0?-shifted_x:shifted_x);
  magnitude_y<=(shifted_y>LIMIT || shifted_y< -LIMIT)?MAG_BITS'(LIMIT):MAG_BITS'(shifted_y<0?-shifted_y:shifted_y);
  negative_x<=shifted_x[31];negative_y<=shifted_y[31];
  reciprocal_x<=PRODUCT_BITS'(magnitude_x)*PRODUCT_BITS'(RECIP);
  reciprocal_y<=PRODUCT_BITS'(magnitude_y)*PRODUCT_BITS'(RECIP);
  quotient_negative_x<=negative_x;quotient_negative_y<=negative_y;
  mapped_x<=quotient_negative_x?COORD_BITS'(SPAN/2)-quotient_x:COORD_BITS'(SPAN/2)+quotient_x;
  mapped_y<=quotient_negative_y?COORD_BITS'(SPAN/2)+quotient_y:COORD_BITS'(SPAN/2)-quotient_y;
 end
 assign busy=state!=IDLE;
 assign ready=state==HOLD;
 assign sample_addr=index[8:0];
 assign copy_valid=state==COPY && primed;
 assign copy_index=index[8:0]-9'd1;
 function automatic [COORD_BITS-1:0] coordinate(input signed [16:0] value,input signed [5:0] shift);
  reg signed [31:0] z;
  localparam DW=$clog2((SPAN/2-1)*63+1)+1;
  reg signed [DW-1:0] small_quotient;
  begin z={{15{value[16]}},value};
   z=z*(SPAN/2-1);
   if(shift>=0)z=z>>>shift;else z=z<<<(-shift);
   // Saturation can be decided before division. Inside this exact interval
   // the numerator fits DW bits, avoiding a full signed 32-bit divider.
   if(z>(SPAN/2-1)*63)z=SPAN/2-1;
   else if(z< -(SPAN/2-1)*63)z=-(SPAN/2-1);
   else begin small_quotient=$signed(DW'(z))/$signed(DW'(63));z=small_quotient;end
   z=z+SPAN/2;coordinate=z[COORD_BITS-1:0];
  end
 endfunction
 function automatic signed [5:0] gain_shift(input [16:0] p);
  integer k,e;begin e=0;for(k=0;k<17;k=k+1)if(p[k])e=k;gain_shift=6'(e-5);end
 endfunction
 always @(posedge clk)begin
  pixel<=bitmap[{front,pixel_addr}];
  xq<=xs[index[8:0]];yq<=ys[index[8:0]];
  if(state==CLEAR)bitmap[{back,clear_index}]<=0;
  if(state==COPY && primed)begin xs[copy_index]<=sample_data[31:16];ys[copy_index]<=sample_data[15:0];end
  if(state==DRAW_LINE)bitmap[{back,line_y,line_x}]<=1;
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=IDLE;map_wait<=0;front<=0;back<=1;ready_signal<=0;ready_mode<=0;ready_mixed<=0;ready_shift<=0;clear_index<=0;clear_last<=0;index<=0;primed<=0;sum_x<=0;sum_y<=0;mean_x<=0;mean_y<=0;
  peak<=0;signal_valid<=0;direct_mode<=0;mixed_mode<=0;scale_shift<=0;sample_release<=0;
  line_x<=0;line_y<=0;target_x<=0;target_y<=0;previous_x<=0;previous_y<=0;
  delta_x<=0;delta_y<=0;x_positive<=0;y_positive<=0;error<=0;
 end else begin
  sample_release<=0;
  case(state)
   IDLE:if(start)begin state<=CLEAR;clear_index<=0;clear_last<=0;ready_signal<=0;ready_mixed<=0;end
   CLEAR:begin
    // Predict the terminal address one existing clock ahead. The bitmap
    // still clears every address, including DEPTH-1, on the same clocks.
    clear_last<=clear_index==DEPTH-2;
    if(clear_last)begin state<=COPY;index<=0;primed<=0;sum_x<=0;sum_y<=0;end
    else clear_index<=clear_index+1'b1;
   end
   COPY:begin
    primed<=1;index<=index+1'b1;
    if(primed)begin
     sum_x<=next_sum_x;sum_y<=next_sum_y;
     if(index==1)ready_mode<=sample_data[32];
     else if(sample_data[32]!=ready_mode)ready_mixed<=1;
     if(index==512)begin
      mean_x<=17'(next_sum_x>>>9);mean_y<=17'(next_sum_y>>>9);
      sample_release<=1;state<=PEAK;index<=0;primed<=0;peak<=0;
     end
    end
   end
   PEAK:begin
    primed<=1;index<=index+1'b1;
    if(peak_valid_pipe[2])peak<=next_peak;
    if(index==515)state<=GAIN;
   end
   GAIN:begin
    ready_shift<=gain_shift(peak);ready_signal<=peak>=8 && !ready_mixed;
    index<=0;state<=(peak>=8 && !ready_mixed)?READ_POINT:HOLD;
   end
   READ_POINT:begin state<=WAIT_POINT;map_wait<=0;end
   WAIT_POINT:if(map_wait==5)state<=BEGIN_LINE;else map_wait<=map_wait+1'b1;
   BEGIN_LINE:begin
    target_x<=mapped_x;target_y<=mapped_y;
    line_x<=index==0?mapped_x:previous_x;line_y<=index==0?mapped_y:previous_y;
    delta_x<={1'b0,(mapped_x>previous_x?mapped_x-previous_x:previous_x-mapped_x)};
    delta_y<={1'b0,(mapped_y>previous_y?mapped_y-previous_y:previous_y-mapped_y)};
    x_positive<=mapped_x>=previous_x;y_positive<=mapped_y>=previous_y;
    state<=SET_ERROR;
   end
   SET_ERROR:begin
    error<=$signed({2'b0,delta_x})-$signed({2'b0,delta_y});state<=DRAW_LINE;
   end
   DRAW_LINE:begin
    if(line_x==target_x && line_y==target_y)begin
     previous_x<=target_x;previous_y<=target_y;
     if(index==511)state<=HOLD;else begin index<=index+1'b1;state<=READ_POINT;end
    end else begin
     if(step_x)line_x<=x_positive?line_x+1'b1:line_x-1'b1;
     if(step_y)line_y<=y_positive?line_y+1'b1:line_y-1'b1;
     if(step_x && step_y)error<=error+$signed({2'b0,delta_x})-$signed({2'b0,delta_y});
     else if(step_x)error<=error-$signed({2'b0,delta_y});
     else if(step_y)error<=error+$signed({2'b0,delta_x});
    end
   end
   HOLD:if(publish)begin front<=back;back<=front;signal_valid<=ready_signal;direct_mode<=ready_mode;mixed_mode<=ready_mixed;scale_shift<=ready_shift;state<=IDLE;end
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire
