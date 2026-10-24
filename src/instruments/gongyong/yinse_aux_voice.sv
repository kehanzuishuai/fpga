`default_nettype none
// Public standalone interface. A bank instead instantiates the shared-input
// core below so all voices use one stateless note table and ratio calculation.
module yinse_aux_voice #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5)(
 input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [2:0] instrument_in,input wire [6:0] note_in,input wire [7:0] velocity_in,
 output wire ready,active,output wire signed [23:0] sample,
 output wire overrun,clipped,output wire [6:0] note
);
 wire [398:0] unused_query;
 wire [31:0] increment,bell_increment;wire [10:0] length,ks_length;
 wire signed [15:0] tuning,ks_tuning;wire valid;
 yinse_note_table table_lut(note_in,increment,length,tuning,valid);
 yinse_ks_tuning kt(length,tuning,ks_length,ks_tuning);
 yinse_bell_profile bell(increment,bell_increment);
 yinse_aux_voice_shared #(.MAX_DELAY(MAX_DELAY),.SEED(SEED)) core(
  clk,rst_n,sample_tick,start,stop,clear,instrument_in,note_in,velocity_in,
  ready,active,sample,overrun,clipped,note,{valid,increment,ks_length,ks_tuning,bell_increment},1'b1,334'd0,unused_query);
endmodule
`default_nettype none
// One shared oscillator/partial scheduler for organ, flute and FM bell, plus
// one KS RAM. Instantiate per voice; do not instantiate four separate banks.
module yinse_aux_voice_shared #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5,parameter EXTERNAL_ARITH=0)(
 input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [2:0] instrument_in,input wire [6:0] note_in,input wire [7:0] velocity_in,
 output wire ready,active,output reg signed [23:0] sample,
 output wire overrun,output wire clipped,output reg [6:0] note,
 input wire [91:0] note_params,
 input wire compute_enable,input wire [333:0] shared_result,output wire [398:0] arithmetic_query
);
 wire [$clog2(MAX_DELAY)-1:0] unused_address;
 wire unused_read,unused_write;wire[23:0] unused_data;
 yinse_aux_voice_context #(.MAX_DELAY(MAX_DELAY),.SEED(SEED),.EXTERNAL_ARITH(EXTERNAL_ARITH)) context_voice(
  clk,rst_n,sample_tick,start,stop,clear,instrument_in,note_in,velocity_in,
  ready,active,sample,overrun,clipped,note,note_params,compute_enable,shared_result,arithmetic_query,
  unused_address,unused_read,unused_write,unused_data,24'd0);
