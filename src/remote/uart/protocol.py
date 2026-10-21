"""ESP32-FPGA byte stream protocol; independent of HTTP/UART read boundaries."""
from dataclasses import dataclass
import time

def crc16(data):
    c=0xffff
    for b in data:
        c^=b<<8
        for _ in range(8): c=((c<<1)^0x1021)&0xffff if c&0x8000 else (c<<1)&0xffff
    return c

def encode(seq,cmd,payload=b''):
    payload=bytes(payload)
    if not 0<=seq<256 or not 0<=cmd<256 or len(payload)>6: raise ValueError('frame fields')
    b=bytearray([0xa5,0x5a,1,seq,cmd,len(payload)])+payload+bytes(8-len(payload))
    return bytes(b)+crc16(b[2:14]).to_bytes(2,'little')

@dataclass(frozen=True)
class Packet:
    seq:int
    cmd:int
    payload:bytes

def decode(b):
    b=bytes(b)
    if len(b)!=16 or b[:3]!=b'\xa5\x5a\x01' or b[5]>6: raise ValueError('format')
    if any(b[6+b[5]:14]): raise ValueError('reserved/padding')
    if crc16(b[2:14])!=int.from_bytes(b[14:],'little'): raise ValueError('CRC')
    return Packet(b[3],b[4],b[6:6+b[5]])

class Decoder:
    def __init__(self): self.buffer=bytearray()
    def reset(self): self.buffer.clear()
    def feed(self,data):
        out=[]
        for x in data:
            self.buffer.append(x)
            if len(self.buffer)>16: del self.buffer[0]
            if len(self.buffer)==16:
                try: p=decode(self.buffer)
                except ValueError: continue
                out.append(p);self.buffer.clear()
        return out

class Client:
    """One outstanding request; retry SAME bytes/sequence, never pipeline."""
    def __init__(self,port,timeout=1.0,retries=2):
        self.port=port;self.timeout=timeout;self.retries=retries;self.seq=0;self.decoder=Decoder()
    def request(self,cmd,payload=b''):
        seq=self.seq;self.seq=(self.seq+1)&255
        frame=encode(seq,cmd,payload)
        for _ in range(self.retries+1):
            self.port.write(frame);deadline=time.monotonic()+self.timeout
            while time.monotonic()<deadline:
                for p in self.decoder.feed(self.port.read(64)):
                    if p.cmd==0x80 and p.seq==seq and len(p.payload)==6 and p.payload[0]==cmd:
                        if p.payload[1]:raise RuntimeError(f'FPGA status {p.payload[1]}')
                        return p.payload[2:]
        raise TimeoutError('No reply; outcome unknown. Query actual status before continuing.')

def keymap_commands(notes):
    if len(notes)!=32 or any(not 36<=n<=96 for n in notes):raise ValueError('32 MIDI notes in 36..96 required')
    return [(0x20,b'')]+[(0x21,bytes([i,n])) for i,n in enumerate(notes)]+[(0x22,b'')]

def score_commands(events):
    if not 1<=len(events)<=32:raise ValueError('1..32 events')
    out=[(0x30,bytes([len(events)]))]
    for i,(note,velocity,duration) in enumerate(events):
        if not 0<=note<128 or not 0<=velocity<128 or not 1<=duration<=65535:raise ValueError('event range')
        out.append((0x31,bytes([i,note,velocity])+duration.to_bytes(2,'little')))
    return out+[(0x32,b'')]
