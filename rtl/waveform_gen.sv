`default_nettype none
module waveform_gen #(
  parameter int SAMPLE_W = 24
) (
  input logic [31:0] phase,
  input logic [1:0] waveform,
  output logic signed [SAMPLE_W-1:0] sample
);
  // Quarter sine table, normalized to signed Q1.23. The 64 entries preserve
  // synthesis portability while giving a smooth enough musical oscillator.
  function automatic logic [15:0] sin_q(input logic [5:0] a);
    case(a)
      0:sin_q=0;1:sin_q=817;2:sin_q=1634;3:sin_q=2451;4:sin_q=3267;5:sin_q=4083;6:sin_q=4899;7:sin_q=5714;
      8:sin_q=6527;9:sin_q=7340;10:sin_q=8152;11:sin_q=8962;12:sin_q=9771;13:sin_q=10578;14:sin_q=11384;15:sin_q=12187;
      16:sin_q=12988;17:sin_q=13787;18:sin_q=14583;19:sin_q=15376;20:sin_q=16167;21:sin_q=16954;22:sin_q=17738;23:sin_q=18519;
      24:sin_q=19296;25:sin_q=20069;26:sin_q=20838;27:sin_q=21603;28:sin_q=22364;29:sin_q=23120;30:sin_q=23871;31:sin_q=24618;
      32:sin_q=25360;33:sin_q=26097;34:sin_q=26829;35:sin_q=27555;36:sin_q=28276;37:sin_q=28992;38:sin_q=29701;39:sin_q=30405;
      40:sin_q=31103;41:sin_q=31794;42:sin_q=32479;43:sin_q=33158;44:sin_q=33829;45:sin_q=34494;46:sin_q=35152;47:sin_q=35803;
      48:sin_q=36447;49:sin_q=37083;50:sin_q=37712;51:sin_q=38333;52:sin_q=38947;53:sin_q=39553;54:sin_q=40151;55:sin_q=40740;
      56:sin_q=41321;57:sin_q=41894;58:sin_q=42458;59:sin_q=43013;60:sin_q=43559;61:sin_q=44097;62:sin_q=44625;default:sin_q=45145;
    endcase
  endfunction
  logic [5:0] idx;
  logic neg;
  logic signed [23:0] sine_v, saw_v, tri_v;
  logic [15:0] mag;
  always @* begin
    case (phase[31:30])
      2'b00: begin idx=phase[29:24]; neg=1'b0; end
      2'b01: begin idx=~phase[29:24]; neg=1'b0; end
      2'b10: begin idx=phase[29:24]; neg=1'b1; end
      default: begin idx=~phase[29:24]; neg=1'b1; end
    endcase
    mag=sin_q(idx); sine_v = neg ? -$signed({1'b0,mag,7'b0}) : $signed({1'b0,mag,7'b0});
    saw_v = $signed({phase[31],phase[30:8]});
    tri_v = phase[31] ? $signed({1'b0,~phase[30:8]}) : $signed({1'b0,phase[30:8]});
    tri_v = (tri_v <<< 1) - 24'sh7f_ffff;
    case(waveform)
      2'd0: sample=sine_v;
      2'd1: sample=phase[31] ? -24'sh7f_ffff : 24'sh7f_ffff;
      2'd2: sample=saw_v;
      default: sample=tri_v;
    endcase
  end
endmodule
`default_nettype wire
