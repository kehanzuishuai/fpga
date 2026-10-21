`default_nettype none
// 63-tap windowed Hilbert FIR, 32 nonzero even taps, time-multiplexed MAC.
// Display-only; never feeds sound or stalls audio. Real X is delayed 31 samples
// to match Hilbert Y. With two real voices enabled, capture them at SAME tick.
module visual_xy_source(
 input wire clk,rst_n,pcm_valid,input wire signed [23:0] pcm,
 input wire xy_enable,input wire signed [23:0] xy_x,xy_y,
 output reg valid,output reg signed [15:0] wave_sample,x_sample,y_sample,
 output reg direct_mode,output reg [31:0] overruns
);
 reg signed [15:0] history[0:63];reg [5:0] wp,base;
 reg [6:0] fill;reg busy;reg [5:0] index;
 reg signed [15:0] ram_q,x_delayed,held_pcm,held_x,held_y,coef_q;
 reg held_mode;reg signed [39:0] sum;
 wire [5:0] addr=base-{index[4:0],1'b0};
 wire [5:0] delayed_addr=wp-6'd31;
 wire signed [31:0] product=ram_q*coef_q;
 wire signed [39:0] total=sum+{{8{product[31]}},product};
 function automatic signed [15:0] coefficient(input [4:0] tap);
  begin case(tap)
   5'd0:coefficient=-16'sd54;
   5'd1:coefficient=-16'sd64;
   5'd2:coefficient=-16'sd91;
   5'd3:coefficient=-16'sd136;
   5'd4:coefficient=-16'sd202;
   5'd5:coefficient=-16'sd295;
   5'd6:coefficient=-16'sd417;
   5'd7:coefficient=-16'sd577;
   5'd8:coefficient=-16'sd783;
   5'd9:coefficient=-16'sd1052;
   5'd10:coefficient=-16'sd1408;
   5'd11:coefficient=-16'sd1904;
   5'd12:coefficient=-16'sd2649;
   5'd13:coefficient=-16'sd3931;
   5'd14:coefficient=-16'sd6807;
   5'd15:coefficient=-16'sd20812;
   5'd16:coefficient=16'sd20812;
   5'd17:coefficient=16'sd6807;
   5'd18:coefficient=16'sd3931;
   5'd19:coefficient=16'sd2649;
   5'd20:coefficient=16'sd1904;
   5'd21:coefficient=16'sd1408;
   5'd22:coefficient=16'sd1052;
   5'd23:coefficient=16'sd783;
   5'd24:coefficient=16'sd577;
   5'd25:coefficient=16'sd417;
   5'd26:coefficient=16'sd295;
   5'd27:coefficient=16'sd202;
   5'd28:coefficient=16'sd136;
   5'd29:coefficient=16'sd91;
   5'd30:coefficient=16'sd64;
   5'd31:coefficient=16'sd54;
   default:coefficient=0;
  endcase end
 endfunction
 function automatic signed [15:0] saturate(input signed [39:0] value);
  reg signed [39:0] q;
  begin q=value>>>15;
   if(q>32767)saturate=32767;else if(q< -32768)saturate=-32768;else saturate=q[15:0];
  end
 endfunction
 always @(posedge clk)begin
  if(pcm_valid && !busy)begin history[wp]<=pcm[23:8];x_delayed<=history[delayed_addr];end
  ram_q<=history[addr];coef_q<=coefficient(index[4:0]);
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  wp<=0;base<=0;fill<=0;busy<=0;index<=0;sum<=0;
  held_pcm<=0;held_x<=0;held_y<=0;held_mode<=0;
  valid<=0;wave_sample<=0;x_sample<=0;y_sample<=0;direct_mode<=0;overruns<=0;
 end else begin
  valid<=0;
  if(pcm_valid && busy)overruns<=overruns+1'b1;
  if(pcm_valid && !busy)begin
   base<=wp;wp<=wp+1'b1;if(fill<64)fill<=fill+1'b1;
   held_pcm<=pcm[23:8];held_x<=xy_x[23:8];held_y<=xy_y[23:8];held_mode<=xy_enable;
   busy<=1;index<=0;sum<=0;
  end else if(busy)begin
   index<=index+1'b1;
   if(index!=0)sum<=total;
   if(index==32)begin
    busy<=0;wave_sample<=held_pcm;direct_mode<=held_mode;
    x_sample<=held_mode?held_x:x_delayed;
    y_sample<=held_mode?held_y:saturate(total);
    valid<=fill==64;
   end
  end
 end
 wire [23:0] unused_low={pcm[7:0],xy_x[7:0],xy_y[7:0]};
endmodule
`default_nettype wire
