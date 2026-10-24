"""Reroute a frozen, completed snapshot without relocating synthesis paths.

Archives prior results before the first overwrite. Never programs hardware.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, re, shutil, subprocess, time

R = Path(__file__).resolve().parents[1]
A = R / 'audit/autonomous_timing_20261022_154006'
p = argparse.ArgumentParser()
p.add_argument('snapshot')
p.add_argument('tag')
p.add_argument('--place', type=int, choices=range(5), required=True)
p.add_argument('--route', type=int, choices=range(3), required=True)
p.add_argument('--clock-order', type=int, choices=range(2), default=1)
p.add_argument('--replicate', type=int, choices=range(2), default=0)
o = p.parse_args()
assert all(re.fullmatch('[a-z0-9_]+', v) for v in [o.snapshot, o.tag])
D = A / 'runs' / o.snapshot
prior = json.loads((D / 'RESULT.json').read_text())
assert prior['status'] != 'RUNNING', 'Original build must finish first'
sha = lambda f: hashlib.sha256(f.read_bytes()).hexdigest()
netlist = D / 'impl/gwsynthesis/yinyue_fashengqi.vg'
assert sha(netlist) == prior['final_netlist_sha256']
inputs = {f.relative_to(D).as_posix(): sha(f) for folder in ['src', 'assets']
          for f in (D / folder).rglob('*') if f.is_file()}
inputs['yinyue_fashengqi.gprj'] = sha(D / 'yinyue_fashengqi.gprj')
assert all(prior['inputs'][n] == v for n, v in inputs.items())
original = D / 'attempts/original'
if not original.exists():
    original.mkdir(parents=True)
    for name in ['RESULT.json', 'console.log', 'run.tcl']:
        shutil.copy2(D / name, original / name)
    if (D / 'impl/pnr').exists():
        shutil.copytree(D / 'impl/pnr', original / 'pnr')
E = D / 'attempts' / o.tag
E.mkdir(exist_ok=False)
t = E / 'run.tcl'
t.write_text(f'''cd {{{D.as_posix()}}}
open_project yinyue_fashengqi.gprj
set_option -top_module tang_mega_138k_pro_top
set_option -convert_sdp32_36_to_sdp16_18 0
set_option -timing_driven 1
set_option -correct_hold_violation 1
set_option -place_option {o.place}
set_option -route_option {o.route}
set_option -clock_route_order {o.clock_order}
set_option -replicate_resources {o.replicate}
set_option -cst_warn_to_error 1
set_option -gen_text_timing_rpt 1
run pnr
exit
''')
now = lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
start = time.time(); mono = time.monotonic()
record = dict(status='RUNNING', started_utc=now(), options=vars(o),
              snapshot=str(D), inputs=inputs, netlist_sha256=sha(netlist),
              programming=False, artifact_storage=str(E / 'pnr'))
receipt = E / 'RESULT.json'
receipt.write_text(json.dumps(record, indent=2))
with (E / 'console.log').open('w') as log:
    proc = subprocess.Popen(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe', str(t)],
                            cwd=D, stdout=log, stderr=subprocess.STDOUT)
    record['pid'] = proc.pid
    receipt.write_text(json.dumps(record, indent=2))
    code = proc.wait()
log = (E / 'console.log').read_text(errors='replace')
errors = re.findall(r'^ERROR.*', log, re.M)
artifacts = {}
if (D / 'impl/pnr').exists():
    shutil.copytree(D / 'impl/pnr', E / 'pnr')
for f in (E / 'pnr').glob('*'):
    if f.is_file():
        artifacts[f.name] = dict(bytes=f.stat().st_size, sha256=sha(f),
                                 fresh=f.stat().st_mtime >= start - 2)
slacks = {}; endpoints = {}
tr = E / 'pnr/yinyue_fashengqi.tr'
if tr.exists() and tr.stat().st_mtime >= start - 2:
    text = tr.read_text(errors='replace')
    for name, title in [('setup','3.1.1 Setup Paths Table'), ('hold','3.1.2 Hold Paths Table'),
                        ('recovery','3.1.3 Recovery Paths Table'), ('removal','3.1.4 Removal Paths Table'),
                        ('min_pulse_width','3.2 Minimum Pulse Width Table')]:
        m = re.search('^' + re.escape(title) + r'.*?\n\s*1\s+([\d.-]+)', text, re.M | re.S)
        slacks[name] = float(m[1]) if m else None
    for kind in ['Setup','Hold']:
        m = re.search(r'<Numbers of ' + kind + r' Violated Endpoints>:\s*(\d+)',text)
        endpoints[kind] = int(m[1]) if m else None
unchanged = all(sha(D / n) == digest for n, digest in inputs.items())
netlist_unchanged = sha(netlist) == record['netlist_sha256']
complete = code == 0 and not errors and unchanged and netlist_unchanged and artifacts.get('ao_0.fs',{}).get('fresh',False)
timing = len(slacks) == 5 and all(v is not None and v >= 0 for v in slacks.values()) and endpoints == {'Setup':0,'Hold':0}
record.update(status='PASS' if complete and timing else 'ROUTED_TIMING_FAILED' if complete else 'IMPLEMENTATION_FAILED',
              finished_utc=now(), elapsed_seconds=time.monotonic()-mono, returncode=code,
              errors=errors, worst_slack_ns=slacks, violated_endpoints=endpoints,
              inputs_unchanged=unchanged, netlist_unchanged=netlist_unchanged,
              automatic_synthesis='GowinSynthesis start' in log,
              complete_implementation=complete, artifacts=artifacts)
receipt.write_text(json.dumps(record,indent=2))
print(json.dumps({k:record[k] for k in ['status','elapsed_seconds','errors','worst_slack_ns','violated_endpoints','automatic_synthesis']},indent=2),flush=True)
