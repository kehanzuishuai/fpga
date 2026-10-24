"""Isolated, provenance-tracked PnR attempts. Never programs hardware."""
from pathlib import Path
import argparse, datetime, hashlib, json, re, shutil, subprocess, time

R = Path(__file__).resolve().parents[1]
A = R / 'audit/autonomous_timing_20261022_154006'
arg = argparse.ArgumentParser()
arg.add_argument('tag')
arg.add_argument('--place', type=int, choices=range(5), default=3)
arg.add_argument('--route', type=int, choices=range(3), default=2)
arg.add_argument('--clock-order', type=int, choices=range(2), default=1)
arg.add_argument('--timing-driven', type=int, choices=range(2), default=1)
arg.add_argument('--correct-hold', type=int, choices=range(2), default=1)
arg.add_argument('--local-raw-clock', action='store_true', help='PnR-only CST change: raw P16 clock local, 27MHz reference global; RTL unchanged')
arg.add_argument('--cst-from-root', action='store_true', help='Reuse verified parent RTL synthesis, copying only current root physical constraints into the new attempt')
arg.add_argument('--sdc-from-root', action='store_true', help='Reuse identical root HDL/assets with only stricter min-delay/report changes; clock/group/other exception lines must stay fixed')
arg.add_argument('--replicate', type=int, choices=range(2), default=0)
arg.add_argument('--resynthesize', action='store_true')
arg.add_argument('--synthesis-only', action='store_true', help='Freeze new RTL and measure synthesis first; no PnR or timing PASS claim')
arg.add_argument('--reuse-snapshot', help='Reuse completed synthesis in this frozen snapshot; no RTL edit')
arg.add_argument('--incremental-place', action='store_true', help='Copy verified parent placed checkpoint; requires --reuse-snapshot')
arg.add_argument('--placement-reference-snapshot', help='Completed routed-revision placement hint; requires fresh synthesis or separately verified reused synthesis')
opts = arg.parse_args()
assert not opts.synthesis_only or opts.resynthesize
assert re.fullmatch('[a-z0-9_]+', opts.tag)
S = R
reuse = None
if opts.placement_reference_snapshot:
    assert bool(opts.resynthesize)!=bool(opts.reuse_snapshot), 'Placement reference needs either fresh synthesis or a verified completed synthesis snapshot'
    assert re.fullmatch('[a-z0-9_]+',opts.placement_reference_snapshot)
    opts.incremental_place = True
assert not opts.incremental_place or opts.reuse_snapshot or opts.placement_reference_snapshot
if opts.reuse_snapshot:
    assert not opts.resynthesize and re.fullmatch('[a-z0-9_]+', opts.reuse_snapshot)
    S = A / 'runs' / opts.reuse_snapshot
    parent = json.loads((S / 'RESULT.json').read_text())
    parent_log = (S / 'console.log').read_text(errors='replace')
    # A later failed PnR does not invalidate the successfully generated netlist.
    assert 'GowinSynthesis finish' in parent_log
    assert not re.findall(r'^ERROR.*', parent_log.split('GowinSynthesis finish',1)[0], re.M)
    for name, digest in parent['inputs'].items():
        if name.startswith(('src/', 'assets/')) or name == 'yinyue_fashengqi.gprj':
            assert hashlib.sha256((S / name).read_bytes()).hexdigest() == digest, name
    reuse = {'parent': str(S), 'netlist_sha256': hashlib.sha256((S / 'impl/gwsynthesis/yinyue_fashengqi.vg').read_bytes()).hexdigest(),
             'synthesis_report_sha256': hashlib.sha256((S / 'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html').read_bytes()).hexdigest(),
             'scope': 'Parent synthesis finished; all original source/assets/project hashes verified. Only placement/routing algorithm changes.'}
D = A / 'runs' / opts.tag
D.mkdir(parents=True, exist_ok=False)
now = lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
for name in ['src', 'assets', 'impl/gwsynthesis']:
    shutil.copytree(S / name, D / name)
shutil.copy2(S / 'yinyue_fashengqi.gprj', D / 'yinyue_fashengqi.gprj')
constraint_change=None
minimum_change=None
if opts.sdc_from_root:
    assert opts.reuse_snapshot and not opts.local_raw_clock
    from strict_sdc_delta_20261023 import verify_stricter_sdc
    import xml.etree.ElementTree as ET
    allowed={'src/integrated.sdc'}|({'src/integrated.cst'} if opts.cst_from_root else set())
    for file in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File'):
        n=file.get('path')
        if file.get('enable')=='1' and n not in allowed:assert sha(R/n)==sha(S/n),('Root HDL/input differs',n)
    assert sha(R/'yinyue_fashengqi.gprj')==sha(S/'yinyue_fashengqi.gprj')
    for f in (R/'assets').rglob('*'):
        if f.is_file():assert sha(f)==sha(S/f.relative_to(R)),('Asset differs',f)
    target=D/'src/integrated.sdc';previous=sha(target)
    delta=verify_stricter_sdc(target.read_text(),(R/'src/integrated.sdc').read_text())
    shutil.copy2(R/'src/integrated.sdc',target)
    minimum_change=dict(previous_sha256=previous,new_sha256=sha(target),**delta)
    reuse['scope']='Identical root HDL/assets and verified parent synthesis; separately recorded stricter min-delay/report SDC change, no resynthesis.'
