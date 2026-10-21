"""PC USB-UART test; never flashes a board."""
import argparse,json
from protocol import Client,encode,decode,keymap_commands,score_commands

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--demo',action='store_true');p.add_argument('--list',action='store_true')
    p.add_argument('--port');p.add_argument('--baud',type=int,default=115200)
    p.add_argument('--mode',type=int,choices=range(3));p.add_argument('--timbre',type=int,choices=range(5))
    p.add_argument('--volume',type=int);p.add_argument('--effects',type=int,choices=range(32))
    p.add_argument('--keymap',help='JSON array of 16 MIDI notes');p.add_argument('--score',help='JSON array [[note,velocity,duration_ms],...]')
    a=p.parse_args()
    if a.demo:
        for cmd,body in [(1,b''),(0x10,b'\x02'),(0x12,b'\xff\x7f')]:
            b=encode(0,cmd,body);print(b.hex(' '),decode(b))
        return
    import serial
    if a.list:
        from serial.tools.list_ports import comports
        for x in comports():print(x.device,x.description)
        return
    if not a.port:p.error('--port required (or use --demo)')
    commands=[(1,b'')]
    if a.mode is not None:commands.append((0x10,bytes([a.mode])))
    if a.timbre is not None:commands.append((0x11,bytes([a.timbre])))
    if a.volume is not None:
        if not 0<=a.volume<=65535:p.error('volume 0..65535')
        commands.append((0x12,a.volume.to_bytes(2,'little')))
    if a.effects is not None:commands.append((0x13,bytes([a.effects])))
    if a.keymap:commands.extend(keymap_commands(json.loads(a.keymap)))
    if a.score:commands.extend(score_commands(json.loads(a.score)))
    commands.append((2,b''))
    with serial.Serial(a.port,a.baud,timeout=.05,write_timeout=1) as port:
        c=Client(port)
        for cmd,body in commands:print(hex(cmd),c.request(cmd,body).hex(' '))

if __name__=='__main__': main()
