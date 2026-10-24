"""Bound live display numbers and MIDI note arithmetic to their actual widths."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];p=R/'src/display/visual_labels.sv';s=p.read_text()
A=R/'audit/display_integration_20261021/optimization';b=A/'visual_labels.before_digit_bounds.sv'
if b.exists():raise RuntimeError('Already applied')
b.write_bytes(p.read_bytes())
# Every selected value is a 16-bit peak/completed count, <=32 voice/key count,
# sample-rate kHz or <=Nyquist axis label; the production rate is 48000 Hz.
s=s.replace('decimal(input [31:0] v,','decimal(input [15:0] v,')
s=s.replace('decimal_trim(input [31:0] v,','decimal_trim(input [15:0] v,')
for divisor in [10000,1000,100,10]:
 s=s.replace(f'v/{divisor}',f"v/16'd{divisor}")
s=s.replace('v%10',"v%16'd10").replace(')%10',")%16'd10")
old="integer pc;begin pc=32'(note)%12;note_char=16'd32;"
new="reg [3:0] pc,octave;begin pc=note%7'd12;octave=note/7'd12-7'd1;note_char=16'd32;"
assert old in s;s=s.replace(old,new)
s=s.replace("16'd48+16'(32'(note)/12-1)","16'd48+{12'd0,octave}")
s=s.replace('key_char(input integer key,input integer pos)', 'key_char(input [4:0] key,input [5:0] pos)')
p.write_text(s);print('Bounded selected 16-bit numbers and valid MIDI note arithmetic')
