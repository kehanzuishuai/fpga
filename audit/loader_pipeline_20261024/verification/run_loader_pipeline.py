"""Branch loader_pipe_20261024 (from v12) + equivalence of the pipelined loader.

Old and new loader take the same 600 requests (77 corner cases of note x
velocity, then random; random voice-fading waits and request gaps); for every
load the voice-visible result (16 x 25 RAM words, rel_slope, future_audible
record) must be identical, and the new loader must be faster.
"""
from pathlib import Path
import hashlib, json, re, shutil, subprocess, sys
R = Path(r'D:\gaoyun\piano_v2_audio_fix')
V = R / 'branches/v12_20261024'
B = R / 'branches/loader_pipe_20261024'
A = R / 'audit/loader_pipeline_20261024'
O = A / 'verification'
IV = Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
TOOL = 'loader_pipeline_20261024.py'
res = {}
if not B.exists():
    for n in ('src', 'assets', 'tools', 'impl'):
        shutil.copytree(V / n, B / n)
    for n in ('yinyue_fashengqi.gprj',):
        shutil.copy2(V / n, B / n)
    res['branch'] = 'created from v12_20261024'
(A / 'before').mkdir(parents=True, exist_ok=True)
before = A / 'before/piano_note_loader.v'
if not before.exists():
    shutil.copy2(V / 'src/piano_note_loader.v', before)
shutil.copy2(R / 'tools' / TOOL, B / 'tools' / TOOL)
py = sys.executable
runs = [subprocess.run([py, str(B / 'tools' / TOOL), str(B)], capture_output=True, text=True) for _ in range(2)]
res['apply'] = [r.stdout.strip().replace(str(B), 'B') + r.stderr[-300:] for r in runs]
assert runs[1].stdout.startswith('unchanged'), res['apply']
O.mkdir(parents=True, exist_ok=True)
old = before.read_text(encoding='utf-8').replace('module piano_note_loader', 'module pre_piano_note_loader')
(O / 'pre_piano_note_loader.v').write_text(old, encoding='utf-8')
# Fast run: 600 loads on the array ROM models (sim/models/piano_roms_fast.v, same
# contents, same one-clock read latency). Real run: 40 loads on src/piano_*_rom.v.
roms = {'fast': [R / 'sim/models/piano_roms_fast.v'],
        'real': [B / 'src/piano_level_rom.v', B / 'src/piano_ratio_rom.v', B / 'src/piano_note_rom.v']}
ok_all = True
for label, nreq in (('fast', 600), ('real', 40)):
    W = O / label
    W.mkdir(exist_ok=True)
    files = [O / 'tb_loader_pipeline.sv', O / 'pre_piano_note_loader.v', B / 'src/piano_note_loader.v', *roms[label]]
    r = {}
    with (W / 'compile.log').open('w') as f:
        p = subprocess.run([str(IV), '-g2012', '-s', 'tb_loader_pipeline', f'-Ptb_loader_pipeline.NREQ={nreq}', '-o', str(W / 'loader.vvp'),
                            *map(str, files)], cwd=W, stdout=f, stderr=subprocess.STDOUT)
    r['compile'] = p.returncode
    ok = False
    if p.returncode == 0:
        with (W / 'simulation.log').open('w') as f:
            subprocess.run([str(IV.with_name('vvp.exe')), str(W / 'loader.vvp')], cwd=W, stdout=f, stderr=subprocess.STDOUT, timeout=10800)
        r['simulation'] = (W / 'simulation.log').read_text().strip().splitlines()
        a = (W / 'old.txt').read_text().splitlines() if (W / 'old.txt').exists() else []
        b = (W / 'new.txt').read_text().splitlines() if (W / 'new.txt').exists() else []
        diff = [i for i, (x, y) in enumerate(zip(a, b)) if x != y]
        r['log_lines'] = [len(a), len(b)]
        r['differing_lines'] = len(diff) + abs(len(a) - len(b))
        r['first_differences'] = [(a[i], b[i]) for i in diff[:5]]
        r['x_words'] = sum('x' in l.split()[-1] for l in b if not l.startswith('done'))
        m = [re.search(r'max (\d+) mean (\d+).*bp_before_clear (\d+)', l) for l in r['simulation'][:2]]
        ok = (len(a) == len(b) == nreq * 401 and not diff and r['x_words'] == 0 and all(m)
              and int(m[0].group(3)) == 0 and int(m[1].group(3)) == 0 and int(m[1].group(1)) < int(m[0].group(1)))
    r['status'] = 'PASS' if ok else 'FAIL'
    ok_all = ok_all and ok
    res[label] = r
res['status'] = 'PASS' if ok_all else 'FAIL'
res['new_loader_sha256'] = hashlib.sha256((B / 'src/piano_note_loader.v').read_bytes()).hexdigest()
(O / 'RESULT.json').write_text(json.dumps(res, indent=1, ensure_ascii=False), encoding='utf-8')
print(json.dumps({'status': res['status'], **{k: {x: res[k].get(x) for x in ('status', 'simulation', 'differing_lines', 'x_words')} for k in ('fast', 'real')}}, ensure_ascii=False))
