from pathlib import Path
import subprocess,json,hashlib,sys,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VV=IV.with_name('vvp.exe')
TARGET=Path(sys.argv[1]) if len(sys.argv)>1 else R/'src/display/visual_dvi_io.v'
PLL_TARGET=Path(sys.argv[2]) if len(sys.argv)>2 else R/'src/display/gowin_pll/visual_pll_mod.v'
plls=PLL_TARGET.read_text()
param=lambda n:int(re.search(r'PLL_inst\.'+n+r'\s*=\s*(\d+);',plls)[1])
dt=param('CLKOUT2_DT_STEP')*.05
phase=(param('CLKOUT2_PE_COARSE')+param('CLKOUT2_PE_FINE')/8)*1.3468+dt
rc_half=param('ODIV2_SEL')*1.3468/2
def run(tag,files,top):
 for name,args in [('compile',[IV,'-g2012','-s',top,'-o',O/(tag+'.vvp'),*files]),('run',[VV,O/(tag+'.vvp')])]:
  z=subprocess.run(list(map(str,args)),cwd=R,capture_output=True);(O/(tag+'_'+name+'.log')).write_bytes(z.stdout+z.stderr);print(tag,name,z.returncode,flush=True);assert z.returncode==0,z.stdout[-1500:]+z.stderr[-1500:]
