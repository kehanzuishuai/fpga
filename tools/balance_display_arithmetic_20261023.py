"""Shorten measured display paths without extra cycles or visual approximations."""
from pathlib import Path
import shutil,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/display_arithmetic';A.mkdir(exist_ok=True)
paths=['src/display/visual_renderer.sv','src/display/visual_scene.sv','tools/pipeline_display_scene_20261021.py']
for n in paths:
    b=A/'before'/n;b.parent.mkdir(parents=True,exist_ok=True);assert not b.exists();shutil.copy2(R/n,b)
p=R/paths[0];s=p.read_text()
marker=' reg signed [26:0] wave_product_a,wave_product_b,wave_sum;';assert s.count(marker)==1
s=s.replace(marker,marker+'''
 wire [26:0] wave_absolute_bits;wire [15:0] wave_restored_bits;
 visual_conditional_negate #(.WIDTH(27),.GROUP_BITS(6)) magnitude_prefix(wave_sum,wave_sum[26],wave_absolute_bits);
 visual_conditional_negate #(.WIDTH(16),.GROUP_BITS(4)) restore_prefix(wave_reciprocal[41:26],wave_reciprocal_negative,wave_restored_bits);
''',1)
a="wave_magnitude<=21'((wave_sum<0?-wave_sum:wave_sum)>>4);wave_negative<=wave_sum<0;";assert s.count(a)==1
s=s.replace(a,'wave_magnitude<=wave_absolute_bits[24:4];wave_negative<=wave_sum[26];',1)
a="wave_sample<=wave_reciprocal_negative?-16'(wave_reciprocal>>26):16'(wave_reciprocal>>26);";assert s.count(a)==1
s=s.replace(a,'wave_sample<=wave_restored_bits;',1)
s+='''
`default_nettype none
// -value bit i equals value[i] XOR any(value[i-1:0]). Keep small group
// boundaries so prefix reductions do not become a long LUT ripple chain.
module visual_conditional_negate #(parameter WIDTH=27,GROUP_BITS=6)(
 input wire [WIDTH-1:0] value,input wire negative,output wire [WIDTH-1:0] result
);
 localparam GROUPS=(WIDTH-1)/GROUP_BITS;
 (* syn_keep=1 *) wire [GROUPS-1:0] group_any;
 genvar g,i;
 generate for(g=0;g<GROUPS;g=g+1)begin:G
  assign group_any[g]=|value[g*GROUP_BITS+:GROUP_BITS];
 end
 for(i=0;i<WIDTH;i=i+1)begin:B
  if(i==0)assign result[i]=value[i];
  else begin:N
   localparam PREVIOUS=i/GROUP_BITS,PARTIAL=i%GROUP_BITS;
   wire lower_any;
   if(PREVIOUS==0)assign lower_any=|value[i-1:0];
   else if(PARTIAL==0)assign lower_any=|group_any[PREVIOUS-1:0];
   else assign lower_any=(|group_any[PREVIOUS-1:0]) || (|value[i-1:PREVIOUS*GROUP_BITS]);
   assign result[i]=value[i] ^ (negative && lower_any);
  end
 end endgenerate
 initial if(WIDTH<=GROUP_BITS || GROUP_BITS<1)$fatal(1,"Invalid conditional-negation prefix geometry");
endmodule
`default_nettype wire
'''
p.write_text(s)
functions=''
for divisor,bits,rembits in [(13,6,4),(5,5,3)]:
    functions+=f' function automatic [{7+rembits}:0] div{divisor}_seed(input [{bits-1}:0] hi);begin case(hi)\n'
    for n in range(1<<bits):functions+=f"  {bits}'d{n}:div{divisor}_seed={8+rembits}'d{((n*32//divisor)<<rembits)|(n*32%divisor)};\n"
    functions+=f'  default:div{divisor}_seed=0;endcase end endfunction\n'
    corrbits=2 if divisor==13 else 3;maximum=31+divisor-1
    functions+=f''' function automatic [7:0] div{divisor}_finish(input [{7+rembits}:0] seed,input [4:0] lo);
  reg [5:0] residual;reg [{corrbits-1}:0] correction;begin
   residual=6'(seed[{rembits-1}:0])+6'(lo);
   case(residual)
'''
    for n in range(maximum+1):functions+=f"    6'd{n}:correction={corrbits}'d{n//divisor};\n"
    functions+=f"    default:correction=0;endcase\n   div{divisor}_finish=seed[{7+rembits}:{rembits}]+8'(correction);\n  end\n endfunction\n"
