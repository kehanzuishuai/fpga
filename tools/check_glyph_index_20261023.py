"""Exhaustively verify supported font keys and rejection against original CAM."""
from pathlib import Path
import json,subprocess,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/glyph_index';O=A/'verification';O.mkdir(exist_ok=True)
r=json.loads((A/'CHANGE.json').read_text());rows=r['entries'];sizes=sorted({key>>16 for key,base in rows})+[0,255]
cases='\n'.join(f" 24'h{key:06x}:gold={{1'b1,17'd{base}}};" for key,base in rows)
sizecases='\n'.join(f" {i}:size=8'd{x};" for i,x in enumerate(sizes))
(O/'tb.sv').write_text('''`timescale 1ns/1ps
module tb;
reg clk=0;reg[7:0] size=0;reg[15:0] ch=0;wire[16:0] base;wire found;
visual_glyph_index dut(clk,size,ch,base,found);
function automatic[17:0] gold(input[23:0] key);begin gold=0;case(key)
__CASES__
default:begin end
endcase end endfunction
integer i,j,checked=0,valid=0;reg[17:0] expected;
initial begin
 for(i=0;i<__SIZES__;i=i+1)begin
  case(i)
__SIZE_CASES__
  endcase
  for(j=0;j<65536;j=j+1)begin
   clk=0;ch=16'(j);expected=gold({size,ch});#1;clk=1;#1;
   if(found!==expected[17] || (found && base!==expected[16:0]))$fatal(1,"glyph mismatch size%0d char%h found%b/%b base%0d/%0d",size,ch,found,expected[17],base,expected[16:0]);
   checked=checked+1;if(found)valid=valid+1;
  end
  $display("glyph font size%0d all65536 characters exact",size);$fflush();
 end
 if(valid!=233)$fatal(1,"lost glyphs %0d",valid);
 $display("PASS %0d glyph key comparisons, all233 original mappings and every16-bit character in8 supported and2 unsupported fonts",checked);$finish;
end
endmodule
'''.replace('__CASES__',cases).replace('__SIZES__',str(len(sizes))).replace('__SIZE_CASES__',sizecases))
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
files=[R/'src/display/visual_labels.sv',O/'tb.sv',R/'assets/display_glyph_index.hex',R/'assets/display_glyph_descriptors.hex']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs={str(p.relative_to(R)):sha(p) for p in files}
for label,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/'glyph.vvp',*files[:2]]),('simulation',[iv.with_name('vvp.exe'),O/'glyph.vvp'])]:
    with (O/(label+'.log')).open('w') as f:p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=240)
    out=(O/(label+'.log')).read_text(errors='replace');print(out[-1600:],flush=True);assert p.returncode==0,(label,out[-3000:])
assert all(sha(R/n)==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',keys=65536*len(sizes),valid_entries=233,registered_lookup_clocks=1,
    scope='Original CAM expected table versus actual sparse-ROM helper; unsupported hash collisions rejected by full24-bit identity. Base compared for all valid glyphs, invalid base unobservable.',inputs=inputs,programming=False),indent=2))
