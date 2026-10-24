"""Prepare and check a separate PLL-input-bypass candidate. Root RTL is untouched."""
from pathlib import Path
import hashlib, json, re, subprocess, xml.etree.ElementTree as ET

R = Path(__file__).resolve().parents[1]
A = R / 'audit/autonomous_timing_20261022_154006/changes/pll_bypass'
A.mkdir(parents=True,exist_ok=True)
names=['src/tang_mega_138k_pro_top.v.v','src/gowin_pll/audio_pll.v',
       'src/gowin_pll/audio_pll_mod.v','src/integrated.cst','src/integrated.sdc']
old={n:(R/n).read_text() for n in names}
new=dict(old)
n=names[0]
pattern=r'// Distribute the P16 board clock.*?defparam u_main_clock\.DCS_MODE="CLK0";\n\n'
new[n],count=re.subn(pattern,'// Board-clock distribution uses the existing audio PLL input-bypass output.\nwire clk_50m_global;\n\n',new[n],flags=re.S)
assert count==1
new[n]=new[n].replace('.clkin\n        (clk_50m_global)','.clkin\n        (clk_50m)',1)
new[n]=new[n].replace('.init_clk\n        (clk_50m_global)','.init_clk\n        (clk_50m)',1)
new[n]=new[n].replace('(clk_12m288),','(clk_12m288),\n\n    .clkout50(clk_50m_global),',1)
n=names[1]
new[n]=new[n].replace('    clkout0,','    clkout0,\n    clkout50,',1).replace('output clkout0;','output clkout0;\noutput clkout50;',1)
new[n]=new[n].replace('        .clkout0(clkout0),','        .clkout0(clkout0),\n        .clkout1(clkout50),',1)
n=names[2]
new[n]=new[n].replace('(lock, clkout0, clkin,','(lock, clkout0, clkout1, clkin,',1)
new[n]=new[n].replace('output clkout0;','output clkout0;\noutput clkout1;',1).replace('wire clkout1;\n','',1)
new[n]=new[n].replace("PLL_inst.CLK1_OUT_SEL = 1'b0", "PLL_inst.CLK1_OUT_SEL = 1'b1",1)
# No divider/VCO/output0/phase/enable setting changes. Channel1 stays disabled.
params=lambda s:dict(re.findall(r'defparam\s+PLL_inst\.(\w+)\s*=\s*([^;]+);',s))
op,np=params(old[n]),params(new[n]);assert {k for k in op if op[k]!=np[k]}=={'CLK1_OUT_SEL'}
assert np['CLKOUT1_EN']=='"FALSE"'
n=names[3]
new[n]=new[n].replace('// Board clock ingress uses the chip-wide DCS location verified in the P16 probe.\nINS_LOC "u_main_clock" PG[0];\n','// Board clock distribution uses the existing audio PLL input bypass.\n')
assert 'u_main_clock' not in new[n]
n=names[4]
new[n]=new[n].replace('u_main_clock/CLKOUT','u_audio_pll/u_pll/PLL_inst/CLKOUT1')
new[n]=new[n].replace('create_generated_clock -name audio_clk -source [get_pins {u_audio_pll/u_pll/PLL_inst/CLKOUT1}]','create_generated_clock -name audio_clk -source [get_ports {clk_50m}]')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for n in names:
 for label,values in [('before',old),('candidate',new)]:
  p=A/label/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(values[n])
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
vendor=Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')
sources=[]
for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File'):
 n=e.get('path')
 if e.get('enable')=='1' and Path(n).suffix in ['.v','.sv']:
  sources.append(A/'candidate'/n if n in names else R/n)
tb=A/'tb_pll_bypass.sv'
tb.write_text('''`timescale 1ns/1ps
module tb_pll_bypass;
 reg raw=0;wire out50,lock,audio;integer i,edges=0;
 audio_PLL_MOD dut(.clkin(raw),.reset(1'b1),.clkout0(audio),.clkout1(out50),.lock(lock),.icpsel(6'b0),.lpfres(3'b0),.lpfcap(2'b0));
 always @(posedge out50)edges=edges+1;
 initial begin #1;edges=0;for(i=0;i<2000;i=i+1)begin #10;raw=~raw;#0.001;if(out50!==raw)$fatal(1,"bypass mismatch");end
 if(edges!=1000)$fatal(1,"bypass edge count %0d",edges);$display("PASS real vendor PLL:1000 input-bypass periods, no lock dependency; output0 parameters unchanged");$finish;end
endmodule
''')
jobs=[('board_elaboration',[iv,'-g2012','-s','tb_hardware_elaboration','-tnull',R/'tests/integration/tb_hardware_elaboration.sv',*sources,vendor]),
      ('bypass_compile',[iv,'-g2012','-s','tb_pll_bypass','-o',A/'bypass.vvp',tb,A/'candidate/src/gowin_pll/audio_pll_mod.v',vendor]),
      ('bypass_edges',[iv.with_name('vvp.exe'),A/'bypass.vvp'])]
for name,args in jobs:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,errors='replace')
 (A/(name+'.log')).write_text(p.stdout+p.stderr)
 assert p.returncode==0,(name,(p.stdout+p.stderr)[-1800:])
 print(name,'PASS',p.stdout[-250:],flush=True)
(A/'RESULT.json').write_text(json.dumps(dict(status='PASS_PREPARED_NOT_APPLIED',
 root_rtl_unchanged=all((R/n).read_text()==old[n] for n in names),
 scope='Separate candidate only. Existing PLL input bypass selected with divider channel disabled; no frequency/phase/output0 parameter change. Complete board elaboration and real vendor bypass edges passed. Not full PnR/STA.',
 sources={n:{label:sha(A/label/n) for label in ['before','candidate']} for n in names}),indent=2))
