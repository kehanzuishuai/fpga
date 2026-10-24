"""Focused clock-tree edit proof and real-primitive board/edge checks."""
from pathlib import Path
import json,hashlib,re,subprocess,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];A=R/'audit/autonomous_timing_20261022_154006'
O=A/'validation';O.mkdir(exist_ok=True)
B=A/'changes/dcs_global/before'
top=R/'src/tang_mega_138k_pro_top.v.v';s=top.read_text()
pattern=r'// Distribute the P16 board clock.*?defparam u_main_clock\.DCS_MODE="CLK0";\n\n'
normalized,count=re.subn(pattern,'',s,flags=re.S);assert count==1
assert normalized.replace('clk_50m_global','clk_50m')==(B/'src/tang_mega_138k_pro_top.v.v').read_text()
for name in ['integrated.cst']:
 extract=lambda p:re.findall(r'(?m)^\s*(?:IO_LOC|IO_PORT|INS_LOC)\s+.*',p.read_text())
 old=extract(B/'src'/name);new=[v for v in extract(R/'src'/name) if 'u_main_clock' not in v];assert old==new
old=(B/'src/integrated.sdc').read_text();new=(R/'src/integrated.sdc').read_text()
new=re.sub(r'(?m)^create_generated_clock -name fabric_50m .*\n','',new)
new=new.replace('[get_pins {u_main_clock/CLKOUT}]','[get_ports {clk_50m}]').replace('clk_50m fabric_50m','clk_50m')
assert new==old,'PLL clock values or other timing exceptions changed'
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
vendor=Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')
files=[R/e.get('path') for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
sources=[p for p in files if p.suffix in ['.v','.sv']]
tb=O/'tb_global_dcs.sv';tb.write_text('''`timescale 1ns/1ps
module tb_global_dcs;
 reg raw=0;wire buffered;integer i,rises=0,falls=0;
 DCS dut(.CLKIN0(raw),.CLKIN1(1'b0),.CLKIN2(1'b0),.CLKIN3(1'b0),.CLKSEL(4'b0001),.SELFORCE(1'b1),.CLKOUT(buffered));
 defparam dut.DCS_MODE="CLK0";
 always @(posedge buffered)rises=rises+1;
 always @(negedge buffered)falls=falls+1;
 initial begin #1;rises=0;falls=0;
 for(i=0;i<2000;i=i+1)begin #10;raw=~raw;#0.001;if(buffered!==raw)$fatal(1,"clock level mismatch");end
 if(rises!=1000 || falls<1000 || falls>1001)$fatal(1,"clock edges lost rises=%0d falls=%0d",rises,falls);
 $display("PASS1000 raw/DCS clock periods after initial settling, real Gowin primitive, no lost/extra active edges");$finish;end
endmodule
''')
commands=[('board_elaboration',[iv,'-g2012','-s','tb_hardware_elaboration','-tnull',R/'tests/integration/tb_hardware_elaboration.sv',*sources,vendor]),
 ('clock_compile',[iv,'-g2012','-s','tb_global_dcs','-o',O/'global_dcs.vvp',tb,vendor]),
 ('clock_edges',[iv.with_name('vvp.exe'),O/'global_dcs.vvp'])]
for name,args in commands:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,errors='replace');(O/(name+'.log')).write_text(p.stdout+p.stderr)
 assert p.returncode==0,(name,(p.stdout+p.stderr)[-1500:]);print(name,'PASS',p.stdout[-250:],flush=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
(O/'GLOBAL_DCS.json').write_text(json.dumps({'status':'PASS','scope':'Original top function exactly preserved except static clock alias; pin assignments and PLL clock ratios unchanged; real Gowin DCS edges and complete board elaboration passed. Not routed timing.',
 'sources':{p.relative_to(R).as_posix():sha(p) for p in files}},indent=2))