endmodule
module yinse_aux_voice_context #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5,parameter EXTERNAL_ARITH=0,parameter EXTERNAL_KS_MEMORY=0)(
 input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [2:0] instrument_in,input wire [6:0] note_in,input wire [7:0] velocity_in,
 output wire ready,active,output reg signed [23:0] sample,
 output wire overrun,output wire clipped,output reg [6:0] note,
 input wire [91:0] note_params,
 input wire compute_enable,input wire [333:0] shared_result,output wire [398:0] arithmetic_query,
 output wire [$clog2(MAX_DELAY)-1:0] ks_memory_address,
 output wire ks_memory_read,ks_memory_write,output wire [23:0] ks_memory_write_data,
 input wire [23:0] ks_memory_read_data
);
 localparam [2:0] IDLE=0,PARTIAL=1,MODULATOR=2,CARRIER=3,OUTPUT=4,VELOCITY=5,START_FRAME=6;
 reg [2:0] state,instrument;
 reg [32:0] phase;reg [31:0] increment,mod_phase,lfo_phase;
 reg [15:0] modulation_level;reg [5:0] modulation_count;
 reg [7:0] velocity;reg [3:0] slot;
 reg signed [27:0] accumulator,raw;
 reg signed [31:0] phase_offset;
 reg [23:0] noise;reg signed [23:0] ks_dc;
 reg local_overrun,local_clipped;
 reg signed [23:0] ks_previous;reg signed [27:0] enveloped;
 wire [31:0] note_increment,bell_load_increment;
 reg [31:0] bell_increment;
 wire [10:0] ks_length;wire signed [15:0] ks_tuning;wire note_valid;
 assign {note_valid,note_increment,ks_length,ks_tuning,bell_load_increment}=note_params;
 wire [15:0] attack_step,decay_step,sustain_level,release_step,envelope;
 wire [4:0] unused_fx_ctrl;wire unused_preset_valid;
 yinse_preset preset(instrument,attack_step,decay_step,sustain_level,release_step,unused_fx_ctrl,unused_preset_valid);
 wire accepted_start=start && note_valid && instrument_in>=1 && instrument_in<=4;
 yinse_envelope env(clk,rst_n,sample_tick,accepted_start,stop,clear,
 attack_step,decay_step,sustain_level,release_step,envelope,active);
 wire signed [23:0] ks_sample;wire ks_busy,ks_overrun,ks_clipped;
 yinse_ks_loop_core #(.MAX_DELAY(MAX_DELAY),.SEED(SEED),.EXTERNAL_MEMORY(EXTERNAL_KS_MEMORY)) ks(
 clk,rst_n,sample_tick,accepted_start && instrument_in==3,clear || (accepted_start && instrument_in!=3),
 active && instrument==3,ks_length,ks_tuning,ks_sample,ks_busy,ks_overrun,ks_clipped,
 ks_memory_address,ks_memory_read,ks_memory_write,ks_memory_write_data,ks_memory_read_data);
 assign ready=state==IDLE && !ks_busy;
 assign overrun=local_overrun || ks_overrun;assign clipped=local_clipped || ks_clipped;
 wire [32:0] next_phase;wire [31:0] next_mod_phase,next_lfo_phase;
 wire signed [27:0] partial_sum,raw_flute,carrier_value,enveloped_next,ks_raw;
 wire signed [31:0] phase_offset_next;wire signed [23:0] sample_next,dc_next;
 wire clipped_next;wire [15:0] next_modulation_level;wire [333:0] arithmetic_result;
 wire signed [23:0] ks_math_sample=EXTERNAL_ARITH?ks_previous:ks_sample;
 assign arithmetic_query={state,instrument,slot,phase,increment,mod_phase,lfo_phase,modulation_level,
  accumulator,raw,phase_offset,noise,velocity,enveloped,envelope,ks_math_sample,ks_dc,bell_increment};
 generate if(EXTERNAL_ARITH)begin:G_SHARED
  assign arithmetic_result=shared_result;
 end else begin:G_LOCAL
  yinse_aux_arithmetic math(arithmetic_query,arithmetic_result);
 end endgenerate
 assign {next_phase,next_mod_phase,next_lfo_phase,partial_sum,raw_flute,phase_offset_next,
  carrier_value,enveloped_next,sample_next,clipped_next,dc_next,ks_raw,next_modulation_level}=arithmetic_result;
 task automatic advance_sample;
 begin
  phase<=next_phase;lfo_phase<=next_lfo_phase;mod_phase<=next_mod_phase;
  noise<={noise[22:0],noise[23]^noise[22]^noise[21]^noise[16]};
  if(instrument==1 || instrument==2)begin slot<=0;accumulator<=0;state<=PARTIAL;end
  else if(instrument==4)begin
   state<=MODULATOR;modulation_count<=modulation_count+1'b1;
   if(&modulation_count && modulation_level!=0)modulation_level<=next_modulation_level;
  end else begin ks_dc<=dc_next;raw<=ks_raw;state<=OUTPUT;end
 end
 endtask
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=IDLE;instrument<=1;note<=0;velocity<=0;phase<=0;increment<=0;bell_increment<=0;mod_phase<=0;lfo_phase<=0;
  modulation_level<=65535;modulation_count<=0;slot<=0;accumulator<=0;raw<=0;phase_offset<=0;
  noise<=SEED;ks_dc<=0;ks_previous<=0;sample<=0;enveloped<=0;local_overrun<=0;local_clipped<=0;
 end else if(clear)begin state<=IDLE;sample<=0;local_overrun<=0;local_clipped<=0;ks_dc<=0;ks_previous<=0;end
 else if(accepted_start)begin
  state<=IDLE;instrument<=instrument_in;note<=note_in;velocity<=(velocity_in>127)?8'd127:velocity_in;
  phase<=0;increment<=note_increment;bell_increment<=bell_load_increment;mod_phase<=0;lfo_phase<=0;
  modulation_level<=65535;modulation_count<=0;noise<=SEED;ks_dc<=0;ks_previous<=0;sample<=0;
 end else begin
  if(sample_tick && active && state!=IDLE)local_overrun<=1;
  case(state)
   IDLE:if(sample_tick)begin
    if(!active)sample<=0;
    else if(EXTERNAL_ARITH)begin ks_previous<=ks_sample;state<=START_FRAME;end
    else advance_sample();
   end
   START_FRAME:if(compute_enable)advance_sample();
   PARTIAL:if(!EXTERNAL_ARITH || compute_enable)begin
    accumulator<=partial_sum;
    if(slot==((instrument==1)?4'd8:4'd2))begin
     raw<=partial_sum>>>2;
     if(instrument==2)raw<=raw_flute;
     state<=OUTPUT;
    end else slot<=slot+1'b1;
   end
   MODULATOR:if(!EXTERNAL_ARITH || compute_enable)begin phase_offset<=phase_offset_next;state<=CARRIER;end
   CARRIER:if(!EXTERNAL_ARITH || compute_enable)begin raw<=carrier_value;state<=OUTPUT;end
   OUTPUT:if(!EXTERNAL_ARITH || compute_enable)begin enveloped<=enveloped_next;state<=VELOCITY;end
   VELOCITY:if(!EXTERNAL_ARITH || compute_enable)begin
    sample<=sample_next;if(clipped_next)local_clipped<=1;
    state<=IDLE;
   end
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire

