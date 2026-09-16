`default_nettype none
module performance_mode_controller #(
  parameter int ADDR_W=5,parameter int DURATION_W=24,parameter int LED_COUNT=12,
  parameter logic [1:0] DEMO_WAVEFORM=0,parameter logic [9:0] DEMO_MORPH=0
) (
  input logic clk,input logic rst_n,input logic sample_tick,input logic [1:0] mode,
  input logic live_valid,input logic live_note_on,input logic [6:0] live_note,
  input logic [7:0] live_velocity,input logic [1:0] live_waveform,input logic [9:0] live_morph,
  output logic live_ready,
  output logic event_valid,input logic event_ready,output logic event_note_on,
  output logic [6:0] event_note,output logic [7:0] event_velocity,
  output logic [1:0] event_waveform,output logic [9:0] event_morph,
  output logic [LED_COUNT-1:0] guide_leds,output logic guide_hit,
  output logic [6:0] guide_note,output logic guide_valid,
  output logic [1:0] display_mode,output logic [ADDR_W-1:0] display_score_address
);
  localparam logic [1:0] MODE_FREE=0,MODE_TEACH=1,MODE_DEMO=2;
  localparam logic [1:0] DEMO_ON=0,DEMO_PLAY=1,DEMO_OFF=2;
  logic [1:0] last_mode,demo_state;
  logic [ADDR_W-1:0] score_address;
  logic [6:0] score_note,active_demo_note;
  logic [DURATION_W-1:0] score_duration,duration_remaining;
  logic [7:0] score_velocity;
  logic score_rest,score_valid,demo_note_active,cancel_pending;
  logic accepted_live_note;

  score_rom #(.ADDR_W(ADDR_W),.DURATION_W(DURATION_W)) u_score(
    .address(score_address),.note(score_note),.duration_ticks(score_duration),
    .velocity(score_velocity),.rest(score_rest),.valid(score_valid));
  led_guide #(.LED_COUNT(LED_COUNT)) u_led(
    .enable(mode==MODE_TEACH),.target_valid(score_valid&&!score_rest),.target_note(score_note),
    .note_played(accepted_live_note),.played_note(live_note),.leds(guide_leds),.hit(guide_hit));

  always @* begin
    display_mode=mode;display_score_address=score_address;
    guide_note=score_note;guide_valid=(mode==MODE_TEACH)&&score_valid&&!score_rest;
    live_ready=0;event_valid=0;event_note_on=0;event_note=0;event_velocity=0;
    event_waveform=live_waveform;event_morph=live_morph;
    if(mode!=last_mode) begin
      // One-cycle mode boundary prevents stale score/live state from issuing
      // an event while the sequential state is being reinitialized.
    end else if(cancel_pending) begin
      event_valid=1;event_note_on=0;event_note=active_demo_note;event_velocity=0;
      event_waveform=DEMO_WAVEFORM;event_morph=DEMO_MORPH;
    end else if(mode==MODE_FREE||mode==MODE_TEACH) begin
      live_ready=event_ready;event_valid=live_valid;event_note_on=live_note_on;
      event_note=live_note;event_velocity=live_velocity;
    end else if(mode==MODE_DEMO&&score_valid) begin
      event_note=score_note;event_velocity=score_velocity;
      event_waveform=DEMO_WAVEFORM;event_morph=DEMO_MORPH;
      if(demo_state==DEMO_ON&&!score_rest)begin event_valid=1;event_note_on=1;end
      else if(demo_state==DEMO_OFF)begin event_valid=1;event_note_on=0;event_note=active_demo_note;end
    end
    accepted_live_note=live_valid&&live_ready&&live_note_on;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      last_mode<=MODE_FREE;score_address<='0;demo_state<=DEMO_ON;duration_remaining<='0;
      active_demo_note<='0;demo_note_active<=0;cancel_pending<=0;
    end else begin
      last_mode<=mode;
      if(mode!=last_mode) begin
        if(last_mode==MODE_DEMO&&demo_note_active)cancel_pending<=1;
        score_address<='0;demo_state<=DEMO_ON;duration_remaining<='0;
      end else if(cancel_pending) begin
        if(event_ready)begin cancel_pending<=0;demo_note_active<=0;end
      end else if(mode==MODE_TEACH) begin
        if(!score_valid)score_address<='0;
        else if(score_rest)score_address<=score_address+1'b1;
        else if(accepted_live_note&&live_note==score_note)score_address<=score_address+1'b1;
      end else if(mode==MODE_DEMO) begin
        if(!score_valid)begin score_address<='0;demo_state<=DEMO_ON;end
        else case(demo_state)
          DEMO_ON:begin
            if(score_rest)begin duration_remaining<=(score_duration=='0)?{{(DURATION_W-1){1'b0}},1'b1}:score_duration;demo_state<=DEMO_PLAY;end
            else if(event_ready)begin
              active_demo_note<=score_note;demo_note_active<=1;
              duration_remaining<=(score_duration=='0)?{{(DURATION_W-1){1'b0}},1'b1}:score_duration;
              demo_state<=DEMO_PLAY;
            end
          end
          DEMO_PLAY:if(sample_tick)begin
            if(duration_remaining<=1)begin
              if(score_rest)begin score_address<=score_address+1'b1;demo_state<=DEMO_ON;end
              else demo_state<=DEMO_OFF;
            end else duration_remaining<=duration_remaining-1'b1;
          end
          default:if(event_ready)begin
            demo_note_active<=0;score_address<=score_address+1'b1;demo_state<=DEMO_ON;
          end
        endcase
      end else begin
        score_address<='0;demo_state<=DEMO_ON;duration_remaining<='0;
      end
    end
  end
endmodule
`default_nettype wire
