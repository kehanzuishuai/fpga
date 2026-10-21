"""Physical timing probe of the exact current display clock/reset sources."""
from pathlib import Path
import subprocess,json,re,hashlib,sys
R=Path(__file__).resolve().parents[2];B=Path(__file__).resolve().parent/'clock_probes';O=B/(sys.argv[1] if len(sys.argv)>1 else 'production_three');O.mkdir(exist_ok=True)
for name in ['probe.v','probe.cst']:
    (O/name).write_bytes((B/'half_fine_trim'/name).read_bytes())
if len(sys.argv)>2:
    with (O/'probe.cst').open('a') as f:f.write('\nINS_LOC "u_video_io/reset_buffer" '+sys.argv[2]+';\n')
s=(R/'src/integrated.sdc').read_text()
propagated=len(sys.argv)>3 and sys.argv[3]=='propagated'
if len(sys.argv)>3 and not propagated:
    fine=int(sys.argv[3]);step=int(sys.argv[4]);phase_fine=fine/(8*742.5)*1000
    s=s.replace('{0.218350168 0.168350168 0.218350168}',f'{{{phase_fine+step*.05:.12f} {phase_fine:.12f} {phase_fine+step*.05:.12f}}}')
    if len(sys.argv)>5:
        od=int(sys.argv[5]);cs=int(sys.argv[6]);edges=f'{{{cs+1} {cs+1+od//2} {cs+1+od}}}'
        s=s.replace('-edges {2 4 6}','-edges '+edges)
constraint_lines=[l.replace('-divide_by 1','-edges {1 2 3}') if l.startswith('create_generated_clock -name video_serial_reset_global ') else l for l in s.splitlines() if (l.startswith('create') and 'audio_clk' not in l) or (l.startswith('set_false_path') and 'u_video_' in l)]
if propagated:
    constraint_lines=[l.replace('-name video_pixel_pll ','-name video_pixel ') for l in constraint_lines if not any(l.startswith('create_generated_clock -name '+n+' ') for n in ['video_pixel','video_serial_global','video_serial_reset_regional'])]
(O/'probe.sdc').write_text('\n'.join(constraint_lines))
files=[R/'src/display/visual_dvi_io.v',R/'src/display/visual_video_clock.v',R/'src/pll_init.v',R/'src/display/gowin_pll/visual_pll_mod.v',R/'src/display/gowin_pll/visual_ref_pll_mod.v',O/'probe.v']
if len(sys.argv)>3 and not propagated:
    pll=(R/'src/display/gowin_pll/visual_pll_mod.v').read_text().replace('PLL_inst.CLKOUT2_PE_FINE = 1;',f'PLL_inst.CLKOUT2_PE_FINE = {fine};').replace('PLL_inst.CLKOUT2_DT_STEP = 1;',f'PLL_inst.CLKOUT2_DT_STEP = {step};')
    if len(sys.argv)>5:
        pll=pll.replace('PLL_inst.ODIV2_SEL = 4;',f'PLL_inst.ODIV2_SEL = {int(sys.argv[5])};').replace('PLL_inst.CLKOUT2_PE_COARSE = 1;',f'PLL_inst.CLKOUT2_PE_COARSE = {int(sys.argv[6])};')
    (O/'visual_pll_mod.v').write_text(pll)
    files=[O/'visual_pll_mod.v' if p.name=='visual_pll_mod.v' else p for p in files]
hashes={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
(O/'probe.gprj').write_text('<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE gowin-fpga-project><Project><Template>FPGA</Template><Version>5</Version><Device name="GW5AST-138C" pn="GW5AST-LV138FPG676AC1/I0">gw5ast138c-003</Device><FileList>'+''.join(f'<File path="{p.as_posix()}" type="file.verilog" enable="1"/>' for p in files)+''.join(f'<File path="{(O/("probe."+s)).as_posix()}" type="file.{s}" enable="1"/>' for s in ['sdc','cst'])+'</FileList></Project>')
(O/'build.tcl').write_text('cd {'+O.as_posix()+'}\nopen_project {'+(O/'probe.gprj').as_posix()+'}\nset_option -verilog_std sysv2017\nset_option -top_module clock_probe\nset_option -gen_text_timing_rpt 1\nrun all\n')
with (O/'build.log').open('w') as f:p=subprocess.run([r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'build.tcl')],cwd=R,stdout=f,stderr=subprocess.STDOUT)
assert p.returncode==0
assert hashes=={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
tr=(O/'impl/pnr/probe.tr').read_text()
names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
slacks={k:float(m[1]) if (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',tr,re.M|re.S)) else None for k,v in names.items()}
ends={k:int(re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',tr)[1]) for k in ['Setup','Hold']}
result={'status':'PASS' if all(v is not None and v>=0 for v in slacks.values()) and ends=={'Setup':0,'Hold':0} else 'FAIL','slacks_ns':slacks,'violated_endpoints':ends,'source_sha256':hashes,'scope':'Exact production sources in small physical-clock probe; full implementation still required'}
(O/'RESULT.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True)