`default_nettype none
// Pure combinational arithmetic. A bank multiplexes eight independent contexts
// into each of four engines; each context completes in <=96 of 256 clocks.
module yinse_aux_arithmetic(input wire [398:0] query,output wire [333:0] result);
 localparam [2:0] PARTIAL=1,MODULATOR=2,CARRIER=3,OUTPUT=4,VELOCITY=5;
 wire [2:0] state,instrument;wire [3:0] slot;wire [32:0] phase;
 wire [31:0] increment,mod_phase,lfo_phase,bell_increment;
 wire [15:0] modulation_level,envelope;wire [23:0] noise;wire [7:0] velocity;
 wire signed [27:0] accumulator,raw,enveloped;wire signed [31:0] phase_offset;
 wire signed [23:0] ks_sample,ks_dc;
 assign {state,instrument,slot,phase,increment,mod_phase,lfo_phase,modulation_level,
  accumulator,raw,phase_offset,noise,velocity,enveloped,envelope,ks_sample,ks_dc,bell_increment}=query;
 wire [31:0] organ_phase,flute_phase;
 wire [7:0] organ_weight,flute_weight;
 // Accepted notes are 36..96: max increment 187278874, and even the
 // highest (8x) drawbar stays below 2^31 (Nyquist). Thus every profile
 // partial is in band; constant zero removes replicated alias checks.
 // The public profile modules retain their generic Nyquist protection.
 yinse_organ_profile organ(slot,phase,32'd0,organ_phase,organ_weight);
 yinse_flute_profile flute(slot,phase[31:0],32'd0,flute_phase,flute_weight);
 wire [31:0] sine_phase=(state==MODULATOR)?mod_phase:
  ((state==CARRIER)?(phase[31:0]+phase_offset):((instrument==1)?organ_phase:flute_phase));
 wire signed [15:0] sine;
 yinse_sine_rom sine_rom(sine_phase[31:24],sine);
 wire [7:0] weight=(instrument==1)?organ_weight:flute_weight;
 // A single scheduled multiplier per voice. Different operations occur in
 // different states; explicit operand muxes prevent four physical DSP paths.
 reg signed [35:0] mac_a;
 reg signed [17:0] mac_b;
 always @* begin
  mac_a={{3{1'b0}},increment};mac_b={{2{lfo_triangle[15]}},lfo_triangle};
  case(state)
   PARTIAL:begin mac_a={{20{sine[15]}},sine};mac_b={10'd0,weight};end
   MODULATOR:begin mac_a={{20{sine[15]}},sine};mac_b={2'd0,modulation_level};end
   OUTPUT:begin mac_a={{8{raw[27]}},raw};mac_b={2'd0,envelope};end
   VELOCITY:begin mac_a={{8{enveloped[27]}},enveloped};mac_b={10'd0,velocity};end
   default:begin end
  endcase
 end
 wire signed [53:0] mac_product=mac_a*mac_b;
 wire signed [24:0] partial_product=mac_product[24:0];
 wire signed [27:0] partial_wide={{3{partial_product[24]}},partial_product};
 wire signed [27:0] partial_sum=accumulator+partial_wide;
 wire signed [27:0] flute_noise={{4{noise[23]}},noise};
 wire signed [32:0] mod_product=mac_product[32:0];
 wire signed [27:0] carrier_value={{12{sine[15]}},sine}<<<7;
 wire signed [44:0] amplitude_product=mac_product[44:0];
 wire signed [36:0] velocity_product=mac_product[36:0];
 wire signed [27:0] scaled=velocity_product[34:7];
 wire [15:0] lfo_unsigned=lfo_phase[31]?~lfo_phase[30:15]:lfo_phase[30:15];
 wire signed [15:0] lfo_triangle=lfo_unsigned ^ 16'h8000;
 wire signed [48:0] vibrato_product=mac_product[48:0];
 wire signed [32:0] vibrato_delta=33'(vibrato_product>>>24); // about +/-0.2 percent
 wire [32:0] next_phase=phase+{1'b0,increment}+((instrument==2)?vibrato_delta:33'd0);
 wire signed [24:0] ks_difference={ks_sample[23],ks_sample}-{ks_dc[23],ks_dc};
 wire signed [24:0] dc_wide={ks_dc[23],ks_dc};
 wire signed [24:0] dc_next=dc_wide+(ks_difference>>>10);
 wire [50:0] unused_quantization={sine_phase[23:0],amplitude_product[44],amplitude_product[15:0],
 velocity_product[36:35],velocity_product[6:0],dc_next[24]};

 reg signed [23:0] sample_next;reg clipped_next;
 always @* begin
  clipped_next=0;sample_next=scaled[23:0];
  if(scaled>8388607)begin sample_next=24'sh7fffff;clipped_next=1;end
  else if(scaled< -8388608)begin sample_next=24'sh800000;clipped_next=1;end
 end
 wire signed [27:0] raw_flute=(partial_sum>>>2)+(flute_noise>>>7);
 wire [31:0] next_mod_phase=mod_phase+bell_increment;
 wire [31:0] next_lfo_phase=lfo_phase+32'd447392;
 wire [15:0] next_modulation_level=modulation_level-(modulation_level>>9)-16'd1;
 assign result={next_phase,next_mod_phase,next_lfo_phase,partial_sum,raw_flute,32'(mod_product>>>1),
  carrier_value,amplitude_product[43:16],sample_next,clipped_next,dc_next[23:0],
  {{3{ks_difference[24]}},ks_difference},next_modulation_level};
endmodule
`default_nettype wire