old=(R/'audit/display_upgrade_20261018/backup/src/display/visual_dvi_io.v').read_text().replace('module visual_dvi_io','module original_dvi_io')
(O/'original_dvi_io.v').write_text(old)
tb='''`timescale 1ns/1fs
module tb_serializer_reset;
reg pc=0,sc=0,rc=0,rst=0;always#1.3468 sc=~sc;
// PLL phase0 outputs have coincident rising edges despite different periods.
initial begin #1.3468;pc=1;forever #6.734 pc=~pc;end
// PLL output2:185.625MHz, actual production coarse/fine/rising-edge trim.
initial begin #@FIRST@;rc=1;forever begin #@HIGH@;rc=0;#@LOW@;rc=1;end end
reg[9:0]b=10'h123,g=10'h2d3,r=10'h37a;wire[2:0]a,z,an,zn;wire ca,cz,can,czn;
integer test=0,k,checks=0,fo;reg check_enable=0;
GSR GSR(.GSRI(1'b1));
visual_dvi_io n(pc,sc,rst,b,g,r,a,an,ca,can,rc);
original_dvi_io o(pc,sc,rst,b,g,r,z,zn,cz,czn);
always@(posedge pc)begin b<={b[8:0],b[9]^b[6]};g<=g+10'd37;r<=r^b;end
always@(sc)begin #0.001;if(check_enable)begin
 $fdisplay(fo,"%0d,%0d,%0d",test,a,z);
 if(^a===1'bx)$fatal(1,"unknown serialized data");checks=checks+1;
end end
initial begin
fo=$fopen("tests/display_upgrade_20261018/serializer_trace.csv","w");
repeat(4)@(posedge pc);
for(test=0;test<100;test=test+1)begin
 check_enable=0;#0.413;rst=0;repeat(3+test%3)@(posedge pc);
 // Production video_rst_n is released by the pixel-domain synchronizer.
 @(posedge pc);rst<=1;
 repeat(16)@(posedge pc);check_enable=1;repeat(24+test%2)@(posedge pc);
end
$fclose(fo);$display("Captured %0d fast-clock edges100relocks vendorOSER10/DCS",checks);$finish;
end endmodule
'''
(O/'tb_serializer_reset.sv').write_text(tb.replace('@FIRST@',f'{1.3468+phase:.12f}').replace('@HIGH@',f'{rc_half-dt:.12f}').replace('@LOW@',f'{rc_half+dt:.12f}'))
run('serializer_reset',[O/'tb_serializer_reset.sv',O/'original_dvi_io.v',TARGET,Path(r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')],'tb_serializer_reset')
trials={}
for line in (O/'serializer_trace.csv').read_text().splitlines():
 t,a,b=map(int,line.split(','));trials.setdefault(t,[]).append((a,b))
lags=[]
for t,rows in trials.items():
 a=[q[0] for q in rows];b=[q[1] for q in rows];matches=[]
 for lag in range(-30,31):
  aa=a[max(0,lag):len(a)+min(0,lag)];bb=b[max(0,-lag):len(b)-max(0,lag)]
  if aa==bb:matches.append(lag)
 assert len(matches)==1,(t,matches)
 lags.append(matches[0])
print('Serializer stream offsets (bits):',sorted(set(lags)),flush=True)
assert len(set(lags))==1 and lags[0]%10==0,('Serializer word phase changed',sorted(set(lags)))
(O/'tb_clock_reset.sv').write_text('''`timescale 1ns/1ps
module tb_clock_reset;
reg clk=0,rst=0;always#10 clk=~clk;wire pc,sc,locked,rc;real last_edge=-100;integer k;
GSR GSR(.GSRI(1'b1));
visual_video_clock d(clk,rst,pc,sc,locked,rc);
always@(posedge pc)last_edge=$realtime;
always@(posedge locked)if($realtime-last_edge>0.001)$fatal(1,"lock release outside pixel edge");
initial begin
repeat(4)@(negedge clk);rst=1;
for(k=0;k<40;k=k+1)begin
 #7.111;d.ref_pll.test_lock=1;
 @(posedge d.ref_clk);#0.001;if(d.ref_ready_sync)$fatal(1,"ref synchronizer too early");
 repeat(4)@(posedge d.ref_clk);d.video_pll.test_lock=1;
 @(posedge pc);#0.001;if(locked)$fatal(1,"pixel synchronizer too early");
 repeat(4)@(posedge pc);#0.001;if(!locked)$fatal(1,"lock never released");
 #1.123;d.video_pll.test_lock=0;#0.001;if(locked)$fatal(1,"video lock loss not immediate");
 d.ref_pll.test_lock=0;#0.001;if(d.ref_ready_sync || locked)$fatal(1,"reference loss not immediate");
 repeat(4)@(posedge pc);
end
$display("PASS40ref/video relocks immediate reset assertion, synchronized release");$finish;
end endmodule
module PLL_INIT #(parameter CLK_PERIOD=20,MULTI_FAC=1)(input CLKIN,I_RST,PLLLOCK,output O_RST,O_LOCK,output[5:0]ICPSEL,output[2:0]LPFRES);
assign O_RST=I_RST;assign O_LOCK=PLLLOCK&&!I_RST;assign ICPSEL=0;assign LPFRES=0;endmodule
module visual_ref_PLL_MOD(input clkin,reset,output lock,output reg clkout0,output clkout1,input[5:0]icpsel,input[2:0]lpfres,input[1:0]lpfcap);
reg test_lock=0;initial clkout0=0;assign lock=test_lock;assign clkout1=0;always#18.518 clkout0=~clkout0;endmodule
module visual_PLL_MOD(input clkin,reset,output lock,output reg clkout0,clkout1,clkout2,input[5:0]icpsel,input[2:0]lpfres,input[1:0]lpfcap);
reg test_lock=0;initial begin clkout0=0;clkout1=0;clkout2=0;end assign lock=test_lock;always#1.347 clkout0=~clkout0;always#6.734 clkout1=~clkout1;always#6.734 clkout2=~clkout2;endmodule
''')
run('clock_reset',[O/'tb_clock_reset.sv',R/'src/display/visual_video_clock.v',Path(r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')],'tb_clock_reset')
result={'status':'PASS','vendor_serializer_trials':100,'release_phase_coverage':'Coincident PLL phase0 rising edges; varied pixel reset holds[3,4,5] and trace lengths[24,25]','checker_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'clock_ready_trials':40,'serializer_reference':'Exact pre-upgrade serializer RTL; production synchronous pixel reset release','coherent_serial_stream_offset_bits':lags[0],'word_phase_preserved':True,'PLL_readiness_test':'Clock/lock stubs, actual production release synchronizers','reset_PLL_phase_ns':phase,'reset_high_ns':rc_half-dt,'source_sha256':{p.resolve().relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in [TARGET,R/'src/display/visual_video_clock.v',PLL_TARGET]}}
(O/'BOUNDARY.json').write_text(json.dumps(result,indent=2))
