`default_nettype none
// Observation only. All inputs are synchronous to the audio clock. No output
// feeds a note-event, source-selection, sample-enable or audio-reset path.
module display_status_adapter #(parameter SAMPLE_RATE=48000,ENVELOPE_OBSERVE=0)(
 input wire clk,rst_n,pcm_valid,
 input wire signed [23:0] pcm_left,pcm_right,
 input wire keys_valid,input wire [31:0] keys,input wire [223:0] key_map,
 input wire [2:0] instrument,input wire [31:0] voices,input wire [223:0] voice_notes,
 input wire score_owned,switching,score_sounding,score_rest,
 input wire [6:0] score_note,input wire [15:0] score_completed,
 input wire [1:0] performance_mode,input wire [31:0] guide_targets,
 input wire [2:0] guide_state,input wire [15:0] guide_completed,
 input wire status_ready,output wire status_update,output reg [511:0] status_data,
 input wire [511:0] monitor_levels,input wire [95:0] monitor_phases,
 input wire [31:0] monitor_valid,monitor_done,monitor_starts,
 input wire monitor_clear,monitor_bypass
);
 wire [127:0] envelope_history;wire [4:0] envelope_voice;wire [2:0] envelope_phase;
 generate if(ENVELOPE_OBSERVE!=0)begin:G_ENVELOPE
 visual_envelope_history #(.SAMPLE_RATE(SAMPLE_RATE)) observer(
  .clk(clk),.rst_n(rst_n),.sample_tick(pcm_valid),.clear(monitor_clear),.bypass(monitor_bypass),
  .instrument(instrument),.active(voices),.gains(monitor_levels),.phases(monitor_phases),
  .gain_valid(monitor_valid),.gain_done(monitor_done),.starts(monitor_starts),
  .history(envelope_history),.voice_index(envelope_voice),.phase(envelope_phase));
 end else begin:G_NO_ENVELOPE
 assign envelope_history=0;assign envelope_voice=0;assign envelope_phase=7;
 end endgenerate
 localparam integer WINDOW=SAMPLE_RATE/30;
 reg [10:0] count;reg [23:0] peak_l,peak_r;reg [7:0] level_l,level_r;
 wire [23:0] abs_l=pcm_left[23]?-pcm_left:pcm_left;
 wire [23:0] abs_r=pcm_right[23]?-pcm_right:pcm_right;
 wire [23:0] max_l=abs_l>peak_l?abs_l:peak_l;
 wire [23:0] max_r=abs_r>peak_r?abs_r:peak_r;
 // Full-scale magnitude maps to255, including -8388608. No calibrated dBFS claim.
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin count<=0;peak_l<=0;peak_r<=0;level_l<=0;level_r<=0;end
 else if(pcm_valid)begin
  if(count==WINDOW-1)begin
   count<=0;peak_l<=0;peak_r<=0;
   level_l<=max_l[23]?8'hff:max_l[22:15];
   level_r<=max_r[23]?8'hff:max_r[22:15];
  end else begin count<=count+1'b1;peak_l<=max_l;peak_r<=max_r;end
 end
 assign status_update=rst_n && pcm_valid && status_ready;
 integer i;reg found;reg [6:0] current_note;reg [4:0] observed;
 reg [31:0] targets;
 always @* begin
  found=0;current_note=0;observed=0;targets=0;
  for(i=0;i<32;i=i+1)begin
   if(voices[i] && !found)begin found=1;current_note=voice_notes[i*7+:7];observed=5'(i);end
   if(score_owned && score_sounding && !switching && key_map[i*7+:7]==score_note)targets[i]=1;
  end
  status_data=0;
  status_data[0]=keys_valid;status_data[1]=1;status_data[2]=instrument<=4;
  status_data[3]=found && current_note>=36 && current_note<=96;
  status_data[4]=1;
  // Read-only gain history, never a mixed-PCM magnitude substituted for ADSR.
  // Piano model is explicitly marked as partial-envelope observation.
  status_data[5]=(ENVELOPE_OBSERVE!=0);status_data[6]=1;
  if(ENVELOPE_OBSERVE!=0)begin
   status_data[7]=instrument==0;status_data[433:306]=envelope_history;
   status_data[511:509]=envelope_phase;
  end
  status_data[10:8]=instrument;status_data[17:11]=current_note;
  status_data[49:18]=keys;status_data[81:50]=voices;status_data[305:82]=key_map;
  status_data[441:434]=level_l;status_data[449:442]=level_r;
  status_data[454:450]=(ENVELOPE_OBSERVE!=0)?envelope_voice:observed;status_data[455]=1;
  status_data[457:456]=performance_mode;
  status_data[489:458]=targets;
  status_data[492:490]=!score_owned?3'd0:switching?3'd1:score_rest?3'd6:3'd2;
  status_data[508:493]=score_owned?score_completed:16'd0;
  if(performance_mode==2)begin
   status_data[489:458]=guide_targets;status_data[492:490]=guide_state;
   status_data[508:493]=guide_completed;
  end
 end
endmodule
`default_nettype wire

