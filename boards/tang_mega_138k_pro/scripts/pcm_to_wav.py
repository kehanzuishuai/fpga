"""Development PCM export, never included in FPGA runtime."""
import argparse,wave
from pathlib import Path

def write_wav(path,samples,sample_rate=48000):
    data=bytearray()
    for sample in samples:
        value=int(sample)
        if not -(1<<23)<=value<(1<<23):raise ValueError('24-bit PCM overflow')
        data.extend((value & 0xffffff).to_bytes(3,'little'))
    with wave.open(str(path),'wb') as out:
        out.setnchannels(1);out.setsampwidth(3);out.setframerate(sample_rate)
        out.writeframes(data)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description='Signed24-bit integer text PCM to mono WAV')
    parser.add_argument('input',type=Path);parser.add_argument('output',type=Path)
    parser.add_argument('--sample-rate',type=int,default=48000)
    parser.add_argument('--column',type=int,default=-1)
    parser.add_argument('--scenario',type=int)
    args=parser.parse_args()
    rows=[list(map(int,line.split())) for line in args.input.read_text().splitlines() if line.strip()]
    values=[r[args.column] for r in rows if args.scenario is None or r[0]==args.scenario]
    write_wav(args.output,values,args.sample_rate)
    print(f'PASS wrote{len(values)} mono24-bit samples at{args.sample_rate}Hz')
