`default_nettype none
package synth_pkg;
  localparam int WAVE_SINE     = 0;
  localparam int WAVE_SQUARE   = 1;
  localparam int WAVE_SAW      = 2;
  localparam int WAVE_TRIANGLE = 3;

  function automatic logic signed [23:0] sat24(input logic signed [31:0] x);
    if (x > 32'sh007f_ffff)      sat24 = 24'sh7f_ffff;
    else if (x < -32'sh0080_0000) sat24 = -24'sh80_0000;
    else                          sat24 = x[23:0];
  endfunction
endpackage
`default_nettype wire
