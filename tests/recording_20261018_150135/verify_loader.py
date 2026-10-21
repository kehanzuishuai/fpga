"""Compare actual integrated synthesis Loader words to the unchanged model.

Only the Loader and its ROM descendants are extracted; primitive instances
and defparams are unmodified. Stimulus bypasses the keyboard/front end and
forces the captured request pitch/increment, not the interpolation signals.
"""
from pathlib import Path
import re, json, hashlib, subprocess, sys
import numpy as np
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools'))
import piano_tables as pt
from fpga_piano_model import Loader, note_phase_inc

def run(tag, source):
    d=O/tag;d.mkdir(exist_ok=True)
    s=Path(source).read_text()
    mods={m.group(1):m.group() for m in re.finditer(r'^module\s+(\w+)\s*\([\s\S]*?^endmodule',s,re.M)}
    wanted={'piano_note_loader'}
    while True:
        found={t for name in wanted for t in re.findall(r'^\s+(\w+)\s+[\\\w]+\s*\(',mods[name],re.M) if t in mods}
        if found<=wanted:break
        wanted |= found
    body=mods['piano_note_loader']
    ports=re.findall(r'^(input|output)\s+(\[[^\]]+\]\s+)?([^;]+);',body,re.M)
    connect=[]
    for direction,width,name in ports:
        name=name.strip()
        if direction=='output':
            val={'state':'state','\\G_PARTIAL.ld_we':'we','\\G_PARTIAL.ld_done':'done','\\G_PARTIAL.ld_data':'data','\\G_PARTIAL.ld_addr':'addr','\\G_PARTIAL.ld_rel_slope':'release_slope'}.get(name,'')
        elif name=='clk_12m288':val='clk'
        elif name=='n290_6':val='!rst_n'
        elif name=='n135_6':val="(state[3:0]==0)"
        elif name=='n135_4':val='req'
        elif name=='out_note_on_Z':val="1'b1"
        elif name.startswith('out_note_Z_'):val=f'note[{name.rsplit("_",1)[1]}]'
        elif name=='out_velocity_Z':val="1'b1"
        elif name.startswith('n3804_5'):val="1'b1"
        elif name.startswith('eng'):val="2'd0"
        elif name.startswith('vstate'):val="2'd2"
        else:val="1'b0"
        connect.append('.'+name+' ('+val+')')
    (d/'loader_netlist.v').write_text('\n'.join(mods[n] for n in sorted(wanted)))
    tb='''`timescale 1ns/1ps
module tb_post_loader;
reg clk=0,rst_n=0,req=0;always #5 clk=~clk;
reg[6:0]note=7'bx;wire[31:0]inc;wire[4:0]state;
wire[31:0]we,done;wire[27:0]data;wire[8:0]addr;wire[12:0]release_slope;
note_freq_table f(.midi_note(note),.phase_inc(inc));
GSR GSR(.GSRI(1'b1));
piano_note_loader d('''+',\n'.join(connect)+''');
integer n,cycles,fo,writes=0;
always @(posedge clk) if(rst_n && |we) begin
if(^data===1'bx)$fatal(1,"unknown loader data note%0d addr%0d data%h",note,addr,data);
$fdisplay(fo,"%0d,%0d,%0d",note,addr,data);writes=writes+1;
end
initial begin
fo=$fopen("'''+(d/'words.csv').relative_to(R).as_posix()+'''","w");
force d.note_r=note;force d.inc0_r=inc;
for(n=60;n<=75;n=n+1)begin
 rst_n=0;req=0;note=n;repeat(6)@(negedge clk);rst_n=1;repeat(4)@(negedge clk);
 req=1;@(negedge clk);req=0;cycles=0;
 while(!(|done))begin @(negedge clk);cycles=cycles+1;if(cycles>4000)$fatal(1,"Loader timeout state%0d",state);end
 @(negedge clk);
end
$fclose(fo);if(writes!=6400)$fatal(1,"Expected6400 writes got%0d",writes);
$display("PASS post-synthesis integrated Loader stimulus 16 notes,6400 words");$finish;
end
endmodule
'''
    (d/'tb.v').write_text(tb)
    iv=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');vv=iv.with_name('vvp.exe')
    for label,args in [('compile',[iv,'-g2012','-s','tb_post_loader','-o',d/'sim.vvp',d/'tb.v',d/'loader_netlist.v',R/'src/note_freq_table.v',r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v']),('run',[vv,d/'sim.vvp'])]:
        z=subprocess.run(list(map(str,args)),cwd=R,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        (d/(label+'.log')).write_bytes(z.stdout)
        print(tag,label,z.returncode,z.stdout.decode(errors='replace')[-1500:],flush=True)
        assert z.returncode==0,(tag,label,z.returncode)
    table=pt.build();loader=Loader(table);errors=[];count=0
    expected={}
    for n in range(60,76):
        p=loader.params(n,100)
        for slot in range(16):
            v=[p['inc'][slot],0,pt.L_INIT,0,*p['bp'][slot]]
            for offset,val in enumerate(v):expected[n,32*slot+offset]=int(val)
    seen=set()
    for line in (d/'words.csv').read_text().splitlines():
        n,a,value=map(int,line.split(','));key=(n,a);assert key not in seen;seen.add(key);count+=1
        if value!=expected[key]:errors.append({'midi':n,'addr':a,'actual':value,'expected':expected[key]})
    assert len(seen)==6400
    result={'status':'PASS' if not errors else 'FAIL','netlist_sha256':hashlib.sha256(Path(source).read_bytes()).hexdigest(),'source':str(source),'notes':16,'words':count,'mismatches':len(errors),'examples':errors[:40],'scope':'Actual production integrated Loader and synthesized ROMs, Gowin GW5A primitive simulation. Captured request pitch/inc forced; keyboard/allocator not covered.'}
    (d/'RESULT.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True)
    return result

if __name__=='__main__':
    tag=sys.argv[1]
    source=R/('audit/recording_20261018_150135/backup/impl/gwsynthesis/yinyue_fashengqi.vg' if tag=='before' else 'impl/gwsynthesis/yinyue_fashengqi.vg')
    result=run(tag,source)
    if tag!='before':assert result['status']=='PASS'
