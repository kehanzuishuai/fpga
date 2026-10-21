"""Synthesize an unconstrained full-range Loader, then compare real cells.

The delivered top only reaches MIDI60..75 at velocity100. A separate small
project preserves all pitch/velocity input bits for the future 44-note range.
No pins, clocks, or options in the production project are changed.
"""
from pathlib import Path
import subprocess,sys,json,hashlib
import numpy as np
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'generic'
O.mkdir(exist_ok=True);sys.path.insert(0,str(R/'tools'))
import piano_tables as pt
from fpga_piano_model import Loader, note_phase_inc
GW=Path(r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe')
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VV=IV.with_name('vvp.exe')

def command(label,args):
    with (O/(label+'.log')).open('w') as f:
        p=subprocess.run(list(map(str,args)),cwd=R,stdout=f,stderr=subprocess.STDOUT)
    print(label,p.returncode,flush=True)
    assert p.returncode==0,(label,(O/(label+'.log')).read_text(errors='replace')[-2000:])

def prepare():
    files=['src/piano_note_loader.v','src/piano_level_rom.v','src/piano_ratio_rom.v','src/piano_note_rom.v']
    (O/'loader.gprj').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE gowin-fpga-project><Project><Template>FPGA</Template><Version>5</Version>
<Device name="GW5AST-138C" pn="GW5AST-LV138FPG676AC1/I0">gw5ast138c-003</Device><FileList>
'''+''.join(f'<File path="{(R/p).as_posix()}" type="file.verilog" enable="1"/>\n' for p in files)+'''</FileList></Project>''')
    (O/'synth.tcl').write_text('cd {'+O.as_posix()+'}\nopen_project {'+(O/'loader.gprj').as_posix()+'}\nset_option -verilog_std sysv2017\nset_option -top_module piano_note_loader\nrun syn\n')
    (O/'INPUTS.json').write_text(json.dumps({p:hashlib.sha256((R/p).read_bytes()).hexdigest() for p in files},indent=2))
    command('synthesis',[GW,O/'synth.tcl'])

def verify():
    # Use the complete standalone synthesized module tree, not a behavioral
    # replacement for ROM/DSP, and preserve the real 32-voice Loader ports.
    net=O/'impl/gwsynthesis/loader.vg';assert net.exists()
    tb='''`timescale 1ns/1ps
module tb_generic;
reg clk=0,rst_n=0,req=0;always #5 clk=~clk;
reg[6:0]note=7'bx;reg[7:0]vel=0;wire[31:0]inc;
wire busy;wire[31:0]we,done;wire[8:0]addr;wire[31:0]data;wire[21:0]release_slope;
note_freq_table f(.midi_note(note),.phase_inc(inc));GSR GSR(.GSRI(1'b1));
piano_note_loader d(.clk(clk),.rst_n(rst_n),.req_valid(req),.req_voice(5'd0),.req_note(note),.req_velocity(vel),.req_inc0(inc),.busy(busy),.voice_ready(32'hffffffff),.ld_we(we),.ld_addr(addr),.ld_data(data),.ld_done(done),.ld_rel_slope(release_slope));
integer n,k,cycles,fo,writes=0;reg[7:0]vels[0:4];
always @(posedge clk)if(rst_n && |we)begin
 if(^data===1'bx)$fatal(1,"unknown parameter");
 if(we!==32'd1)$fatal(1,"wrong target voice");
 $fdisplay(fo,"%0d,%0d,%0d,%0d",note,vel,addr,data);writes=writes+1;
end
initial begin
vels[0]=1;vels[1]=40;vels[2]=80;vels[3]=100;vels[4]=127;
fo=$fopen("'''+(O/'words.csv').relative_to(R).as_posix()+'''","w");
repeat(6)@(negedge clk);rst_n=1;
for(n=48;n<=91;n=n+1)for(k=0;k<5;k=k+1)begin
 @(negedge clk);note=n;vel=vels[k];req=1;@(negedge clk);req=0;cycles=0;
 while(!(|done))begin @(negedge clk);cycles=cycles+1;if(cycles>4000)$fatal(1,"timeout");end
 @(negedge clk);
end
$fclose(fo);if(writes!=88000)$fatal(1,"write count%0d",writes);
$display("PASS generic post-synthesis 44 notes x5 velocities,88000 words");$finish;
end
endmodule
'''
    (O/'tb.v').write_text(tb)
    command('compile',[IV,'-g2012','-s','tb_generic','-o',O/'sim.vvp',O/'tb.v',net,R/'src/note_freq_table.v',r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v'])
    command('run',[VV,O/'sim.vvp'])
    t=pt.build();l=Loader(t);expected={};bad=[];seen=set()
    for n in range(48,92):
        for v in [1,40,80,100,127]:
            p=l.params(n,v)
            for slot in range(16):
                for a,z in enumerate([p['inc'][slot],0,pt.L_INIT,0,*p['bp'][slot]]):expected[n,v,32*slot+a]=int(z)
    for line in (O/'words.csv').read_text().splitlines():
        n,v,a,z=map(int,line.split(','));key=n,v,a;assert key not in seen;seen.add(key)
        if z!=expected[key]:bad.append({'midi':n,'velocity':v,'addr':a,'expected':expected[key],'actual':z})
    assert len(seen)==len(expected)==88000
    result={'status':'PASS' if not bad else 'FAIL','notes':44,'velocities':[1,40,80,100,127],'words':len(seen),'mismatches':len(bad),'examples':bad[:30],'netlist_sha256':hashlib.sha256(net.read_bytes()).hexdigest(),'scope':'Separate unconstrained piano_note_loader synthesis; real GW5A primitive cells and initialized ROMs; all request inputs exposed. Not the optimized production top.'}
    (O/'RESULT.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True);assert not bad

if __name__=='__main__':
    if sys.argv[1]=='synth':prepare()
    else:verify()
