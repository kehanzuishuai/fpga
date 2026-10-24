`default_nettype none
// Observation only. All inputs are synchronous to the audio clock. No output
// feeds a note-event, source-selection, sample-enable or audio-reset path.
module display_status_adapter #(parameter SAMPLE_RATE=48000)(
 input wire clk,rst_n,pcm_valid,
 input wire signed [23:0] pcm_left,pcm_right,
 input wire keys_valid,input wire [31:0] keys,input wire [223:0] key_map,
 input wire [2:0] instrument,input wire [31:0] voices,input wire [223:0] voice_notes,
 input wire score_owned,switching,score_sounding,score_rest,
 input wire [6:0] score_note,input wire [15:0] score_completed,
 input wire [1:0] performance_mode,input wire [31:0] guide_targets,
 input wire [2:0] guide_state,input wire [15:0] guide_completed,
 input wire status_ready,output wire status_update,output reg [511:0] status_data
);
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
  // Piano partial envelopes are independent; no single true ADSR signal exists.
  // Keep envelope-valid clear rather than substituting a PCM magnitude trace.
  status_data[5]=0;status_data[6]=1;
  status_data[10:8]=instrument;status_data[17:11]=current_note;
  status_data[49:18]=keys;status_data[81:50]=voices;status_data[305:82]=key_map;
  status_data[441:434]=level_l;status_data[449:442]=level_r;
  status_data[454:450]=observed;status_data[455]=1;
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
