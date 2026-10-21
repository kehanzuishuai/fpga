`default_nettype none
// Offline table handles fractional delay + averaging-filter half-sample delay.
// Outputs are generated in gongyong/yinse_note_table.sv. No runtime divider.
module yinse_ks_tuning(input wire [10:0] integer_delay,
 input wire signed [15:0] allpass_coefficient,
 output wire [10:0] delay_length,output wire signed [15:0] tuning);
 assign delay_length=integer_delay;
 assign tuning=allpass_coefficient;
endmodule
`default_nettype wire
