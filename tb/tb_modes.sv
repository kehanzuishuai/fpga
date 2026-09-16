`timescale 1ns/1ps
module tb_modes;
  logic clk=0,rst_n=0,sample_tick=1;logic [1:0] mode=0;
  logic live_valid=0,live_note_on=0,live_ready;logic [6:0] live_note=0;
  logic [7:0] live_velocity=0;logic [1:0] live_waveform=0;logic [9:0] live_morph=0;
  logic event_valid,event_ready,event_note_on;logic [6:0] event_note;logic [7:0] event_velocity;
  logic [1:0] event_waveform;logic [9:0] event_morph;logic [11:0] leds;logic guide_hit;
  logic [6:0] guide_note;logic guide_valid;logic [1:0] display_mode;logic [4:0] score_address;
  logic signed [23:0] audio;logic [31:0] active;
  logic [4:0] probe_address=0;logic [6:0] probe_note;logic [23:0] probe_duration;
  logic [7:0] probe_velocity;logic probe_rest,probe_valid;
  integer on_count=0,off_count=0,teach_hit_seen=0,i;
  logic [6:0] last_on_note,last_off_note;logic [7:0] last_on_velocity;
  always #5 clk=~clk;
  performance_mode_controller ctrl(.clk,.rst_n,.sample_tick,.mode,.live_valid,.live_note_on,.live_note,
    .live_velocity,.live_waveform,.live_morph,.live_ready,.event_valid,.event_ready,.event_note_on,
    .event_note,.event_velocity,.event_waveform,.event_morph,.guide_leds(leds),.guide_hit,.guide_note,
    .guide_valid,.display_mode,.display_score_address(score_address));
  synth_event_frontend front(.clk,.rst_n,.sample_tick,.event_valid,.event_note_on,.event_note,
    .event_velocity,.event_waveform,.event_morph,.event_ready,.test_enable(1'b0),.audio_out(audio),.active_debug(active));
  score_rom probe(.address(probe_address),.note(probe_note),.duration_ticks(probe_duration),
    .velocity(probe_velocity),.rest(probe_rest),.valid(probe_valid));
  always @(posedge clk)if(rst_n&&event_valid&&event_ready)begin
    if(event_note_on)begin on_count<=on_count+1;last_on_note<=event_note;last_on_velocity<=event_velocity;end
    else begin off_count<=off_count+1;last_off_note<=event_note;end
    if(guide_hit)teach_hit_seen<=1;
  end
  task live_event(input logic is_on,input [6:0] note_value,input [7:0] velocity_value);
    begin
      while(!live_ready)@(posedge clk);
      @(negedge clk);live_note_on=is_on;live_note=note_value;live_velocity=velocity_value;
      live_waveform=2;live_morph=700;live_valid=1;
      @(negedge clk);live_valid=0;
    end
  endtask
  initial begin
    repeat(4)@(posedge clk);rst_n=1;
    live_event(1,60,99);repeat(3)@(posedge clk);#1;
    if(active[0]!==1||last_on_note!=60||last_on_velocity!=99||event_waveform!=2||event_morph!=700)
      $fatal(1,"free mode did not pass live multidimensional event to synth");

    @(negedge clk);mode=1;repeat(3)@(posedge clk);#1;
    if(!guide_valid||guide_note!=60||score_address!=0||leds==0)$fatal(1,"teaching target initialization failed");
    live_event(1,61,100);repeat(3)@(posedge clk);if(score_address!=0)$fatal(1,"wrong teaching note advanced score");
    live_event(1,60,100);repeat(3)@(posedge clk);#1;
    if(score_address!=1||guide_note!=62||!teach_hit_seen)$fatal(1,"correct teaching note did not advance exactly once");
    repeat(12020)@(posedge clk);if(score_address!=1)$fatal(1,"teaching mode advanced from duration instead of correct note");

    probe_address=4;#1;
    if(!probe_valid||!probe_rest||probe_duration!=6000||probe_velocity!=0)$fatal(1,"score rest event format failed");

    @(negedge clk);mode=2;repeat(5)@(posedge clk);#1;
    if(last_on_note!=60||last_on_velocity!=104||active==0)$fatal(1,"Demo note_on did not enter 32-Voice synth chain");
    i=0;while(off_count<1&&i<12100)begin @(posedge clk);i=i+1;end
    if(off_count<1||last_off_note!=60)$fatal(1,"Demo duration/note_off failed");
    i=0;while(last_on_note!=62&&i<100)begin @(posedge clk);i=i+1;end
    if(last_on_note!=62)$fatal(1,"Demo did not advance to next score event");
    @(negedge clk);mode=0;repeat(5)@(posedge clk);
    if(display_mode!=0)$fatal(1,"mode display/status reservation failed");
    $display("TB_MODES PASS: free, correct-note-only teaching, rest format and timed Demo through 32-Voice synth");
    $finish;
  end
endmodule