stage5=''' d.sx_div13_seed=div13_seed(d.pane_x[10:5]);d.ox_div13_seed=div13_seed(d.pane_right[10:5]);
 d.sy_div5_seed=div5_seed(d.pane_y[9:5]);d.oy_div5_seed=div5_seed(d.pane_bottom[9:5]);
'''
p=R/paths[1];s=p.read_text();assert 'div13_seed' not in s
s=s.replace(' localparam PIPE_STAGES=',functions+' localparam PIPE_STAGES=',1)
marker='  logic [7:0] key_top_edge,key_bottom_edge;';assert s.count(marker)==1
s=s.replace(marker,marker+'\n  logic [11:0] sx_div13_seed,ox_div13_seed;\n  logic [10:0] sy_div5_seed,oy_div5_seed;',1)
marker=' d.channel_sum=d.rr+d.gg+d.bb;';assert s.count(marker)==1;s=s.replace(marker,marker+'\n'+stage5,1)
for variable,coordinate,divisor,bits in [('sx_part','pane_x',13,11),('ox_part','pane_right',13,11),('sy_part','pane_y',5,10),('oy_part','pane_bottom',5,10)]:
    a=f"d.{variable}=d.{coordinate}[{bits-1}:0]/{bits}'d{divisor}"
    assert s.count(a)==1,a
    seed={'sx_part':'sx_div13_seed','ox_part':'ox_div13_seed','sy_part':'sy_div5_seed','oy_part':'oy_div5_seed'}[variable]
    s=s.replace(a,f'd.{variable}=13\'(div{divisor}_finish(d.{seed},d.{coordinate}[4:0]))',1)
p.write_text(s)
# Preserve the same transformation when the scene is regenerated.
p=R/paths[2];s=p.read_text();assert 'div13_seed' not in s
marker='chunks=[]';assert s.count(marker)==1;s=s.replace(marker,'functions+='+repr(functions)+'\n'+marker,1)
marker=' channel_sum=rr+gg+bb;';assert s.count(marker)==1;s=s.replace(marker,marker+'\n'+stage5.replace('d.',''),1)
marker="group(8,'key_top_edge,key_bottom_edge',False)";assert s.count(marker)==1
s=s.replace(marker,marker+"\ngroup(12,'sx_div13_seed,ox_div13_seed',False)\ngroup(11,'sy_div5_seed,oy_div5_seed',False)",1)
for variable,coordinate,divisor,bits,seed in [('sx_part','pane_x',13,11,'sx_div13_seed'),('ox_part','pane_right',13,11,'ox_div13_seed'),('sy_part','pane_y',5,10,'sy_div5_seed'),('oy_part','pane_bottom',5,10,'oy_div5_seed')]:
    a=f"{variable}={coordinate}[{bits-1}:0]/{bits}\\'d{divisor}"
    # The generator uses escaped single quotes inside its triple-quoted source.
    if a not in s:a=f"{variable}={coordinate}[{bits-1}:0]/{bits}'d{divisor}"
    assert s.count(a)==1,a
    s=s.replace(a,f"{variable}=13'(div{divisor}_finish({seed},{coordinate}[4:0]))",1)
p.write_text(s)
for divisor,count in [(13,2048),(5,1024)]:
    for x in range(count):
        hi,lo=divmod(x,32);base,rem=divmod(hi*32,divisor)
        assert base+(rem+lo)//divisor==x//divisor
rec=dict(status='APPLIED_PENDING_RTL_EQUIVALENCE',scope='Measured display-only absolute value/sign restoration and pane division paths; same numeric results and same pipeline stages. Source315-BSRAM PnR remains isolated and running.',
    files={n:hashlib.sha256((R/n).read_bytes()).hexdigest() for n in paths},programming=False)
(A/'CHANGE.json').write_text(json.dumps(rec,indent=2));print(json.dumps(rec,indent=2))
