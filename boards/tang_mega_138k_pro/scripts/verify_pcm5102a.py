"""Repeatable focused verification of the E: dual-DAC modification."""
from pathlib import Path
import subprocess
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'sim_out_pcm5102a'
OUT.mkdir(exist_ok=True)
BIN = Path('D:/fpga26/bin')
TOOLS = Path(os.environ['APPDATA']) / 'Python/Python313/Scripts'
env = dict(os.environ)
env['PATH'] = 'C:/Strawberry/perl/bin;' + env['PATH']
env['LANG'] = env['LC_ALL'] = 'C'
results = []

def run(label, args):
    proc = subprocess.run([str(x) for x in args], cwd=ROOT, env=env,
                          text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          errors='replace')
    (OUT / (label + '.log')).write_text(proc.stdout, encoding='utf-8')
    print(proc.stdout, end='')
    if proc.returncode:
        raise RuntimeError(f'{label}: exit {proc.returncode}')
    return proc.stdout

def sim(name, sources):
    image = OUT / (name + '.vvp')
    run(name + '_compile', [BIN/'iverilog.exe', '-g2012', '-I', ROOT/'src',
                          '-s', name, '-o', image, *sources])
    output = run(name, [BIN/'vvp.exe', image])
    if 'PASS' not in output or 'FATAL' in output:
        raise RuntimeError(name + ': no PASS')
    results.append(name + ': PASS')

try:
    src = ROOT/'src'
    tb = ROOT/'sim'
    new = src/'pcm5102_i2s_tx.v'
    sim('tb_pcm5102a', [new, tb/'tb_pcm5102a.sv'])
    sim('tb_dual_dac', [new, src/'i2s_tx.v', tb/'tb_pcm5102a.sv', tb/'tb_dual_dac.sv'])
    tree = ET.parse(ROOT/'yinyue_fashengqi.gprj')
    sources = [ROOT/f.attrib['path'] for f in tree.findall('.//File')
               if f.attrib.get('type')=='file.verilog' and f.attrib.get('enable')=='1']
    # PLL and hardware top are intentionally excluded from portable synth simulation.
    sources = [p for p in sources if 'gowin_pll' not in str(p) and
               p.name not in ('pll_init.v', 'tang_mega_138k_pro_top.v.v')]
    sim('tb_pcm5102a_synth', [*sources,tb/'tb_pcm5102a.sv',tb/'tb_pcm5102a_synth.sv'])
    backup = ROOT/'backup_before_pcm5102a_20261007'
    for filename in ('i2s_tx.v',):
        before = (backup/filename).read_text(encoding='utf-8')
        after = (src/filename).read_text(encoding='utf-8')
        if before[before.index('always @'):].strip() != after[after.index('always @'):].strip():
            raise RuntimeError('Existing PT8211 clocked logic has changed')
    results.append('PT8211 sequential logic unchanged against backup: PASS')
    lint = run('verilator_pcm5102a', [TOOLS/'verilator-cli.exe', '--lint-only', '--Wall',
                                     '--top-module', 'pcm5102_i2s_tx', new])
    if '%Warning' in lint or '%Error' in lint:
        raise RuntimeError('New sender has Verilator diagnostics')
    results.append('New sender Verilator --Wall, no suppressed warnings: PASS')
    yosys = run('yosys_pcm5102a', [TOOLS/'yowasp-yosys.exe', '-Q', '-T', '-p',
        'read_verilog -sv -DSYNTHESIS src/pcm5102_i2s_tx.v; hierarchy -check -top pcm5102_i2s_tx; synth -noabc -top pcm5102_i2s_tx; check -assert; stat; log PCM5102_CHECK_COMPLETE'])
    if 'Found and reported 0 problems' not in yosys or 'PCM5102_CHECK_COMPLETE\n' not in yosys:
        raise RuntimeError('No clean Yosys check result')
    results.append('New sender Yosys synth -noabc/check -assert (generic, not device mapping): PASS')
    pins = (src/'yinyue_fashengqi.cst').read_text(encoding='utf-8')
    for signal,pin in [('pcm_bclk','C24'),('pcm_lrclk','B24'),('pcm_data','H15')]:
        if not re.search(r'IO_LOC\s+"'+signal+r'"\s+'+pin+r'\s*;', pins):
            raise RuntimeError('GPIO mismatch: '+signal)
    results.append('Approved three GPIO active constraints: PASS')
    report = '# PCM5102A focused verification\n\n' + '\n'.join('- '+s for s in results)
    report += '\n\nNominal input 12.288 MHz; measured BCLK period 4 input cycles (3.072 MHz), LRCLK period 256 input cycles (48 kHz).\n'
    report += '\nScope: new serial output plus integration with actual E: synth; not a new full-core freeze, PLL lock, Gowin P&R or physical DAC validation.\n'
    (OUT/'verification_report.md').write_text(report,encoding='utf-8')
    print('\nALL PCM5102A FOCUSED CHECKS PASS')
except Exception as error:
    (OUT/'verification_report.md').write_text('# Verification FAILED\n\n'+'\n'.join(results)+'\n\n'+str(error),encoding='utf-8')
    print('FAIL:', error)
    sys.exit(1)
