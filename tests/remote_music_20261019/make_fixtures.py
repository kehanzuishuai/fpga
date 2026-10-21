from pathlib import Path
import struct,math
out=Path(__file__).resolve().parent/'out';out.mkdir(exist_ok=True)
def chunk(name,data):return name+struct.pack('<I',len(data))+data+(b'\0' if len(data)&1 else b'')
for name,bits,channels,rate,n in [('stereo24_48000',24,2,48000,12000),('mono16_44100',16,1,44100,3000),('stereo16_48000',16,2,48000,7),('stereo24_dac',24,2,48000,256)]:
 frames=[];data=bytearray()
 for i in range(n):
  samples=[int(math.sin(2*math.pi*440*i/rate)*.6*((1<<(bits-1))-1)),int(math.cos(2*math.pi*700*i/rate)*.3*((1<<(bits-1))-1))]
  if channels==1:samples[1]=samples[0]
  frames.append([s<<(24-bits) for s in samples])
  for s in samples[:channels]:data+=int(s).to_bytes(bits//8,'little',signed=True)
 fmt=struct.pack('<HHIIHH',1,channels,rate,rate*channels*(bits//8),channels*(bits//8),bits)
 body=b'WAVE'+chunk(b'JUNK',b'odd')+chunk(b'fmt ',fmt)+chunk(b'LIST',b'fixture')+chunk(b'data',data)+chunk(b'JUNK',b'final')
 wav=b'RIFF'+struct.pack('<I',len(body))+body
 result=[];index=0;phase=0
 while index<n:
  a=frames[index];b=frames[min(index+1,n-1)];fraction=(phase*89478)>>16
  result.append([a[c]+(((b[c]-a[c])*fraction)>>16) for c in range(2)])
  phase+=rate
  if phase>=48000:phase-=48000;index+=1
 payload=struct.pack('<II',len(wav),len(result))+wav
 (out/(name+'.mem')).write_text('\n'.join(f'{x:02x}' for x in payload))
 (out/(name+'_expected.mem')).write_text('\n'.join(f'{((r&0xffffff)<<24)|(l&0xffffff):012x}' for l,r in result))
 (out/(name+'.wav')).write_bytes(wav)
 print(name,len(wav),len(result))
