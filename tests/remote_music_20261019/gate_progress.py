"""Short diagnostic of mapped simulator progress; never an acceptance result."""
from run import ROOT, OUT, IVER, VVP
import subprocess, time
tb=(OUT/'tb_gate_aux.sv').read_text().replace(
 'integer i,n,base,frames,checked=0,nonzero;',
 '''integer i,n,base,frames,checked=0,nonzero;
always @(negedge clk) if(cycles<8 || cycles%1024==0)begin
 $display("progress mapped diagnostic cycle%0d time%0t",cycles,$time);$fflush();
 if(cycles>=4096)$finish;
end''')
p=OUT/'tb_gate_progress.sv';p.write_text(tb)
with (OUT/'gate_progress_compile.log').open('w') as f:
 subprocess.run(list(map(str,[IVER,'-g2012','-s','tb_gate_aux','-o',OUT/'gate_progress.vvp',p,OUT/'gate_aux.v',OUT/'yinse_aux_bank_netview.sv',*[q for q in (ROOT/'src/instruments').rglob('*.sv') if q.name!='yinse_aux_bank.sv'],'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v'])),cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=90)
started=time.time()
try:
 with (OUT/'gate_progress.log').open('w') as f:
  subprocess.run([str(VVP),str(OUT/'gate_progress.vvp')],cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=45)
except subprocess.TimeoutExpired:
 print('Diagnostic timed out; inspect last printed simulation cycle.')
print('Diagnostic wall seconds:',time.time()-started)
print((OUT/'gate_progress.log').read_text())
