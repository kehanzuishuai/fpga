"""Record a finished physical display probe only when its snapshots are current."""
from pathlib import Path
import datetime, hashlib, html, json, re, sys, xml.etree.ElementTree as ET

R = Path(__file__).resolve().parents[2]
O = Path(__file__).resolve().parent / 'out'
probe = Path(__file__).resolve().parent / 'resource' / sys.argv[1]
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
log = (probe / 'probe.log').read_text(errors='replace')
assert 'GowinSynthesis finish' in log and not re.search(r'^ERROR', log, re.M)
inputs = {}
snapshot_inputs = {}
for f in ET.parse(probe / 'probe.gprj').findall('./FileList/File'):
    p = Path(f.get('path'))
    if p.name == 'probe_top.sv':
        continue
    current = R / 'src/display' / p.name if p.parent == probe else p
    assert current.is_file() and current.read_bytes().replace(b'\r\n', b'\n') == p.read_bytes().replace(b'\r\n', b'\n'), 'Stale probe: ' + str(p)
    name = current.relative_to(R).as_posix()
    inputs[name] = sha(current)
    snapshot_inputs[name] = sha(p)
for p in (probe / 'assets').glob('*.hex'):
    current = R / 'assets' / p.name
    assert sha(current) == sha(p), 'Stale asset: ' + p.name
    inputs[current.relative_to(R).as_posix()] = sha(p)
report = probe / 'impl/gwsynthesis/probe_syn.rpt.html'
s = report.read_text(errors='replace')
a = s.index('<a name="performance">')
b = s.index('<h3>Path&nbsp1', a)
summary = ' '.join(html.unescape(re.sub('<[^>]+>', ' ', s[a:b])).split())
frequency = {name: float(actual) for name, constraint, actual in re.findall(
    r'(\S+)\s+(\d+\.\d+)\(MHz\)\s+(\d+\.\d+)\(MHz\)', summary)}
pixel = frequency['clocks/physical_pixel']
record = {
    'status': 'SYNTHESIS_ESTIMATE_ABOVE_PIXEL_REQUIREMENT' if pixel >= 74.25 else 'SYNTHESIS_ESTIMATE_BELOW_PIXEL_REQUIREMENT',
    'recorded_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'estimate_mhz': pixel, 'required_pixel_mhz': 74.25,
    'probe_clock_constraint_mhz': 100.0, 'routed': False,
    'scope': 'Complete visual_audio_core with actual raster, native frame stores, FFT, CDC, renderer, TMDS, physical video PLL/DCS/OSER10 and real audio PLL; status bit5 fixed0. Synthesis estimate only, no post-route STA claim.',
    'clock_frequency_estimates_mhz': frequency,
    'report': report.relative_to(R).as_posix(),
    'report_sha256': sha(report),
    'wrapper_sha256': sha(probe / 'probe_top.sv'),
    'netlist_sha256': sha(probe / 'impl/gwsynthesis/probe.vg'),
    'resources': ET.parse(probe / 'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib,
    'source_sha256': inputs,
    'snapshot_source_sha256': snapshot_inputs,
    'source_comparison': 'Exact bytes after normalizing CRLF/LF only; actual current and snapshot digests both recorded.',
}
(O / 'DISPLAY_CORE_TIMING_ESTIMATE.json').write_text(json.dumps(record, indent=2))
print(record['status'], pixel, 'MHz; physical display probe only')
