`default_nettype none
// Pure board-independent guide mapping.  Score progression is owned by the
// mode controller, so elapsed duration can never skip a teaching note.
module led_guide #(
  parameter int LED_COUNT=12
) (
  input logic enable,input logic target_valid,input logic [6:0] target_note,
  input logic note_played,input logic [6:0] played_note,
  output logic [LED_COUNT-1:0] leds,output logic hit
);
  localparam logic [6:0] LED_COUNT_7=LED_COUNT[6:0];
  always @* begin
    hit=enable&&target_valid&&note_played&&(played_note==target_note);
    leds='0;
    if(enable&&target_valid)
      leds={{(LED_COUNT-1){1'b0}},1'b1}<<(target_note%LED_COUNT_7);
  end
endmodule
`default_nettype wire
