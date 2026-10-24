"""Compare current and candidate labels with per-cycle changing 32-key maps."""
from pathlib import Path
import hashlib,json,re,subprocess,sys
R=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(R/'tools'))
from display_selected_note_20261023 import compact_selected_note
current='--current' in sys.argv
O=R/('audit/routing_followup_20261022/selected_note_v6' if current else 'audit/routing_followup_20261022/selected_note');O.mkdir(exist_ok=True)
source=R/'src/display/visual_labels.sv';frozen=source.read_text()
before=(R/'audit/routing_followup_20261022/v6_before/src/display/visual_labels.sv').read_text() if current else frozen
assert 'key_note_pipe[0]<=pick_key_note' not in before,'Test expects original reference pipeline'
candidate=frozen if current else compact_selected_note(before)
(O/'before_visual_labels.sv').write_text(before)
(O/'candidate_visual_labels.sv').write_text(candidate)
# Rename all modules in the reference, including appended glyph/BCD helpers.
modules=re.findall(r'\bmodule\s+(\w+)',before)
reference=before
for name in modules:reference=re.sub(r'\b'+re.escape(name)+r'\b',name+'_reference',reference)
(O/'reference.sv').write_text(reference)
rects=re.findall(r"wire hit_(\d+)=.*?x>=(\d+) && x<(\d+) && y>=(\d+) && y<(\d+)",before)
assert len(rects)==90
cases='\n'.join(f"{n}:begin x=12'({x0}+($unsigned($random(seed))%{int(x1)-int(x0)}));y=12'({y0}+($unsigned($random(seed))%{int(y1)-int(y0)}));end" for n,x0,x1,y0,y1 in rects)
tb='''`timescale 1ns/1ps
module tb;
 reg clk=0;reg [11:0] x=0,y=0;reg live=0,pv=0,xd=0,xs=0,xm=0;
 reg [15:0] hz=0;reg signed [5:0] shift=0;reg [1:0] range_sel=0;
 reg [511:0] status=0;wire ink,ri;wire [23:0] color,rc;wire [1:0] coverage,rv;
 visual_labels dut(x,y,pv,hz,xd,xs,xm,shift,ink,live,status,color,coverage,range_sel,clk);
 visual_labels_reference gold(x,y,pv,hz,xd,xs,xm,shift,ri,live,status,rc,rv,range_sel,clk);
 integer n,k;integer seed=73197;reg [31:0] key_coverage=0;
 initial begin
  for(n=0;n<11560;n=n+1)begin
   for(k=0;k<16;k=k+1)status[k*32+:32]=$random(seed);
   status[6:0]=7'h7f;status[0]=(n%5)!=0;status[1]=(n%3)!=0;
   status[8+:3]=3'(n%6);status[11+:7]=7'(36+n%61);
   for(k=0;k<32;k=k+1)status[82+k*7+:7]=7'((n+k*17)%128);
   status[455]=1;status[456+:2]=2'(n%3);status[490+:3]=3'(n%8);
   // Include all-pressed states while metadata and current label change.
   if(n%4==0)status[18+:32]=32'hffffffff;
   live=(n%7)!=0;pv=(n%4)!=0;hz=$random(seed);xd=n%2;xs=n%3!=0;xm=n%5==0;range_sel=2'(n%4);
   case((n/128)%90)
__CASES__
   endcase
   #1;clk=1;#1;
   if(n>24)begin
    if({ink,color,coverage}!=={ri,rc,rv})$fatal(1,"label pixel mismatch cycle=%0d",n);
    if(dut.ch!==gold.ch)$fatal(1,"character mismatch cycle=%0d",n);
    if(dut.char_key_note!==gold.char_key_note)$fatal(1,"selected note mismatch cycle=%0d actual=%0d expected=%0d",n,dut.char_key_note,gold.char_key_note);
    if(dut.char_status[511:306]!==gold.char_status[511:306] || dut.char_status[81:0]!==gold.char_status[81:0])$fatal(1,"other status mismatch cycle=%0d",n);
    if(dut.char_status[305:82]!==224'd0)$fatal(1,"unused mapping remained");
    key_coverage[gold.attr_pipe[14][32:28]]=1'b1;
   end
   clk=0;
  end
  if(key_coverage!==32'hffffffff)$fatal(1,"not all32key indices exercised %h",key_coverage);
  $display("PASS 11560 changing metadata cycles, all32 selected notes,90regions, identical pixels/characters/latency");$finish;
 end
endmodule
'''.replace('__CASES__',cases)
(O/'tb.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('compile',[iv,'-g2012','-s','tb','-o',O/'equivalence.vvp',O/'candidate_visual_labels.sv',O/'reference.sv',O/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),O/'equivalence.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-3000:])
 print(p.stdout[-1000:],flush=True)
sha=lambda data:hashlib.sha256(data).hexdigest()
assert source.read_text()==frozen,'Running source must remain frozen'
result=dict(status='PASS_CURRENT_LABELS_AGAINST_V5_PIPELINE' if current else 'PASS_ISOLATED_CANDIDATE_NOT_APPLIED',cycles=11560,regions=90,key_indices=32,original_latency_cycles=21,
 root_sha256=sha(source.read_bytes()),before_sha256=sha((O/'before_visual_labels.sv').read_bytes()),candidate_sha256=sha((O/'candidate_visual_labels.sv').read_bytes()),
 scope='Identical pixel/character/note capture cycles. Only label-local note mapping is compacted; physical piano RTL is not an input or output of this transformation.',programming=False)
(O/'RESULT.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
