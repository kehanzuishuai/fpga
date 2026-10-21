`default_nettype none
module yinse_controls #(parameter integer DEBOUNCE_CYCLES=122880,
 parameter integer FADE_SAMPLES=240,parameter integer KEYS=16)(
 input wire clk,rst_n,sample_tick,button_next_n,button_previous_n,loader_busy,
 input wire [KEYS-1:0] keys_down,
 output wire [2:0] current_id,requested_id,output wire [15:0] gain,
 output wire block_events,flush_events,clear_aux,committed,switching
);
 wire next_pulse,previous_pulse,next_down,previous_down;
 yinse_button #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) n(clk,rst_n,button_next_n,next_pulse,next_down);
 yinse_button #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) p(clk,rst_n,button_previous_n,previous_pulse,previous_down);
 // Two stable buttons held together do not issue a direction request.
 yinse_selector selector(clk,rst_n,next_pulse && !previous_down,previous_pulse && !next_down,requested_id);
 yinse_switch #(.FADE_SAMPLES(FADE_SAMPLES),.KEYS(KEYS)) sw(
 clk,rst_n,sample_tick,requested_id,keys_down,loader_busy,current_id,gain,
 block_events,flush_events,clear_aux,committed,switching);
endmodule
`default_nettype wire
