`default_nettype none
// Independent KS loop: one synchronous RAM read/write port, noise fill on note-on,
// two-tap loss filter and a one-multiply allpass fractional-delay correction.
module yinse_ks_loop #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5)(
 input wire clk,rst_n,sample_tick,start,clear,enable,
 input wire [10:0] delay_in,input wire signed [15:0] tuning_in,
 output reg signed [23:0] sample,output wire busy,output reg overrun,clipped
);
 localparam integer AW=$clog2(MAX_DELAY);
 typedef logic [AW-1:0] address_t;
 localparam [3:0] IDLE=0,FILL=1,READ0=2,READ1=3,AVERAGE=4,TUNE=5,WRITE=6;
 reg [3:0] state;reg [AW-1:0] ptr,fill_ptr;
 reg [10:0] length;reg signed [15:0] coefficient;
 reg [23:0] noise;
 reg signed [23:0] memory[0:MAX_DELAY-1],read_data,current,w,v;
 wire [AW-1:0] next_ptr=(ptr==address_t'(length-1'b1))?{AW{1'b0}}:ptr+1'b1;
 wire [AW-1:0] read_address=(state==READ0)?ptr:next_ptr;
 wire signed [24:0] pair_sum={current[23],current}+{read_data[23],read_data};
 wire signed [24:0] average=pair_sum>>>1;
 wire signed [40:0] loss_product=average*16'sd32720;
 wire signed [31:0] difference={{8{v[23]}},v}-{{8{w[23]}},w};
 wire signed [47:0] tune_product=difference*coefficient;
 wire [32:0] unused_quantization={loss_product[40:39],loss_product[14:0],tune_product[47],tune_product[14:0]};
 wire signed [31:0] m=tune_product[46:15];
 wire signed [31:0] new_ring=m+{{8{w[23]}},w};
 wire signed [31:0] new_w=m+{{8{v[23]}},v};
 assign busy=state!=IDLE;
 function automatic signed [23:0] clamp24(input signed [31:0] x);
  if(x>32'sd8388607)clamp24=24'sh7fffff;
  else if(x< -32'sd8388608)clamp24=24'sh800000;
  else clamp24=x[23:0];
 endfunction
 initial if(MAX_DELAY<4 || MAX_DELAY>1024 || (MAX_DELAY&(MAX_DELAY-1))!=0 || SEED==0)
  $fatal(1,"KS needs power-of-two MAX_DELAY 4..1024 and nonzero seed");
 // No RAM reset: only initialized note-length addresses are read.
 always @(posedge clk)begin
  if(state==READ0 || state==READ1)read_data<=memory[read_address];
  if(state==FILL)memory[fill_ptr]<=$signed(noise)>>>1;
  else if(state==WRITE)memory[ptr]<=clamp24(new_ring);
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=IDLE;ptr<=0;fill_ptr<=0;length<=2;coefficient<=0;noise<=SEED;
  current<=0;w<=0;v<=0;sample<=0;overrun<=0;clipped<=0;
 end else if(clear)begin state<=IDLE;sample<=0;w<=0;overrun<=0;clipped<=0;end
 else if(start)begin
  length<=delay_in;coefficient<=tuning_in;ptr<=0;fill_ptr<=0;noise<=SEED;w<=0;sample<=0;
  if(delay_in>=2 && {21'd0,delay_in}<=MAX_DELAY)state<=FILL;else begin state<=IDLE;overrun<=1;end
 end else begin
  if(sample_tick && enable && busy && state!=FILL)overrun<=1;
  case(state)
   IDLE:if(sample_tick && enable)state<=READ0;
   FILL:begin
    noise<={noise[22:0],noise[23]^noise[22]^noise[21]^noise[16]};
    if(fill_ptr==address_t'(length-1'b1))state<=IDLE;else fill_ptr<=fill_ptr+1'b1;
   end
   READ0:state<=READ1;
   READ1:begin current<=read_data;state<=AVERAGE;end
   AVERAGE:begin v<=loss_product[38:15];state<=TUNE;end
   TUNE:state<=WRITE;
   WRITE:begin
    w<=clamp24(new_w);sample<=current;ptr<=next_ptr;state<=IDLE;
    if(new_ring>8388607 || new_ring< -8388608 || new_w>8388607 || new_w< -8388608)clipped<=1;
   end
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire
