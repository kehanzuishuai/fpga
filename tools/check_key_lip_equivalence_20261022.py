"""Compare current and pre-change registered scene pixels, with key-biased inputs."""
from pathlib import Path
import subprocess,json,hashlib,time,sys,re
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/key_lip'
tag=sys.argv[1] if len(sys.argv)>1 else ''
assert not tag or re.fullmatch('[a-z0-9_]+',tag)
O=A/('verification_'+tag if tag else 'verification');O.mkdir(exist_ok=True)
gold=A/'before/src/display/visual_scene.sv'
source=R/'src/display/visual_scene.sv'
(O/'gold.sv').write_text(gold.read_text().replace('module visual_scene','module scene_before').replace('module visual_light_motion','module motion_before'))
(O/'tb.sv').write_text('''`timescale 1ns/1ps
module tb;
reg clk=0;reg[11:0] x=0,y=0;reg live=0;reg[511:0] status=0;reg signed[9:0] dx=0,dy=0;reg[95:0] trails=0;reg[23:0] sharp=0,frost=0;
wire[23:0] actual,reference;
visual_scene dut(x,y,live,status,actual,dx,dy,trails,sharp,frost,clk);
scene_before gold(x,y,live,status,reference,dx,dy,trails,sharp,frost,clk);
integer i,k,seed=9227181;
initial begin
 for(i=0;i<512;i=i+1)begin
  if(i%64==0)begin $display("scene comparison progress %0d",i);$fflush();end
  for(k=0;k<16;k=k+1)status[k*32+:32]=$random(seed);
  status[456+:2]=2'(i%4);status[490+:3]=3'(i%8);live=i%7!=0;
  dx=$random(seed);dy=$random(seed);trails={$random(seed),$random(seed),$random(seed)};
  sharp=$random(seed);frost=$random(seed);
  if(i<384)begin x=12'((i*73)%1920);y=12'(840+(i*29)%174);end
  else begin x=12'($unsigned($random(seed))%4096);y=12'($unsigned($random(seed))%4096);end
  #3;clk=1;#3;
  if(i>=40 && actual!==reference)$fatal(1,"pixel mismatch i=%0d input=%0d,%0d actual=%h ref=%h",i,x,y,actual,reference);
  clk=0;
 end
 $display("PASS 512 scene pixel comparisons, key edges and full12-bit coordinates, all modes; latency40 unchanged");$finish;
end
endmodule
''')
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs={str(p.relative_to(R)):sha(p) for p in [source,gold,O/'gold.sv',O/'tb.sv']}
for label,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/'scene.vvp',source,O/'gold.sv',O/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),O/'scene.vvp'])]:
    with (O/(label+'.log')).open('w') as f:
        p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,text=True,timeout=180)
    output=(O/(label+'.log')).read_text(errors='replace')
    assert p.returncode==0,(label,output)
    print(output[-900:],flush=True)
assert all(sha(R/n)==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',scene_pixels=512,latency=40,files=inputs,programming=False),indent=2))
