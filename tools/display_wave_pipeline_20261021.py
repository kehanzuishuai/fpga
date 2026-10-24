"""Exact waveform interpolation with bounded unsigned reciprocal division."""
from pathlib import Path
def pipeline_wave(s,root):
 r=Path(root)
 (r/'assets/display_wave_position.hex').write_text(''.join(f'{((((x*32)//39)&511)<<6)|((x*32)%39):04x}\n' for x in range(4096)))
 start=s.index(' wire [8:0] wave_index=');end=s.index(' wire [8:0] next_index=',start)
 s=s[:start]+''' // Exact index/remainder for all 4096 local X values. The four zero
 // fraction bits are reconstructed after the ROM, avoiding a wide divider.
 (* syn_romstyle="block_rom" *) reg [14:0] wave_position_rom[0:4095];
 reg [14:0] wave_position_q;
 initial $readmemh("assets/display_wave_position.hex",wave_position_rom);
 always @(posedge clk)wave_position_q<=wave_position_rom[local_wave_x];
 wire [8:0] wave_index=wave_position_q[14:6];
'''+s[end:]
 s=s.replace("wave_fraction_q<=10'((32'(local_wave_x)*512)%624);","wave_fraction_q<={wave_position_q[5:0],4'd0};")
 start=s.index("  wave_sample<=16'(");end=s.index('  wave_previous<=',start)
 s=s[:start]+s[end:]
 # Original numerator is within +/-32768*624. Divide the nonnegative magnitude
 # by 16, then use an exact reciprocal for /39, with a registered product.
 magic=((1<<26)+38)//39
 assert all(((v*magic)>>26)==v//39 for v in range(1277953))
 at=s.index(' wire signed [31:0] scaled_sample=')
 logic=f''' // Five additional clocks relative to the original waveform result:
 // index ROM + products + sum + magnitude + reciprocal + restored sign.
 reg signed [26:0] wave_product_a,wave_product_b,wave_sum;
 reg [20:0] wave_magnitude;reg wave_negative,wave_reciprocal_negative;
 reg [41:0] wave_reciprocal;
 always @(posedge clk)begin
  wave_product_a<=$signed(wave_sample_q)*$signed(11'd624-{{1'b0,wave_fraction_q}});
  wave_product_b<=$signed(wave_next_q)*$signed({{1'b0,wave_fraction_q}});
  wave_sum<=wave_product_a+wave_product_b;
  wave_magnitude<=21'((wave_sum<0?-wave_sum:wave_sum)>>4);wave_negative<=wave_sum<0;
  wave_reciprocal<=42'(wave_magnitude)*42'd{magic};wave_reciprocal_negative<=wave_negative;
  wave_sample<=wave_reciprocal_negative?-16'(wave_reciprocal>>26):16'(wave_reciprocal>>26);
 end
'''
 s=s[:at]+logic+s[at:]
 first=s.index(' wire [11:0] wave_y=');last=s.index(' wire [11:0] wave_min=',first)
 s=s[:first]+''' reg [11:0] wave_y,wave_prev_y;
 always @(posedge clk)begin
  wave_y<=12'(32'sd322-scaled_sample);wave_prev_y<=12'(32'sd322-scaled_previous);
 end
'''+s[last:]
 return s
