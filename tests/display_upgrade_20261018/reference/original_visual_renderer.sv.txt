`default_nettype none
// Minimal instruments, no complex UI. Top-left waveform, top-right delayed
// PCM phase portrait, bottom linear-frequency log-power spectrum (0..24kHz).
// All CDC snapshots copied during vblank, then frozen for the visible frame.
module visual_renderer #(parameter LOGN=11,parameter SAMPLE_RATE=48000)(
 input wire clk,rst_n,input wire [9:0] x,y,input wire de,hs,vs,blank_start,
 input wire wave_pending,spec_pending,input wire [23:0] wave_data,input wire [36:0] spec_data,
 output wire [8:0] wave_addr,output wire [LOGN-2:0] spec_addr,
 output reg wave_release,spec_release,
 output reg [7:0] red,green,blue,output reg out_de,out_hs,out_vs
);
 reg [7:0] wave[0:255];
 reg phase_map[0:32767];
 reg [7:0] spectrum[0:511];
 reg [2:0] state;
 localparam WAIT_BLANK=0,CLEAR=1,WAVE_START=2,WAVE_COPY=3,SPEC_START=4,SPEC_COPY=5;
 reg [15:0] counter;
 reg primed,initialized;
 reg [7:0] pool_peak;
`ifndef SYNTHESIS
 initial if(LOGN<10 || LOGN>12 || SAMPLE_RATE<8000 || SAMPLE_RATE>96000)
   $fatal(1,"renderer supports LOGN10..12 and SAMPLE_RATE8000..96000");
`endif
 reg [36:0] peak_power;
 reg [LOGN-2:0] peak_bin;
 reg [15:0] peak_hz;
 reg peak_valid;
 wire new_peak=prev_count!=0 && spec_data>peak_power;
 wire [LOGN-2:0] candidate_bin=new_peak?prev_count[LOGN-2:0]:peak_bin;
 wire [15:0] candidate_hz=16'((64'(candidate_bin)*64'(SAMPLE_RATE)+(64'd1<<(LOGN-1)))>>LOGN);
 function [7:0] power_height;
 input [36:0] p;integer k,e;
 begin e=0;for(k=0;k<37;k=k+1)if(p[k])e=k;power_height=8'(e*6);end
 endfunction
 wire [7:0] spec_height=power_height(spec_data);
 assign wave_addr=counter[8:0];
 assign spec_addr=counter[LOGN-2:0];
 wire [15:0] prev_count=counter-1'b1;
 wire [8:0] bar_index=9'(prev_count>>(LOGN-10));
 localparam [15:0] POOL_MASK=16'((1<<(LOGN-10))-1);
 wire pool_first=(prev_count & POOL_MASK)==0;
 wire pool_last=(prev_count & POOL_MASK)==POOL_MASK;
 wire [7:0] pool_value=(pool_first || spec_height>pool_peak)?spec_height:pool_peak;
 wire [7:0] px=wave_data[15:8]^8'h80;
 // Y uses 7 most significant offset-binary bits; see explicit expression below.
 wire [7:0] y_unsigned=wave_data[7:0]^8'h80;
 wire [14:0] phase_write={7'd127-7'(y_unsigned>>1),px};
 reg [7:0] wave_sample,spectrum_sample;
 reg phase_pixel;
 reg [9:0] draw_x,draw_y;
 reg draw_de,draw_hs,draw_vs;
 // Explicit synchronous read ports: avoid a32768:1 combinational bitmap mux.
 always @(posedge clk)begin
   wave_sample<=wave[x[7:0]];
   spectrum_sample<=spectrum[9'(x-64)];
   phase_pixel<=phase_map[phase_read];
 end
 wire [7:0] wave_unsigned=wave_sample^8'h80;
 wire [7:0] wave_y=8'd160-8'(wave_unsigned>>1);
 wire [14:0] phase_read={7'(y-32),8'(x-352)};
 always @(posedge clk)begin
   if(state==CLEAR)phase_map[counter[14:0]]<=0;
   else if(state==WAVE_COPY && primed)phase_map[phase_write]<=1;
   if(state==WAVE_COPY && primed && !prev_count[0])wave[prev_count[8:1]]<=wave_data[23:16];
   if(state==SPEC_COPY && primed && pool_last)spectrum[bar_index]<=pool_value;
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n) begin state<=WAIT_BLANK;counter<=0;primed<=0;initialized<=0;pool_peak<=0;
 peak_power<=0;peak_bin<=0;peak_hz<=0;peak_valid<=0;
 wave_release<=0;spec_release<=0;end
 else begin
   wave_release<=0;spec_release<=0;
   case(state)
   WAIT_BLANK:if(blank_start) begin counter<=0;state<=CLEAR;end
   CLEAR:begin
     if(counter==32767) begin counter<=0;state<=WAVE_START;end
     else counter<=counter+1'b1;
   end
   WAVE_START:begin counter<=0;primed<=0;state<=wave_pending?WAVE_COPY:SPEC_START;end
   WAVE_COPY:begin
     primed<=1;
     if(counter==512) begin wave_release<=1;counter<=0;state<=SPEC_START;end
     else counter<=counter+1'b1;
   end
   SPEC_START:begin counter<=0;primed<=0;peak_power<=0;peak_bin<=0;state<=spec_pending?SPEC_COPY:WAIT_BLANK;end
   SPEC_COPY:begin
     primed<=1;
     if(primed)pool_peak<=pool_value;
     if(primed && new_peak)begin peak_power<=spec_data;peak_bin<=prev_count[LOGN-2:0];end
     if(counter==(1<<(LOGN-1))) begin
       peak_hz<=candidate_hz;peak_valid<=(new_peak || peak_power!=0);
       spec_release<=1;initialized<=1;state<=WAIT_BLANK;
     end
     else counter<=counter+1'b1;
   end
   default:state<=WAIT_BLANK;
   endcase
 end
 wire label_ink;
 visual_labels #(.SAMPLE_RATE(SAMPLE_RATE)) labels(draw_x,draw_y,peak_valid,peak_hz,label_ink);
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin red<=0;green<=0;blue<=0;out_de<=0;out_hs<=1;out_vs<=1;
 draw_x<=0;draw_y<=0;draw_de<=0;draw_hs<=1;draw_vs<=1;end
 else begin
   draw_x<=x;draw_y<=y;draw_de<=de;draw_hs<=hs;draw_vs<=vs;
   out_de<=draw_de;out_hs<=draw_hs;out_vs<=draw_vs;
   red<=8'd3;green<=8'd8;blue<=8'd16;
   if(draw_de && initialized)begin
     if(draw_x[5:0]==0 || draw_y[5:0]==0)begin red<=12;green<=22;blue<=32;end
     if((draw_x<256 && draw_y==96) || (draw_x>=64 && draw_x<576 && draw_y==448))begin red<=36;green<=48;blue<=64;end
     if(draw_x<256 && draw_y>=32 && draw_y<161 && draw_y=={2'b0,wave_y})begin red<=32;green<=255;blue<=96;end
     if(draw_x>=352 && draw_x<608 && draw_y>=32 && draw_y<160 && phase_pixel)begin red<=32;green<=210;blue<=255;end
     if(draw_x>=64 && draw_x<576 && draw_y>=240 && draw_y<448 && (10'd448-draw_y)<{2'b0,spectrum_sample})begin
       red<=draw_x[8:1];green<=8'd96;blue<=8'd255-draw_x[8:1];
     end
     if(label_ink)begin red<=180;green<=210;blue<=224;end
   end
 end
endmodule
`default_nettype wire
