"""Exhaustive key/name function comparison; production source stays frozen."""
from pathlib import Path
import hashlib,json,subprocess,sys
R=Path(__file__).resolve().parents[2];sys.path.insert(0,str(R/'tools'))
from display_routed_fixes_20261023 import table_key_fallback
O=R/'audit/routing_followup_20261022/key_fallback';O.mkdir(exist_ok=True)
source=R/'src/display/visual_labels.sv';s=source.read_text();candidate=table_key_fallback(s)
(O/'before_visual_labels.sv').write_text(s);(O/'candidate_visual_labels.sv').write_text(candidate)
def function(text,name):
 a=text.index(' function automatic [15:0] '+name+'(');b=text.index('endfunction',a)+len('endfunction');return text[a:b]
functions=''
# The original decimal helper uses only this power helper for trim, which is
# not called here. Include decimal and note_char with their original widths.
for name in ['decimal','note_char']:functions+=function(s,name)+'\n'
functions+=function(s,'key_char').replace('key_char','gold_key_char')+'\n'
functions+=function(candidate,'key_char').replace('key_char','candidate_key_char')+'\n'
tb='''module tb;
 reg c_mapping_valid=0;reg [6:0] char_key_note=0;
__FUNCTIONS__
 integer key,pos,note,cases=0;
 initial begin
  for(note=0;note<129;note=note+1)begin
   c_mapping_valid=note!=128;char_key_note=7'(note);
   for(key=0;key<32;key=key+1)for(pos=0;pos<64;pos=pos+1)begin
    if(gold_key_char(5'(key),6'(pos))!==candidate_key_char(5'(key),6'(pos)))
     $fatal(1,"key name differs key=%0d pos=%0d note=%0d",key,pos,note);
    cases=cases+1;
   end
  end
  $display("PASS %0d key/name cases: all32 keys,64positions,128notes and missing mapping",cases);$finish;
 end
endmodule
'''.replace('__FUNCTIONS__',functions)
(O/'tb.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('compile',[iv,'-g2012','-s','tb','-o',O/'test.vvp',O/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),O/'test.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=120)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-2000:])
 print(p.stdout[-800:],flush=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert source.read_text()==s
r=dict(status='PASS_ISOLATED_CANDIDATE_NOT_APPLIED',cases=264192,keys=32,positions=64,note_values=128,missing_mapping=True,before_sha256=sha(source),candidate_sha256=sha(O/'candidate_visual_labels.sv'),scope='Only fallback decimal arithmetic replaced by exact literals; mapped MIDI note branch and all pipeline statements byte-identical.',programming=False)
(O/'RESULT.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
