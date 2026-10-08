`default_nettype none
module audio_visualizer #(parameter LOGN=11)(
 input wire audio_clk,audio_rst_n,pcm_valid,input wire signed [23:0] pcm,
 input wire xy_enable,input wire signed [23:0] xy_x,xy_y,
 input wire pixel_clk,pixel_rst_n,
 output wire [9:0] tmds_blue,tmds_green,tmds_red,
 output wire [31:0] fft_dropped,wave_dropped,spectrum_dropped
);
 reg [7:0] delay_ram[0:31];reg [4:0] delay_ptr;
 // Both ends of CDC mailbox share assertion. Video relock resets ONLY analysis.
 wire analysis_reset_async=audio_rst_n && pixel_rst_n;
 reg analysis_reset_meta;
 reg analysis_rst_n;
 reg display_reset_meta;
 reg display_rst_n;
 always @(posedge audio_clk or negedge analysis_reset_async)
 if(!analysis_reset_async)begin analysis_reset_meta<=0;analysis_rst_n<=0;end
 else begin analysis_reset_meta<=1'b1;analysis_rst_n<=analysis_reset_meta;end
 always @(posedge pixel_clk or negedge analysis_reset_async)
 if(!analysis_reset_async)begin display_reset_meta<=0;display_rst_n<=0;end
 else begin display_reset_meta<=1'b1;display_rst_n<=display_reset_meta;end
 wire [39:0] unused_quantization={pcm[7:0],xy_x[15:0],xy_y[15:0]};
 reg [7:0] delayed;
 always @(posedge audio_clk or negedge analysis_rst_n)
 if(!analysis_rst_n)begin delay_ptr<=0;delayed<=0;end
 else if(pcm_valid)begin
   delayed<=delay_ram[delay_ptr];delay_ptr<=delay_ptr+1'b1;
 end
 always @(posedge audio_clk)
 if(pcm_valid)delay_ram[delay_ptr]<=pcm[23:16];
 // Gate acquisition until the delay buffer has valid data after reset.
 reg [5:0] fill;
 always @(posedge audio_clk or negedge analysis_rst_n)
 if(!analysis_rst_n)fill<=0;else if(pcm_valid && fill<33)fill<=fill+1'b1;
 // Rising zero-crossing trigger;100ms timeout still permits DC/silence traces.
 reg collecting,previous_negative;
 reg [8:0] trace_count;
 reg [12:0] trigger_wait;
 wire trigger_now=(previous_negative && !pcm[23]) || trigger_wait==13'd4799;
 wire wave_valid=pcm_valid && fill==33 && (collecting || trigger_now);
 always @(posedge audio_clk or negedge analysis_rst_n)
 if(!analysis_rst_n)begin collecting<=0;previous_negative<=0;trace_count<=0;trigger_wait<=0;end
 else if(pcm_valid)begin
   previous_negative<=pcm[23];
   if(fill==33)begin
     if(collecting)begin
       trace_count<=trace_count+1'b1;
       if(&trace_count)begin collecting<=0;trigger_wait<=0;end
     end else if(trigger_now)begin collecting<=1;trace_count<=1;trigger_wait<=0;end
     else trigger_wait<=trigger_wait+1'b1;
   end
 end
 wire wave_pending,spec_pending,wave_release,spec_release;
 wire [8:0] wave_addr;wire [23:0] wave_data;
 wire [LOGN-2:0] spec_addr;wire [7:0] spec_data;
 visual_frame_store #(.AW(9),.W(24)) wave_frames(
 .wr_clk(audio_clk),.wr_rst_n(analysis_rst_n),.wr_valid(wave_valid),
 .wr_data({pcm[23:16],xy_enable?xy_x[23:16]:pcm[23:16],xy_enable?xy_y[23:16]:delayed}),
 .dropped_frames(wave_dropped),.rd_clk(pixel_clk),.rd_rst_n(display_rst_n),
 .rd_addr(wave_addr),.rd_data(wave_data),.pending(wave_pending),.release_frame(wave_release));
 wire bin_valid;wire [LOGN-2:0] unused_bin_index;
 wire signed [17:0] unused_bin_re,unused_bin_im;wire [36:0] power_value;
 visual_fft #(.LOGN(LOGN)) fft(.clk(audio_clk),.rst_n(analysis_rst_n),
 .sample_valid(pcm_valid),.sample(pcm[23:8]),.dropped_frames(fft_dropped),
 .bin_valid(bin_valid),.bin_index(unused_bin_index),.bin_re(unused_bin_re),.bin_im(unused_bin_im),.bin_power(power_value));
 function [7:0] power_height;
 input [36:0] p;integer k,e;
 begin e=0;for(k=0;k<37;k=k+1)if(p[k])e=k;
 power_height=8'(e*6);end
 endfunction
 visual_frame_store #(.AW(LOGN-1),.W(8)) spectrum_frames(
 .wr_clk(audio_clk),.wr_rst_n(analysis_rst_n),.wr_valid(bin_valid),.wr_data(power_height(power_value)),
 .dropped_frames(spectrum_dropped),.rd_clk(pixel_clk),.rd_rst_n(display_rst_n),
 .rd_addr(spec_addr),.rd_data(spec_data),.pending(spec_pending),.release_frame(spec_release));
 wire [9:0] x,y;wire de,hs,vs,blank_start;
 visual_raster raster(pixel_clk,display_rst_n,x,y,de,hs,vs,blank_start);
 wire [7:0] r,g,b;wire de_d,hs_d,vs_d;
 visual_renderer #(.LOGN(LOGN)) render(pixel_clk,display_rst_n,x,y,de,hs,vs,blank_start,
 wave_pending,spec_pending,wave_data,spec_data,wave_addr,spec_addr,wave_release,spec_release,r,g,b,de_d,hs_d,vs_d);
 visual_tmds enc_b(pixel_clk,display_rst_n,de_d,{vs_d,hs_d},b,tmds_blue);
 visual_tmds enc_g(pixel_clk,display_rst_n,de_d,2'b00,g,tmds_green);
 visual_tmds enc_r(pixel_clk,display_rst_n,de_d,2'b00,r,tmds_red);
endmodule
`default_nettype wire
