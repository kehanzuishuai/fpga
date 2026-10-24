"""Branch v13_20261024 (= loader_pipe_20261024 + physical-key recording) and its checks."""
from pathlib import Path
import hashlib, json, re, shutil, subprocess, sys
R = Path(r'D:\gaoyun\piano_v2_audio_fix')
L = R / 'branches/loader_pipe_20261024'
B = R / 'branches/v13_20261024'
A = R / 'audit/remote_recording_20261024'
O = A / 'verification'
IV = Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
TOOL = 'remote_recording_20261024.py'
FILES = ['src/remote/control/wifi_control.sv', 'src/remote/wifi_core.sv', 'src/remote/remote_control.sv']
res = {}
if not B.exists():
    for n in ('src', 'assets', 'tools', 'impl'):
        shutil.copytree(L / n, B / n)
    shutil.copy2(L / 'yinyue_fashengqi.gprj', B / 'yinyue_fashengqi.gprj')
    res['branch'] = 'created from loader_pipe_20261024'
(A / 'before').mkdir(parents=True, exist_ok=True)
for f in FILES:
    dst = A / 'before' / Path(f).name
    if not dst.exists():
        shutil.copy2(L / f, dst)
shutil.copy2(R / 'tools' / TOOL, B / 'tools' / TOOL)
runs = [subprocess.run([sys.executable, str(B / 'tools' / TOOL), str(B)], capture_output=True, text=True) for _ in range(2)]
res['apply'] = [r.stdout.strip().replace(str(B), 'B') + r.stderr[-400:] for r in runs]
assert runs[0].returncode == 0 and runs[1].stdout.count('unchanged') == 3, res['apply']
old = (A / 'before/wifi_control.sv').read_text(encoding='utf-8').replace('module wifi_control', 'module pre_wifi_control')
(O / 'pre_wifi_control.sv').write_text(old, encoding='utf-8')
with (O / 'compile.log').open('w') as f:
    p = subprocess.run([str(IV), '-g2012', '-s', 'tb_recording', '-o', str(O / 'rec.vvp'), str(O / 'tb_recording.sv'),
                        str(O / 'pre_wifi_control.sv'), str(B / 'src/remote/control/wifi_control.sv')], cwd=O, stdout=f, stderr=subprocess.STDOUT)
res['compile'] = p.returncode
if p.returncode == 0:
    with (O / 'simulation.log').open('w') as f:
        subprocess.run([str(IV.with_name('vvp.exe')), str(O / 'rec.vvp')], cwd=O, stdout=f, stderr=subprocess.STDOUT, timeout=7200)
    res['simulation'] = (O / 'simulation.log').read_text().strip().splitlines()[-8:]
    res['status'] = 'PASS' if any(l.startswith('PASS recording') for l in res['simulation']) else 'FAIL'
res['sha256'] = {f: hashlib.sha256((B / f).read_bytes()).hexdigest() for f in FILES}
(O / 'RESULT.json').write_text(json.dumps(res, indent=1, ensure_ascii=False), encoding='utf-8')
print(json.dumps({k: res.get(k) for k in ('status', 'compile', 'simulation')}, ensure_ascii=False))
