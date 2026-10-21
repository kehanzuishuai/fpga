"""One-time structural time sharing; retain all 32 logical contexts and KS RAMs."""
from pathlib import Path
R=Path(__file__).resolve().parents[2]
p=R/'src/instruments/gongyong/yinse_aux_voice.sv';s=p.read_text()
assert 'module yinse_aux_arithmetic' not in s
s=s.replace('note,{valid,increment,ks_length,ks_tuning,bell_increment});','note,{valid,increment,ks_length,ks_tuning,bell_increment},1\'b1,334\'d0,unused_query);')
s=s.replace(' wire [31:0] increment,bell_increment;', ' wire [398:0] unused_query;\n wire [31:0] increment,bell_increment;',1)
s=s.replace('module yinse_aux_voice_shared #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24\'h713AC5)', 'module yinse_aux_voice_shared #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24\'h713AC5,parameter EXTERNAL_ARITH=0)')
s=s.replace(' input wire [91:0] note_params\n',' input wire [91:0] note_params,\n input wire compute_enable,input wire [333:0] shared_result,output wire [398:0] arithmetic_query\n')
s=s.replace('OUTPUT=4,VELOCITY=5;', 'OUTPUT=4,VELOCITY=5,START_FRAME=6;')
s=s.replace(' reg local_overrun,local_clipped;', ' reg local_overrun,local_clipped;\n reg signed [23:0] ks_previous;reg signed [27:0] enveloped;')
a=s.index(' wire [31:0] organ_phase,flute_phase;');b=s.index(' always @(posedge clk or negedge rst_n)',a)
math=s[a:b].replace(' reg signed [27:0] enveloped;\n','')
interface=''' wire [32:0] next_phase;wire [31:0] next_mod_phase,next_lfo_phase;
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
'''
s=s[:a]+interface+s[b:]
s=s.replace('noise<=SEED;ks_dc<=0;sample<=0;', 'noise<=SEED;ks_dc<=0;ks_previous<=0;sample<=0;')
s=s.replace('local_clipped<=0;ks_dc<=0;end','local_clipped<=0;ks_dc<=0;ks_previous<=0;end')
a=s.index('   IDLE:if(sample_tick)begin');b=s.index('   PARTIAL:begin',a)
s=s[:a]+'''   IDLE:if(sample_tick)begin
    if(!active)sample<=0;
    else if(EXTERNAL_ARITH)begin ks_previous<=ks_sample;state<=START_FRAME;end
    else advance_sample();
   end
   START_FRAME:if(compute_enable)advance_sample();
'''+s[b:]
for state in ['PARTIAL','MODULATOR','CARRIER','OUTPUT','VELOCITY']:
 s=s.replace('   '+state+':begin','   '+state+':if(!EXTERNAL_ARITH || compute_enable)begin')
s=s.replace('raw<=(partial_sum>>>2)+(flute_noise>>>7);','raw<=raw_flute;')
s=s.replace("phase_offset<=32'(mod_product>>>1);",'phase_offset<=phase_offset_next;')
s=s.replace('enveloped<=amplitude_product[43:16];','enveloped<=enveloped_next;')
s=s.replace("    if(scaled>8388607)begin sample<=24'sh7fffff;local_clipped<=1;end\n    else if(scaled< -8388608)begin sample<=24'sh800000;local_clipped<=1;end else sample<=scaled[23:0];",'    sample<=sample_next;if(clipped_next)local_clipped<=1;')
engine='''
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
'''+math+'''
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
'''
s+=engine
bank=R/'src/instruments/gongyong/yinse_aux_bank.sv';bs=bank.read_text()
bs=bs.replace(' genvar g;',''' localparam integer THREADS=(VOICES<8)?VOICES:8;
 localparam integer LANES=VOICES/THREADS;
 localparam integer CW=(THREADS<2)?1:$clog2(THREADS);
 reg [CW-1:0] cursor;
 always @(posedge clk or negedge rst_n)
  if(!rst_n)cursor<=0;else if(THREADS>1)cursor<=cursor+1'b1;else cursor<=0;
 wire [VOICES*399-1:0] queries;wire [LANES*334-1:0] results;
 genvar lane,thread;
 generate for(lane=0;lane<LANES;lane=lane+1)begin:L
  wire [398:0] words[0:THREADS-1];
  for(thread=0;thread<THREADS;thread=thread+1)begin:T
   assign words[thread]=queries[(lane*THREADS+thread)*399+:399];
  end
  yinse_aux_arithmetic math(words[cursor],results[lane*334+:334]);
 end endgenerate
 genvar g;''')
bs=bs.replace(".SEED(24'h713AC5+24'(g))) voice(",".SEED(24'h713AC5+24'(g)),.EXTERNAL_ARITH(1)) voice(")
bs=bs.replace('notes[g*7 +: 7],note_params);',"notes[g*7 +: 7],note_params,cursor==CW'(g%THREADS),results[(g/THREADS)*334+:334],queries[g*399+:399]);")
assert '.EXTERNAL_ARITH(1)' in bs and 'query' in s
top=R/'src/tang_mega_138k_pro_top.v.v';ts=top.read_text()
for line in ['wire [4:0]  event_key_index;','wire [4:0]  fifo_level;']:
 assert ts.count(line)==1;ts=ts.replace(line+'\n','')
ts=ts.replace('wire key_event_ready,bridge_reset_n,remote_tick,engine_idle,engine_clear,switching,score_playing;', 'wire [4:0] event_key_index,fifo_level;\nwire key_event_ready,bridge_reset_n,remote_tick,engine_idle,engine_clear,switching,score_playing;')
p.write_text(s);bank.write_text(bs);top.write_text(ts)
print('Installed four shared arithmetic engines / 32 independent voice contexts; moved forward declarations before use')
