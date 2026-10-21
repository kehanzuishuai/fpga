`default_nettype none
// One shared oscillator/partial scheduler for organ, flute and FM bell, plus
// one KS RAM. Instantiate per voice; do not instantiate four separate banks.
module yinse_aux_voice #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5)(
 input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [2:0] instrument_in,input wire [6:0] note_in,input wire [7:0] velocity_in,
 output wire ready,active,output reg signed [23:0] sample,
 output wire overrun,output wire clipped,output reg [6:0] note
);
 localparam [2:0] IDLE=0,PARTIAL=1,MODULATOR=2,CARRIER=3,OUTPUT=4;
 reg [2:0] state,instrument;
 reg [32:0] phase;reg [31:0] increment,mod_phase,lfo_phase;
 reg [15:0] modulation_level;reg [5:0] modulation_count;
 reg [7:0] velocity;reg [3:0] slot;
 reg signed [27:0] accumulator,raw;
 reg signed [31:0] phase_offset;
 reg [23:0] noise;reg signed [23:0] ks_dc;
 reg local_overrun,local_clipped;
 wire [31:0] note_increment,bell_increment;
 wire [10:0] table_length,ks_length;
 wire signed [15:0] table_tuning,ks_tuning;
 wire note_valid;
 yinse_note_table table_lut(note_in,note_increment,table_length,table_tuning,note_valid);
 yinse_ks_tuning kt(table_length,table_tuning,ks_length,ks_tuning);
 yinse_bell_profile bell(increment,bell_increment);
 wire [15:0] attack_step,decay_step,sustain_level,release_step,envelope;
 wire [4:0] unused_fx_ctrl;wire unused_preset_valid;
 yinse_preset preset(instrument,attack_step,decay_step,sustain_level,release_step,unused_fx_ctrl,unused_preset_valid);
 wire accepted_start=start && note_valid && instrument_in>=1 && instrument_in<=4;
 yinse_envelope env(clk,rst_n,sample_tick,accepted_start,stop,clear,
 attack_step,decay_step,sustain_level,release_step,envelope,active);
 wire signed [23:0] ks_sample;wire ks_busy,ks_overrun,ks_clipped;
 yinse_ks_loop #(.MAX_DELAY(MAX_DELAY),.SEED(SEED)) ks(
 clk,rst_n,sample_tick,accepted_start && instrument_in==3,clear || (accepted_start && instrument_in!=3),
 active && instrument==3,ks_length,ks_tuning,ks_sample,ks_busy,ks_overrun,ks_clipped);
 assign ready=state==IDLE && !ks_busy;
 assign overrun=local_overrun || ks_overrun;assign clipped=local_clipped || ks_clipped;
 wire [31:0] organ_phase,flute_phase;
 wire [7:0] organ_weight,flute_weight;
 yinse_organ_profile organ(slot,phase,increment,organ_phase,organ_weight);
 yinse_flute_profile flute(slot,phase[31:0],increment,flute_phase,flute_weight);
 wire [31:0] sine_phase=(state==MODULATOR)?mod_phase:
  ((state==CARRIER)?(phase[31:0]+phase_offset):((instrument==1)?organ_phase:flute_phase));
 wire signed [15:0] sine;
 yinse_sine_rom sine_rom(sine_phase[31:24],sine);
 wire [7:0] weight=(instrument==1)?organ_weight:flute_weight;
 wire signed [24:0] partial_product=sine*$signed({1'b0,weight});
 wire signed [27:0] partial_wide={{3{partial_product[24]}},partial_product};
 wire signed [27:0] partial_sum=accumulator+partial_wide;
 wire signed [27:0] flute_noise={{4{noise[23]}},noise};
 wire signed [32:0] mod_product=sine*$signed({1'b0,modulation_level});
 wire signed [27:0] carrier_value={{12{sine[15]}},sine}<<<7;
 wire signed [44:0] amplitude_product=raw*$signed({1'b0,envelope});
 wire signed [27:0] enveloped=amplitude_product[43:16];
 wire signed [36:0] velocity_product=enveloped*$signed({1'b0,velocity});
 wire signed [27:0] scaled=velocity_product[34:7];
 wire [15:0] lfo_unsigned=lfo_phase[31]?~lfo_phase[30:15]:lfo_phase[30:15];
 wire signed [15:0] lfo_triangle=lfo_unsigned ^ 16'h8000;
 wire signed [48:0] vibrato_product=$signed({1'b0,increment})*lfo_triangle;
 wire signed [32:0] vibrato_delta=33'(vibrato_product>>>24); // about +/-0.2 percent
 wire [32:0] next_phase=phase+{1'b0,increment}+((instrument==2)?vibrato_delta:33'd0);
 wire signed [24:0] ks_difference={ks_sample[23],ks_sample}-{ks_dc[23],ks_dc};
 wire signed [24:0] dc_wide={ks_dc[23],ks_dc};
 wire signed [24:0] dc_next=dc_wide+(ks_difference>>>10);
 wire [50:0] unused_quantization={sine_phase[23:0],amplitude_product[44],amplitude_product[15:0],
 velocity_product[36:35],velocity_product[6:0],dc_next[24]};
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=IDLE;instrument<=1;note<=0;velocity<=0;phase<=0;increment<=0;mod_phase<=0;lfo_phase<=0;
  modulation_level<=65535;modulation_count<=0;slot<=0;accumulator<=0;raw<=0;phase_offset<=0;
  noise<=SEED;ks_dc<=0;sample<=0;local_overrun<=0;local_clipped<=0;
 end else if(clear)begin state<=IDLE;sample<=0;local_overrun<=0;local_clipped<=0;ks_dc<=0;end
 else if(accepted_start)begin
  state<=IDLE;instrument<=instrument_in;note<=note_in;velocity<=(velocity_in>127)?8'd127:velocity_in;
  phase<=0;increment<=note_increment;mod_phase<=0;lfo_phase<=0;
  modulation_level<=65535;modulation_count<=0;noise<=SEED;ks_dc<=0;sample<=0;
 end else begin
  if(sample_tick && active && state!=IDLE)local_overrun<=1;
  case(state)
   IDLE:if(sample_tick)begin
    if(!active)sample<=0;
    else begin
     phase<=next_phase;lfo_phase<=lfo_phase+32'd447392; // 5 Hz at 48 kHz
     mod_phase<=mod_phase+bell_increment;
     noise<={noise[22:0],noise[23]^noise[22]^noise[21]^noise[16]};
     if(instrument==1 || instrument==2)begin slot<=0;accumulator<=0;state<=PARTIAL;end
     else if(instrument==4)begin
      state<=MODULATOR;modulation_count<=modulation_count+1'b1;
      if(&modulation_count && modulation_level!=0)modulation_level<=modulation_level-(modulation_level>>9)-16'd1;
     end else begin
      ks_dc<=dc_next[23:0];raw<={{3{ks_difference[24]}},ks_difference};state<=OUTPUT;
     end
    end
   end
   PARTIAL:begin
    accumulator<=partial_sum;
    if(slot==((instrument==1)?4'd8:4'd2))begin
     raw<=partial_sum>>>2;
     if(instrument==2)raw<=(partial_sum>>>2)+(flute_noise>>>7);
     state<=OUTPUT;
    end else slot<=slot+1'b1;
   end
   MODULATOR:begin phase_offset<=32'(mod_product>>>1);state<=CARRIER;end
   CARRIER:begin raw<=carrier_value;state<=OUTPUT;end
   OUTPUT:begin
    if(scaled>8388607)begin sample<=24'sh7fffff;local_clipped<=1;end
    else if(scaled< -8388608)begin sample<=24'sh800000;local_clipped<=1;end else sample<=scaled[23:0];
    state<=IDLE;
   end
   default:state<=IDLE;
  endcase
 end
endmodule
`default_nettype wire
