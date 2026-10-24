"""Test actual replacement digit functions against original expressions."""
from pathlib import Path
import re,subprocess,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/bcd_select';O=A/'verification';O.mkdir(exist_ok=True)
source=R/'src/display/visual_labels.sv';s=source.read_text();functions='\n'.join(f for f in re.findall(r' function automatic .*?endfunction',s,re.S) if f.split('(')[0].split()[-1] in ['selected_bcd_digit','bcd_digit_visible'])
assert functions.count('endfunction')==2
(O/'tb.sv').write_text('''module tb;
'''+functions+'''
integer v,p,d,n,seed=89127,checked=0;reg[19:0] bcd;reg[15:0] old_digit,new_digit,old_trim,new_trim;
task check;begin
 for(p=0;p<5;p=p+1)begin
  old_digit=16'd48+16'(bcd[p*4+:4]);new_digit={12'd3,selected_bcd_digit(bcd,3'(p))};
  old_trim=(p>0 && (bcd>>(p*4))==0)?16'd32:old_digit;
  new_trim=bcd_digit_visible(bcd,3'(p))?new_digit:16'd32;
  if(old_digit!==new_digit || old_trim!==new_trim)$fatal(1,"digit mismatch %h place%0d",bcd,p);
  checked=checked+1;
 end
end endtask
initial begin
 for(v=0;v<65536;v=v+1)begin
  n=v;for(d=0;d<5;d=d+1)begin bcd[d*4+:4]=4'(n%10);n=n/10;end check;
  bcd=$random(seed);check;
 end
 $display("PASS %0d digit and trim comparisons: all16-bit decimal values/all5places plus random20-bit patterns",checked);$finish;
end endmodule
''')
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs={str(p.relative_to(R)):sha(p) for p in [source,O/'tb.sv']}
for stage,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/'tb.vvp',O/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),O/'tb.vvp'])]:
 with (O/(stage+'.log')).open('w') as f:p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=60)
 out=(O/(stage+'.log')).read_text(errors='replace');print(out[-1000:],flush=True);assert p.returncode==0,(stage,out)
assert all(sha(R/n)==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',comparisons=655360,scope='Actual5-way digit functions versus original numeric-place expressions; all16-bit decimal values and random20-bit patterns, all5places.',inputs=inputs,programming=False),indent=2))