`default_nettype none
module visual_envelope_history #(parameter integer SAMPLE_RATE=48000)(
 input wire clk,rst_n,sample_tick,clear,bypass,input wire [2:0] instrument,
 input wire [31:0] active,input wire [511:0] gains,input wire [95:0] phases,
 input wire [31:0] gain_valid,gain_done,starts,
 output wire [127:0] history,output reg [4:0] voice_index,output wire [2:0] phase
);
 localparam integer BIN_SAMPLES=SAMPLE_RATE/32;
 reg armed;reg [2:0] previous_instrument;
 reg [15:0] partial_peak,current_gain,note_peak,bin_peak;
 reg [15:0] history_bins[0:14];reg [15:0] bin_counter;
 reg [4:0] newest;integer n;
 always @*begin newest=0;for(integer k=0;k<32;k=k+1)if(starts[k])newest=5'(k);end
 wire [15:0] gain=gains[voice_index*16+:16];
 wire [15:0] collected=(gain_valid[voice_index] && gain>partial_peak)?gain:partial_peak;
 wire [15:0] current_bin=current_gain>bin_peak?current_gain:bin_peak;
 wire [15:0] peak_next=current_gain>note_peak?current_gain:note_peak;
 assign phase=bypass?3'd6:!armed?3'd7:!active[voice_index]?3'd0:phases[voice_index*3+:3];
 function automatic [7:0] normalized(input [15:0] value,peak);
 integer msb,k;reg [23:0] scaled;
 begin
  msb=0;for(k=0;k<16;k=k+1)if(peak[k])msb=k;
  if(peak==0)scaled=0;
  else if(msb>=7)scaled={8'd0,value}>>(msb-7);
  else scaled={8'd0,value}<<(7-msb);
  normalized=(scaled>255)?8'd255:scaled[7:0];
 end endfunction
 genvar g;generate for(g=0;g<15;g=g+1)begin:G_BIN
 assign history[g*8+:8]=normalized(history_bins[g],peak_next);
 end endgenerate
 assign history[120+:8]=normalized(current_bin,peak_next);
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  armed<=0;voice_index<=0;partial_peak<=0;current_gain<=0;note_peak<=0;bin_peak<=0;bin_counter<=0;previous_instrument<=0;
  for(n=0;n<15;n=n+1)history_bins[n]<=0;
 end else begin
  previous_instrument<=instrument;
  if(clear || bypass || (instrument!=previous_instrument && !(|starts)))begin
   armed<=0;voice_index<=0;partial_peak<=0;current_gain<=0;note_peak<=0;bin_peak<=0;bin_counter<=0;
   for(n=0;n<15;n=n+1)history_bins[n]<=0;
  end else if(|starts)begin
   armed<=1;voice_index<=newest;partial_peak<=0;current_gain<=0;note_peak<=0;bin_peak<=0;bin_counter<=0;
   for(n=0;n<15;n=n+1)history_bins[n]<=0;
  end else if(armed)begin
   if(!active[voice_index])begin current_gain<=0;partial_peak<=0;end
   else if(gain_done[voice_index])begin current_gain<=collected;partial_peak<=0;end
   else if(gain_valid[voice_index])partial_peak<=collected;
   if(sample_tick)begin
    note_peak<=peak_next;
    if(bin_counter==BIN_SAMPLES-1)begin
     bin_counter<=0;
     for(n=0;n<14;n=n+1)history_bins[n]<=history_bins[n+1];history_bins[14]<=current_bin;bin_peak<=0;
    end else begin bin_counter<=bin_counter+1'b1;bin_peak<=current_bin;end
   end
  end
 end
 initial if(BIN_SAMPLES<1 || BIN_SAMPLES>65535)$fatal(1,"envelope history sample rate");
endmodule
`default_nettype wire
