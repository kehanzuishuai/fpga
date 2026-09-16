`default_nettype none
module waveform_set #(parameter int SAMPLE_W=24) (
  input logic [31:0] phase,
  output logic signed [SAMPLE_W-1:0] sine,square,saw,triangle
);
  // sin(k*pi/128), k=0..64.  Including the endpoint makes the exact
  // pi/2 and 3*pi/2 phase codes reach the intended full-scale peak.
  function automatic logic [15:0] sin_q(input logic [6:0] a);
    case(a)
      0:sin_q=0;1:sin_q=804;2:sin_q=1608;3:sin_q=2410;4:sin_q=3212;5:sin_q=4011;6:sin_q=4808;7:sin_q=5602;
      8:sin_q=6393;9:sin_q=7179;10:sin_q=7962;11:sin_q=8739;12:sin_q=9512;13:sin_q=10278;14:sin_q=11039;15:sin_q=11793;
      16:sin_q=12539;17:sin_q=13279;18:sin_q=14010;19:sin_q=14732;20:sin_q=15446;21:sin_q=16151;22:sin_q=16846;23:sin_q=17530;
      24:sin_q=18204;25:sin_q=18868;26:sin_q=19519;27:sin_q=20159;28:sin_q=20787;29:sin_q=21403;30:sin_q=22005;31:sin_q=22594;
      32:sin_q=23170;33:sin_q=23731;34:sin_q=24279;35:sin_q=24811;36:sin_q=25329;37:sin_q=25832;38:sin_q=26319;39:sin_q=26790;
      40:sin_q=27245;41:sin_q=27683;42:sin_q=28105;43:sin_q=28510;44:sin_q=28898;45:sin_q=29268;46:sin_q=29621;47:sin_q=29956;
      48:sin_q=30273;49:sin_q=30571;50:sin_q=30852;51:sin_q=31113;52:sin_q=31356;53:sin_q=31580;54:sin_q=31785;55:sin_q=31971;
      56:sin_q=32137;57:sin_q=32285;58:sin_q=32412;59:sin_q=32521;60:sin_q=32609;61:sin_q=32678;62:sin_q=32728;63:sin_q=32757;
      default:sin_q=32767;
    endcase
  endfunction
  logic [6:0] lut_index; logic sine_negative; logic [15:0] sine_magnitude;
  logic signed [23:0] sine24,square24,saw24,triangle24;
  logic fraction_nonzero;
  always @* begin
    case(phase[31:30])
      2'b00:begin lut_index={1'b0,phase[29:24]};sine_negative=0;end
      2'b01:begin lut_index=7'd64-{1'b0,phase[29:24]};sine_negative=0;end
      2'b10:begin lut_index={1'b0,phase[29:24]};sine_negative=1;end
      default:begin lut_index=7'd64-{1'b0,phase[29:24]};sine_negative=1;end
    endcase
    sine_magnitude=sin_q(lut_index);
    sine24=sine_negative?-$signed({sine_magnitude,8'b0}):$signed({sine_magnitude,8'b0});
    // The low DDS bits are retained as a fractional remainder.  Rounding the
    // 24-bit saw upward when that remainder is non-zero consumes the complete
    // accumulator without adding another multiplier to every Voice.
    fraction_nonzero=|phase[7:0];
    if(fraction_nonzero && phase[31:8]!=24'h7f_ffff)
      saw24=$signed(phase[31:8])+24'sd1;
    else saw24=$signed(phase[31:8]);
    triangle24=phase[31]?$signed({1'b0,~phase[30:8]}):$signed({1'b0,phase[30:8]});
    triangle24=(triangle24<<<1)-24'sh7f_ffff;
    square24=phase[31]?-24'sh7f_ffff:24'sh7f_ffff;
  end
  generate
    if(SAMPLE_W<24) begin:G_NARROW
      always @* begin sine=sine24[23 -: SAMPLE_W];square=square24[23 -: SAMPLE_W];saw=saw24[23 -: SAMPLE_W];triangle=triangle24[23 -: SAMPLE_W];end
    end else if(SAMPLE_W==24) begin:G_NATIVE
      always @* begin sine=sine24;square=square24;saw=saw24;triangle=triangle24;end
    end else begin:G_WIDE
      always @* begin sine={sine24,{(SAMPLE_W-24){1'b0}}};square={square24,{(SAMPLE_W-24){1'b0}}};saw={saw24,{(SAMPLE_W-24){1'b0}}};triangle={triangle24,{(SAMPLE_W-24){1'b0}}};end
    end
  endgenerate
endmodule
`default_nettype wire
