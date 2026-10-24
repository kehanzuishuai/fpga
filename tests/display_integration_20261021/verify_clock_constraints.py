"""Verify appended clock constraints and safe reuse of the existing RTL netlist."""
from pathlib import Path
import datetime, hashlib, json, re, xml.etree.ElementTree as ET

R = Path(__file__).resolve().parents[2]
A = R / 'audit/clock_constraints_20261022'
O = Path(__file__).resolve().parent / 'out'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
base = json.loads((R / 'audit/display_integration_20261021/SYN_DISTRIBUTED_SHIFT_ALL.json').read_text())
constraints = ['src/integrated.cst', 'src/integrated.sdc']
for name, digest in base['inputs'].items():
    if name not in constraints:
        assert sha(R / name) == digest, 'Netlist input changed: ' + name
net = R / 'impl/gwsynthesis/yinyue_fashengqi.vg'
assert sha(net) == base['netlist_sha256'], 'Mapped netlist changed'
s = net.read_text()
top = s[s.index('module tang_mega_138k_pro_top ('):]
assert re.search(r'\binput tck_pad_i;', top)
assert re.search(r'IBUF clk_50m_ibuf\s*\(\s*\.O\(clk_50m_d\),\s*\.I\(clk_50m\)', top)
assert re.search(r'GW_JTAG u_gw_jtag\s*\([^;]*\.tck_o\(control0\[0\]\)', s)
assert 'gw_gao gw_gao_inst_0 (' in top
for name in constraints:
    old = (A / 'before' / name).read_text()
    new = (R / name).read_text()
    assert new.startswith(old.rstrip()), 'Original constraints modified: ' + name
cst = (R / constraints[0]).read_text()
assert 'CLOCK_LOC "clk_50m_d" BUFG = CLK;' in cst
sdc = (R / constraints[1]).read_text()
assert 'create_clock -name gao_tck_pad -period 50.000 [get_ports {tck_pad_i}]' in sdc
assert 'create_generated_clock -name gao_tck -source [get_ports {tck_pad_i}] -divide_by 1 [get_pins {gw_gao_inst_0/u_gw_jtag/tck_o}]' in sdc
assert sdc.count('set_false_path') == (A / 'before' / constraints[1]).read_text().count('set_false_path')
log = (O / 'clock_constraints_tcl.log').read_text(errors='replace')
assert 'PASS Tcl syntax and references for11 clocks' in log
files = [R / e.get('path') for e in ET.parse(R / 'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable') == '1']
assert all(p.is_file() for p in files)
assert all(any(p == R / name for p in files) for name in constraints)
closure = json.loads((O / 'CHECKS.json').read_text())
for name, digest in closure['source_sha256'].items():
    if name not in constraints:
        assert sha(R / name) == digest, 'Previous board elaboration dependency changed: ' + name
record = {
    'status': 'PASS_STATIC_AND_TCL_ONLY_IMPLEMENTATION_PENDING',
    'recorded_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'scope': 'Original constraints retained verbatim apart from line endings; only primary-clock routing and independent GAO TCK definitions appended. All nonconstraint synthesis inputs and mapped netlist unchanged. Pin targets checked in actual netlist; Tcl grammar/clock references checked using command stubs, not the PnR constraint mapper.',
    'base_synthesis_receipt': 'audit/display_integration_20261021/SYN_DISTRIBUTED_SHIFT_ALL.json',
    'mapped_netlist_sha256': sha(net),
    'current_enabled_inputs': {p.relative_to(R).as_posix(): sha(p) for p in files},
    'gprj_sha256': sha(R / 'yinyue_fashengqi.gprj'),
    'constraints': {name: {'before_sha256': sha(A / 'before' / name), 'after_sha256': sha(R / name)} for name in constraints},
    'tcl_syntax_check_log': 'tests/display_integration_20261021/out/clock_constraints_tcl.log',
    'rao_and_gao_preserved': True, 'gao_tck_constraint_max_mhz': 20,
    'new_synthesis_needed': False, 'new_pnr_started': False, 'new_sta_passed': False, 'programming': False,
}
(A / 'RESULT.json').write_text(json.dumps(record, indent=2))
print('PASS mapped targets,11 clock definitions, unchanged RTL/assets/pin assignments; reuse existing netlist, new manual implementation required')