if opts.cst_from_root:
    assert opts.reuse_snapshot and not opts.local_raw_clock
    assert sha(S/'src/display/visual_dvi_io.v')==sha(R/'src/display/visual_dvi_io.v'),'HDMI target logic differs'
    before=sha(D/'src/integrated.cst')
    shutil.copy2(R/'src/integrated.cst',D/'src/integrated.cst')
    constraint_change=dict(source=str(R/'src/integrated.cst'),previous_sha256=before,new_sha256=sha(D/'src/integrated.cst'),scope='CST only; no HDL, SDC or synthesis netlist changed.')
    reuse['scope']='Parent synthesis complete and source hashes verified; unchanged HDL/netlist reused with separately recorded PnR-only physical constraints.'
if opts.local_raw_clock:
    assert opts.reuse_snapshot, 'Constraint-only experiment must reuse verified unchanged RTL synthesis'
    cst=D/'src/integrated.cst'
    cst.write_text(cst.read_text()+'\n// Only low-fanout input/PLL-init logic uses the raw P16 net.\nCLOCK_LOC "clk_50m_d" LOCAL_CLOCK;\nCLOCK_LOC "u_video_clock/ref_clk" BUFG = CLK;\n')
config = S / 'impl/yinyue_fashengqi_process_config.json'
shutil.copy2(config if config.exists() else R / 'impl/yinyue_fashengqi_process_config.json', D / 'impl/yinyue_fashengqi_process_config.json')
if reuse:
    # Preserve the verified synthesis result only. PnR state is explicitly pending.
    (D / 'yinyue_fashengqi.gprj.user').write_text('''<?xml version="1" encoding="UTF-8"?>
<!DOCTYPE ProjectUserData><UserConfig><Version>1.0</Version><FlowState>
<Process ID="Synthesis" State="2"/><Process ID="Pnr" State="0"/>
<Process ID="Gao" State="2"/><Process ID="Rtl_Gao" State="2"/>
<Process ID="Gvio" State="0"/><Process ID="Place" State="0"/>
</FlowState><ResultFileList>
<ResultFile ResultFileType="RES.netlist" ResultFilePath="impl/gwsynthesis/yinyue_fashengqi.vg"/>
<ResultFile ResultFileType="RES.syn.report" ResultFilePath="impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html"/>
<ResultFile ResultFileType="RES.syn.resource" ResultFilePath="impl/gwsynthesis/yinyue_fashengqi_syn_rsc.xml"/>
</ResultFileList><Ui></Ui><FpUi></FpUi></UserConfig>''')
placement = None
if opts.incremental_place:
    place_parent = A / 'runs' / opts.placement_reference_snapshot if opts.placement_reference_snapshot else S
    source_place = place_parent / 'impl/pnr/yinyue_fashengqi.p'
    if opts.placement_reference_snapshot:
        reference_record=json.loads((place_parent/'RESULT.json').read_text(encoding='utf-8-sig'))
        assert reference_record.get('complete_implementation'), 'Cross-revision hint must come from a completed whole route'
        assert reference_record['inputs_unchanged']
        for n,h in reference_record['inputs'].items():
            if n.startswith(('src/','assets/')) or n=='yinyue_fashengqi.gprj':
                assert sha(place_parent/n)==h,('Reference source drift',n)
        assert reference_record['final_netlist_sha256']==sha(place_parent/'impl/gwsynthesis/yinyue_fashengqi.vg')
        assert reference_record['artifacts'][source_place.name]['fresh']
        assert reference_record['artifacts'][source_place.name]['sha256']==sha(source_place)
        assert sha(place_parent/'yinyue_fashengqi.gprj')==sha(D/'yinyue_fashengqi.gprj'), 'Reference device/project differs'
        assert sha(place_parent/'src/integrated.cst')==sha(D/'src/integrated.cst'), 'Reference IO/clock physical constraints differ'
        def clock_and_exception_commands(path):
            return [line.strip() for line in path.read_text().splitlines()
                    if line.strip() and not line.lstrip().startswith(('#','set_min_delay ','report_timing '))]
        assert clock_and_exception_commands(place_parent/'src/integrated.sdc')==clock_and_exception_commands(D/'src/integrated.sdc'), 'Reference clock relationships differ'
    place_hash = sha(source_place)
    shutil.copy2(source_place, D / 'reference.p')
    assert sha(source_place) == place_hash == sha(D / 'reference.p')
    placement = {'parent': str(source_place), 'sha256': place_hash,
                 'parent_netlist_sha256':sha(place_parent/'impl/gwsynthesis/yinyue_fashengqi.vg'),
                 'scope': 'Placement hint only. Current netlist is freshly synthesized or reused from its separately verified synthesis parent. Matching cells from a different revision may retain vendor placement hints; all routing and STA are recomputed.'}
