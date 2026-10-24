"""Sequential PnR-only sweep on one verified synthesis snapshot. Never programs hardware.

Each variant reuses the synthesis of SNAPSHOT (same source as the project root)
through tools/autonomous_timing_20261022.py, one gw_sh at a time. The driver
stops a gw_sh that hangs after a Tcl error or exceeds the time limit, renews the
bounded keep-awake request per run, records every result in SWEEP.json and stops
at the first run whose own receipt says PASS. Extra jobs (for example a branch
build with its own copy of the build script) can be queued in INSERT.json as
[{"tag":..., "cwd":..., "argv":[...], "result":...}]; they run before the next
variant under the same watchdog and are recorded but do not stop the sweep.
"""
from pathlib import Path
import json, subprocess, sys, time, datetime

R = Path(__file__).resolve().parents[1]
A = R / 'audit/autonomous_timing_20261022_154006/runs'
OUT = R / 'audit/pnr_sweep_20261024'
PY = sys.executable
SNAPSHOT = 'v11b_gs_p3_r0'
LIMIT_S = 80 * 60
VARIANTS = [
    ('sweep_v11b_hint_v10', ['--placement-reference-snapshot', 'v10_ks_sf_p3_r0', '--place', '3', '--route', '0', '--clock-order', '0']),
    ('sweep_v11b_p3_c1', ['--place', '3', '--route', '0', '--clock-order', '1']),
    ('sweep_v11b_p4', ['--place', '4', '--route', '0', '--clock-order', '0']),
    ('sweep_v11b_p2', ['--place', '2', '--route', '0', '--clock-order', '0']),
    ('sweep_v11b_p0', ['--place', '0', '--route', '0', '--clock-order', '0']),
    ('sweep_v11b_p3_rep', ['--place', '3', '--route', '0', '--clock-order', '0', '--replicate', '1']),
]


def now():
    return datetime.datetime.now().isoformat(timespec='seconds')


def ps(command):
    return subprocess.run(['powershell', '-NoProfile', '-Command', command], capture_output=True, text=True).stdout


def stop_gw_sh(tag):
    return ps("Get-CimInstance Win32_Process -Filter \"Name='gw_sh.exe'\" | Where-Object { $_.CommandLine -match '%s' } | "
              "ForEach-Object { Stop-Process -Id $_.ProcessId -Force; $_.ProcessId }" % tag).strip()


def main():
    OUT.mkdir(exist_ok=True)
    record_path = OUT / 'SWEEP.json'
    record = json.loads(record_path.read_text()) if record_path.exists() else {'snapshot': SNAPSHOT, 'runs': []}
    done = {r['tag'] for r in record['runs']}
    def run_job(tag, argv, cwd, run_dir, entry):
        assert not ps("Get-Process gw_sh -ErrorAction SilentlyContinue").strip(), 'another gw_sh is running'
        subprocess.Popen(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                          str(R / 'tools/bounded_native_build_awake_20261023.ps1'), '-Minutes', '90'])
        log = (OUT / f'{tag}_driver.txt').open('w')
        proc = subprocess.Popen(argv, cwd=cwd, stdout=log, stderr=subprocess.STDOUT)
        t0 = time.time()
        while proc.poll() is None:
            time.sleep(30)
            console = run_dir / 'console.log'
            text = console.read_text(errors='replace') if console.exists() else ''
            if 'while executing' in text and 'stopped' not in entry:
                entry['stopped'] = 'gw_sh hung after Tcl error: ' + stop_gw_sh(tag)
            elif time.time() - t0 > LIMIT_S and 'stopped' not in entry:
                entry['stopped'] = 'time limit: ' + stop_gw_sh(tag)
        log.close()

    def read_result(entry, result):
        if result.exists():
            r = json.loads(result.read_text())
            entry.update(status=r.get('status'), worst_slack_ns=r.get('worst_slack_ns'),
                         violated_endpoints=r.get('violated_endpoints'), errors=r.get('errors'),
                         elapsed_seconds=round(r.get('elapsed_seconds', 0)))

    def drain_inserts():
        insert_path = OUT / 'INSERT.json'
        while insert_path.exists():
            jobs = json.loads(insert_path.read_text())
            if not jobs:
                insert_path.unlink();break
            job = jobs.pop(0);insert_path.write_text(json.dumps(jobs, indent=2))
            entry = {'tag': job['tag'], 'inserted': True, 'argv': job['argv'], 'cwd': job['cwd'], 'started': now()}
            run_job(job['tag'], job['argv'], job['cwd'], Path(job['result']).parent, entry)
            read_result(entry, Path(job['result']));entry['finished'] = now()
            record['runs'].append(entry);record_path.write_text(json.dumps(record, indent=2))
            print(json.dumps(entry), flush=True)

    for tag, args in VARIANTS:
        drain_inserts()
        if tag in done:
            continue
        if any(r.get('status') == 'PASS' and not r.get('inserted') for r in record['runs']):
            break
        entry = {'tag': tag, 'args': args, 'started': now()}
        run_job(tag, [PY, str(R / 'tools/autonomous_timing_20261022.py'), tag, '--reuse-snapshot', SNAPSHOT, *args], R, A / tag, entry)
        result = A / tag / 'RESULT.json'
        read_result(entry, result)
        entry['finished'] = now()
        record['runs'].append(entry)
        record_path.write_text(json.dumps(record, indent=2))
        print(json.dumps(entry), flush=True)
    drain_inserts()
    record['finished'] = now()
    record_path.write_text(json.dumps(record, indent=2))


if __name__ == '__main__':
    main()
