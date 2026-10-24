"""Focused algebra and registered pixels for the fixed-mask critical path."""
from pathlib import Path
import re,subprocess,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/well_geometry';O=A/'verification';O.mkdir(exist_ok=True)
source=R/'src/display/visual_scene.sv';before=A/'before_visual_scene.sv';s=source.read_text()
functions='\n'.join(f for f in re.findall(r' function automatic .*?endfunction',s,re.S) if f.split('(')[0].split()[-1] in ['circle_limit','rounded','round_geometry','round_finish'])
shapes=[(42,186,688,274,18),(782,186,688,274,18),(1522,186,356,282,18),(42,550,1836,176,18),(42,830,892,208,18),(986,830,892,208,18),(24,752,1872,24,12)]+[(54+i*12,76-(25 if i==2 else 17 if i in [1,3] else 8),7,50 if i==2 else 34 if i in [1,3] else 16,3) for i in range(5)]
shape_cases='\n'.join(f'{i}:begin left={x};top={y};w={w};h={h};r={r};end' for i,(x,y,w,h,r) in enumerate(shapes))
(O/'algebra.sv').write_text('''module tb;
'''+functions+'''
integer shape,n,k,left,top,w,h,r,sx,sy,checked=0;
task check;reg original,split;begin
 original=rounded(13'(sx),13'(sy),13'(left),13'(top),13'(w),13'(h),13'(r));
 split=round_finish(round_geometry(13'(sx),13'(sy),13'(left),13'(top),13'(w),13'(h),13'(r)),6'(r));
 if(original!==split)$fatal(1,"mask shape%0d coordinate%0d,%0d",shape,sx,sy);
 checked=checked+1;
end endtask
initial begin
 for(shape=0;shape<12;shape=shape+1)begin
 case(shape)
'''+shape_cases+'''
 endcase
 for(n=0;n<4096;n=n+1)begin
  for(k=0;k<6;k=k+1)begin
   sx=n;case(k)0:sy=top-1;1:sy=top;2:sy=top+r;3:sy=top+h-r;4:sy=top+h-1;5:sy=top+h;endcase check;
   sy=n;case(k)0:sx=left-1;1:sx=left;2:sx=left+r;3:sx=left+w-r;4:sx=left+w-1;5:sx=left+w;endcase check;
  end
 end
 for(sx=left-1;sx<=left+2*r+1;sx=sx+1)
  for(sy=top-1;sy<=top+2*r+1;sy=sy+1)check;
 end
 $display("PASS %0d fixed rounded-mask comparisons: all4096 axis coordinates at boundaries and corner grids,12shapes",checked);$finish;
end endmodule
''')
gold=before.read_text().replace('module visual_scene','module scene_before').replace('module visual_light_motion','module motion_before');(O/'gold.sv').write_text(gold)
template=(R/'audit/routing_followup_20261022/key_lip/verification_balanced_arithmetic/tb.sv').read_text()
template=template.replace('integer i,k,seed=9227181;','integer i,k,seed=9227181;integer left,top,w,h,r;')
old="  if(i<384)begin x=12'((i*73)%1920);y=12'(840+(i*29)%174);end\n  else begin x=12'($unsigned($random(seed))%4096);y=12'($unsigned($random(seed))%4096);end"
new="""  case((i/32)%12)
"""+shape_cases+"""
  endcase
  if(i<384)begin
   x=12'((i%2)?left+w-1-(i%r):left+(i%r));
   y=12'((i%3)?top+h-1-((i/2)%r):top+((i/2)%r));
  end else begin x=12'($unsigned($random(seed))%4096);y=12'($unsigned($random(seed))%4096);end"""
assert template.count(old)==1;template=template.replace(old,new).replace('key edges and full12-bit coordinates','fixed well/sound corners and full12-bit coordinates');(O/'pixels.sv').write_text(template)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs={str(p.relative_to(R)):sha(p) for p in [source,before,O/'algebra.sv',O/'gold.sv',O/'pixels.sv']}
for tag,files in [('algebra',[O/'algebra.sv']),('pixels',[source,O/'gold.sv',O/'pixels.sv'])]:
 for stage,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/(tag+'.vvp'),*files]),('simulation',[iv.with_name('vvp.exe'),O/(tag+'.vvp')])]:
  with (O/(tag+'_'+stage+'.log')).open('w') as f:p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=180)
  out=(O/(tag+'_'+stage+'.log')).read_text(errors='replace');print(out[-1000:],flush=True);assert p.returncode==0,(tag,stage,out[-3000:])
assert all(sha(R/n)==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',scope='Original rounded versus split functions; all4096 axis boundaries and corners of12shapes;512registered scene pixels, unchanged40clocks',inputs=inputs,programming=False),indent=2))
