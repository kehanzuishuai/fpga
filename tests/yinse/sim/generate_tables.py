"""Offline constants only; hardware needs no Python. Writes only inside yinse."""
from pathlib import Path
import math, json, hashlib, subprocess
ROOT=Path(__file__).resolve().parents[1]

def write(name,text):
    target=(ROOT/name).resolve()
    if ROOT not in target.parents:raise RuntimeError('outside yinse')
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(text,encoding='utf-8')

rows=[]
for k in range(256):
    val=round(32767*math.sin(2*math.pi*k/256))
    rows.append(f" rom[8'd{k}]=16'h{val&65535:04x};")
write('gongyong/yinse_sine_rom.sv','''`default_nettype none
// Generated mathematical sine, not sampled instrument audio. Signed Q1.15.
module yinse_sine_rom(input wire [7:0] address,output wire signed [15:0] sample);
 reg signed [15:0] rom[0:255];
 initial begin
'''+ '\n'.join(rows)+'''
 end
 assign sample=rom[address];
endmodule
`default_nettype wire
''')
rows=[]
for note in range(36,97):
    freq=440*2**((note-69)/12)
    period=48000/freq
    length=math.floor(period)
    # Current + next-sample average has an effective delay N-0.5.
    d=period+0.5-length
    coeff=round((1-d)/(1+d)*32768)
    inc=round(freq/48000*2**32)
    rows.append(f" 7'd{note}:begin increment=32'd{inc};delay_length=11'd{length};tuning=16'h{coeff&65535:04x};valid=1;end")
write('gongyong/yinse_note_table.sv','''`default_nettype none
// 48 kHz ONLY; supported MIDI 36..96. Outside range is rejected, not aliased.
module yinse_note_table(input wire [6:0] note,output reg [31:0] increment,
 output reg [10:0] delay_length,output reg signed [15:0] tuning,output reg valid);
 always @* begin
 increment=0;delay_length=2;tuning=0;valid=0;
 case(note)
'''+ '\n'.join(rows)+'''
 default:begin end
 endcase
 end
endmodule
`default_nettype wire
''')

baseline=ROOT/'sim/outside_before.json'
if not baseline.exists():
    repo=ROOT.parent
    result=subprocess.run(['git','-c','safe.directory='+repo.as_posix(),'ls-files','-z'],cwd=repo,capture_output=True,check=True)
    data={}
    for name in result.stdout.decode().split('\0'):
        if name and not name.startswith('yinse/'):
            p=repo/name
            if p.is_file():data[name]=hashlib.sha256(p.read_bytes()).hexdigest()
    write('sim/outside_before.json',json.dumps(data,indent=2)+'\n')
    print('Protected existing tracked files:',len(data))
print('Generated sine and pitch/tuning tables inside',ROOT)