tcl = D / 'run.tcl'
tcl.write_text(f'''cd {{{D.as_posix()}}}
open_project yinyue_fashengqi.gprj
set_option -top_module tang_mega_138k_pro_top
set_option -convert_sdp32_36_to_sdp16_18 0
set_option -timing_driven {opts.timing_driven}
set_option -correct_hold_violation {opts.correct_hold}
set_option -place_option {opts.place}
set_option -route_option {opts.route}
set_option -clock_route_order {opts.clock_order}
set_option -replicate_resources {opts.replicate}
set_option -cst_warn_to_error 1
set_option -gen_text_timing_rpt 1
{('set_option -inc_place {' + (D / 'reference.p').as_posix() + '}') if placement else ''}
run {'syn' if opts.synthesis_only else 'all' if opts.resynthesize else 'pnr'}
exit
''')
inputs = {p.relative_to(D).as_posix(): sha(p) for directory in ['src', 'assets'] for p in (D / directory).rglob('*') if p.is_file()}
for name in ['yinyue_fashengqi.gprj', 'impl/gwsynthesis/yinyue_fashengqi.vg', 'run.tcl']:
    inputs[name] = sha(D / name)
if placement:
    inputs['reference.p'] = sha(D / 'reference.p')
record = {'status': 'RUNNING', 'started_utc': now(), 'tag': opts.tag,
          'options': vars(opts), 'inputs': inputs, 'programming': False,
          'synthesis_reuse': reuse,
          'placement_reuse': placement,
          'physical_constraint_change':constraint_change,
          'minimum_constraint_change':minimum_change,
          'scope': 'Independent snapshot of source/assets/netlist, PnR plus automatic STA only.'}
receipt = D / 'RESULT.json'
receipt.write_text(json.dumps(record, indent=2))
started = time.time()
with (D / 'console.log').open('w') as f:
    p = subprocess.Popen(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe', str(tcl)], cwd=D, stdout=f, stderr=subprocess.STDOUT)
    record['pid'] = p.pid
    receipt.write_text(json.dumps(record, indent=2))
    code = p.wait()
log = (D / 'console.log').read_text(errors='replace')
errors = re.findall(r'^ERROR.*', log, re.M)
artifacts = {}
for p in (D / 'impl/pnr').glob('*'):
    if p.is_file():
        artifacts[p.name] = {'bytes': p.stat().st_size, 'sha256': sha(p), 'fresh': p.stat().st_mtime >= started - 2}
tr = D / 'impl/pnr/yinyue_fashengqi.tr'
slacks = {}; endpoints = {}
if tr.exists() and tr.stat().st_mtime >= started - 2:
    text = tr.read_text(errors='replace')
    titles = {'setup': '3.1.1 Setup Paths Table', 'hold': '3.1.2 Hold Paths Table',
              'recovery': '3.1.3 Recovery Paths Table', 'removal': '3.1.4 Removal Paths Table',
              'min_pulse_width': '3.2 Minimum Pulse Width Table'}
    for name, title in titles.items():
        m = re.search('^' + re.escape(title) + r'.*?\n\s*1\s+([\d.-]+)', text, re.M | re.S)
        slacks[name] = float(m[1]) if m else None
    for kind in ['Setup', 'Hold']:
        m = re.search(r'<Numbers of ' + kind + r' Violated Endpoints>:\s*(\d+)', text)
        endpoints[kind] = int(m[1]) if m else None
netlist_name = 'impl/gwsynthesis/yinyue_fashengqi.vg'
unchanged = all(sha(D / name) == digest for name, digest in inputs.items() if name != netlist_name)
record['initial_netlist_sha256'] = inputs[netlist_name]
record['final_netlist_sha256'] = sha(D / netlist_name)
record['automatic_synthesis_in_snapshot'] = 'GowinSynthesis start' in log
timing_pass = len(slacks) == 5 and all(v is not None and v >= 0 for v in slacks.values()) and endpoints == {'Setup': 0, 'Hold': 0}
complete = code == 0 and not errors and artifacts.get('ao_0.fs', {}).get('fresh', False) and unchanged
record.update(status='PASS' if complete and timing_pass else 'ROUTED_TIMING_FAILED' if complete else 'IMPLEMENTATION_FAILED',
              finished_utc=now(), elapsed_seconds=time.time()-started, returncode=code,
              errors=errors, inputs_unchanged=unchanged, complete_implementation=complete,
              worst_slack_ns=slacks, violated_endpoints=endpoints, artifacts=artifacts)
if opts.synthesis_only:
    record['status']='SYNTHESIS_PASSED_PNR_PENDING' if code==0 and not errors and unchanged and 'GowinSynthesis finish' in log else 'SYNTHESIS_FAILED'
    record['scope']='New frozen source fully synthesized only; no PnR, FS or final STA claim.'
receipt.write_text(json.dumps(record, indent=2))
print(json.dumps({k: record[k] for k in ['status', 'tag', 'elapsed_seconds', 'errors', 'worst_slack_ns', 'violated_endpoints']}, indent=2), flush=True)
