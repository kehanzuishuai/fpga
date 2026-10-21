"""Compare the actual integrated synthesized Hilbert FIR with frozen RTL.

Only the FIR module and its synthesized children are extracted. Primitive
instances/parameters are unchanged. Lifted input bits are wired exactly as
the parent PCM path, checked against the synthesized RAM write data.
"""
from pathlib import Path
import json,re,subprocess,hashlib,wave,math
import numpy as np
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
vg=R/'impl/gwsynthesis/yinyue_fashengqi.vg';s=vg.read_text();digest=hashlib.sha256(vg.read_bytes()).hexdigest()
mods={m[1]:m[0] for m in re.finditer(r'^module\s+(\w+)\s*\([\s\S]*?^endmodule[^\n]*',s,re.M)}
body=mods['visual_xy_source']
expected_di='visual_pcm[23:20],'+','.join(f'u_synth_top_{k}_1' for k in range(4,16))
assert expected_di in body,'Inspect lifted PCM mapping after synthesis changed'
assert re.search(r'DFFCE out_sample_19_s0\s*\(\s*\.Q\(u_synth_top_4_1\)',s)
wanted={'visual_xy_source'}
while True:
 found={t for n in wanted for t in re.findall(r'^\s+(\w+)\s+[\\\w]+\s*\(',mods[n],re.M) if t in mods}
 if found<=wanted:break
 wanted|=found
net='\n'.join(mods[n] for n in sorted(wanted)).replace('module visual_xy_source','module post_xy_source')
(O/'post_xy_source.v').write_text(net)
connections=[]
for direction,width,name in re.findall(r'^(input|output)\s+(\[[^\]]+\]\s+)?([^;]+);',body,re.M):
 name=name.strip()
 if name=='clk_12m288':val='clk'
 elif name=='n114_32':val='!rst_n'
 elif name in ['visual_pcm_valid','left_reg_15_11']:val='pv'
 elif name=='audio_pa_en_d':val="1'b1"
 elif name=='visual_pcm':val='pcm[23:20]'
 elif (m:=re.fullmatch(r'u_synth_top_(\d+)_1',name)):val=f'pcm[{23-int(m[1])}]'
 elif direction=='output':val={'paired_valid':'nv','paired_pcm':'nw','paired_x':'nx','paired_y':'ny'}[name]
 else:raise AssertionError(('Unknown lifted port',direction,width,name))
 connections.append('.'+name+'('+val+')')
samples=[]
for f in [130.81278265,261.6255653,440,1567.9817439]:
 samples.extend(round(12000*math.sin(2*math.pi*f*n/48000)) for n in range(2048))
wavpath=R/'tests/range44_20261018/wav/fx_on/midi_060_C4.wav'
with wave.open(str(wavpath),'rb') as w:
 assert w.getframerate()==48000 and w.getsampwidth()==3
 raw=np.frombuffer(w.readframes(2048),dtype=np.uint8).reshape(-1,w.getnchannels(),3)[:,0,:].astype(np.int64)
 p24=raw[:,0]|(raw[:,1]<<8)|(raw[:,2]<<16)
 piano=((p24^0x800000)-0x800000)>>8
assert len(piano)==2048 and max(abs(piano.astype(np.int64)))>0
samples.extend(map(int,piano));assert len(samples)==10240
(O/'post_stimulus.hex').write_text(''.join(f'{(p&65535)<<8:06x}\n' for p in samples))
tb='''`timescale 1ns/1ps
module tb_post_hilbert;
reg clk=0,rst_n=0,pv=0;always#5 clk=~clk;
reg signed[23:0]pcm=0;reg[23:0]stim[0:10239];
wire rv,nv,dm;wire signed[15:0]rw,rx,ry,nx,ny;wire[15:8]nw;wire[31:0]drops;
integer i,seen=0,fo;
GSR GSR(.GSRI(1'b1));
visual_xy_source rtl(clk,rst_n,pv,pcm,1'b0,24'sd0,24'sd0,rv,rw,rx,ry,dm,drops);
post_xy_source net('''+',\n'.join(connections)+''');
always@(posedge clk)begin #1;if(rst_n)begin
 if(rv!==nv)$fatal(1,"valid mismatch sample%0d",i);
 if(rv)begin
  if(^{nw,nx,ny}===1'bx)$fatal(1,"unknown gate output%0d",i);
  if({rw[15:8],rx,ry}!=={nw,nx,ny})$fatal(1,"gate mismatch sample%0d X%0d/%0d Y%0d/%0d",i,rx,nx,ry,ny);
  $fdisplay(fo,"%0d %0d %0d",i,nx,ny);seen=seen+1;
 end
end end
initial begin
$readmemh("tests/lissajous_video_20261018/post_stimulus.hex",stim);
fo=$fopen("tests/lissajous_video_20261018/post_output.txt","w");
repeat(4)@(negedge clk);rst_n=1;
for(i=0;i<10240;i=i+1)begin
 @(negedge clk);pcm=stim[i];pv=1;@(negedge clk);pv=0;repeat(254)@(negedge clk);
end
repeat(140)@(negedge clk);
if(seen!=9217 || drops!=0)$fatal(1,"count/drops%0d/%0d",seen,drops);
$fclose(fo);$display("PASS actual integrated synthesized Hilbert9217pairs4sines+actualpianoPCM");$finish;
end
initial begin #30000000;$fatal(1,"timeout");end
endmodule
'''
(O/'tb_post_hilbert.sv').write_text(tb)
iv=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');vv=iv.with_name('vvp.exe')
for label,args in [('compile',[iv,'-g2012','-s','tb_post_hilbert','-o',O/'post.vvp',O/'tb_post_hilbert.sv',O/'post_xy_source.v',R/'src/display/visual_xy_source.sv',r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v']),('run',[vv,O/'post.vvp'])]:
 z=subprocess.run(list(map(str,args)),cwd=R,capture_output=True);(O/('post_'+label+'.log')).write_bytes(z.stdout+z.stderr);print(label,z.returncode,flush=True);assert z.returncode==0,z.stdout[-2000:]+z.stderr[-2000:]
assert digest==hashlib.sha256(vg.read_bytes()).hexdigest()
result={'status':'PASS','netlist_sha256':digest,'source_sha256':hashlib.sha256((R/'src/display/visual_xy_source.sv').read_bytes()).hexdigest(),'actual_output_pairs':9217,'input_samples':10240,'input_pure_tones_Hz':[130.81278265,261.6255653,440,1567.9817439],'actual_piano_samples':2048,'piano_file':str(wavpath),'piano_file_sha256':hashlib.sha256(wavpath.read_bytes()).hexdigest(),'mismatches':0,'scope':'Exact synthesized FIR primitives and children from production integrated netlist vs frozen RTL; external PCM/control ports driven, internal FIR signals not forced'}
(O/'POST_SYNTHESIS.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True)
