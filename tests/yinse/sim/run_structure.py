"""Portable RTL/memory structure check, NOT Gowin synthesis or timing."""
from pathlib import Path
import os,shutil,subprocess,json,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sim/out';OUT.mkdir(exist_ok=True)
sources=sorted(p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*.sv') if 'sim' not in p.relative_to(ROOT).parts)
override=os.environ.get('FPGA_YOSYS')
tool=shutil.which(override or 'yosys') or shutil.which(override or 'yowasp-yosys')
if not tool:
    options=list((Path(os.environ.get('APPDATA','__absent__'))/'Python').glob('*/Scripts/yowasp-yosys.exe'))
    tool=str(options[-1]) if options else None
if not tool:raise SystemExit('Yosys missing; use FPGA_YOSYS or install on PATH')
results=[]
for top in ['yinse_controls','yinse_aux_bank']:
    command='read_verilog -sv '+' '.join(sources)+'; hierarchy -check -top '+top+'; proc; opt; memory_dff; memory_collect; opt_clean; check -assert; stat; log YINSE_STRUCTURE_COMPLETE'
    result=subprocess.run([tool,'-Q','-T','-p',command],cwd=ROOT,capture_output=True,text=True,errors='replace',timeout=240)
    output=result.stdout+result.stderr;(OUT/('structure_'+top+'.log')).write_text(output,encoding='utf-8')
    if result.returncode or 'YINSE_STRUCTURE_COMPLETE\n' not in output or 'Found and reported 0 problems' not in output or 'Warning:' in output:
        print(output[-6000:]);raise SystemExit('Structure FAILED '+top)
    results.append(top+': PASS (generic RTL and memory, not device mapping)');print(results[-1],flush=True)
(OUT/'structure_report.json').write_text(json.dumps({'status':'PASS','results':results,'hardware_validated':False},indent=2),encoding='utf-8')
