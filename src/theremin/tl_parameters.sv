`default_nettype none
// 64-cycle restoring divider runs per control update, NOT per audio sample.
// phase_inc = frequency_mHz * 2^32 / (SAMPLE_RATE*1000), floor rounding.
module tl_parameters #(parameter integer SAMPLE_RATE=48000,AMP_STEP=274,PITCH_SHIFT=6)(
 input wire clk,rst_n,sample_tick,update,linked,enabled,clear,
 input wire [31:0] frequency_mhz,input wire [15:0] amplitude,
 output reg [31:0] phase_increment,output reg [15:0] level
);
 localparam [32:0] DENOM=33'(SAMPLE_RATE*1000);
 reg pending,busy;reg [31:0] pending_freq;reg [15:0] pending_amp,captured_amp,target_amp;
 reg [63:0] numerator,quotient;reg [32:0] remainder;reg [6:0] bit_count;
 reg [31:0] target_inc;
 wire [32:0] trial={remainder[31:0],numerator[63]};
 wire take=trial>=DENOM;
 wire [63:0] next_quotient={quotient[62:0],take};
 wire [31:0] delta=(target_inc>phase_increment)?target_inc-phase_increment:phase_increment-target_inc;
 wire [31:0] pitch_step=(delta>>PITCH_SHIFT)==0?32'd1:delta>>PITCH_SHIFT;
 wire [15:0] wanted=(linked && enabled)?target_amp:16'd0;
 initial if(SAMPLE_RATE<8000 || SAMPLE_RATE>192000 || AMP_STEP<1 || AMP_STEP>65535 || PITCH_SHIFT<0 || PITCH_SHIFT>16)$fatal(1,"control parameters");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  pending<=0;busy<=0;pending_freq<=0;pending_amp<=0;captured_amp<=0;target_amp<=0;
  numerator<=0;quotient<=0;remainder<=0;bit_count<=0;target_inc<=0;phase_increment<=0;level<=0;
 end else begin
  if(!busy && pending)begin
   busy<=1;pending<=0;numerator<={pending_freq,32'b0};quotient<=0;remainder<=0;bit_count<=0;captured_amp<=pending_amp;
  end else if(busy)begin
   numerator<=numerator<<1;remainder<=take?trial-DENOM:trial;quotient<=next_quotient;
   if(bit_count==63)begin busy<=0;target_inc<=next_quotient[31:0];target_amp<=linked?captured_amp:16'd0;end
   else bit_count<=bit_count+1'b1;
  end
  // Latest update wins; an update during conversion is not dropped.
  if(update)begin pending<=1;pending_freq<=frequency_mhz;pending_amp<=amplitude;end
  if(!linked)target_amp<=0;
  if(clear)level<=0;
  else if(sample_tick)begin
   if(phase_increment<target_inc)phase_increment<=phase_increment+pitch_step;
   else if(phase_increment>target_inc)phase_increment<=phase_increment-pitch_step;
   if(level<wanted)begin
    if({1'b0,wanted}-{1'b0,level}<=17'(AMP_STEP))level<=wanted;else level<=level+16'(AMP_STEP);
   end else if(level>wanted)begin
    if({1'b0,level}-{1'b0,wanted}<=17'(AMP_STEP))level<=wanted;else level<=level-16'(AMP_STEP);
   end
  end
 end
 wire [32:0] unused_quantization={remainder[32],quotient[63:32]};
endmodule
`default_nettype wire
