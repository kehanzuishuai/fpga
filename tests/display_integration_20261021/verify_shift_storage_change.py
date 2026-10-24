"""Reuse the pixel simulation only after proving functional source identity.

This is an annotation-only source proof, not a new post-synthesis simulation.
Gowin's documented distributed_ram shift inference preserves the RTL latency.
"""
from pathlib import Path
import hashlib, json, re

R = Path(__file__).resolve().parents[2]
A = R / 'audit/routing_repair_20261022'
O = Path(__file__).resolve().parent / 'out'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
changed = ['src/display/visual_scene.sv', 'src/display/visual_renderer.sv', 'src/display/visual_labels.sv']
normalize = lambda s: re.sub(r'syn_srlstyle\s*=\s*"(?:registers|distributed_ram)"', 'syn_srlstyle="NORMALIZED"', s)
for name in changed:
    before = (A / 'before' / name).read_text()
    after = (R / name).read_text()
    assert normalize(before) == normalize(after), 'Functional source changed: ' + name
    assert len(re.findall(r'syn_srlstyle\s*=\s*"distributed_ram"', after)) == 1

simulation = O / 'RENDERER_EQUIVALENCE.json'
evidence = json.loads(simulation.read_text())
assert evidence['status'] == 'PASS'
current = {}
for name, digest in evidence['files'].items():
    p = R / name
    canonical = p.relative_to(R).as_posix()
    original = A / 'before' / canonical if canonical in changed else p
    assert sha(original) == digest, 'Historical simulation dependency changed: ' + name
    current[canonical] = sha(p)

record = {
    'status': 'PASS',
    'scope': 'Only three syn_srlstyle attributes changed. Functional source identity to the original 2048-pixel RGB/sync simulation is proven; no new post-synthesis simulation or STA claim.',
    'historical_pixel_simulation': simulation.relative_to(R).as_posix(),
    'historical_pixel_simulation_sha256': sha(simulation),
    'changed_annotations': changed,
    'extra_pixel_clocks': evidence['extra_clocks'],
    'files': current,
}
(O / 'SHIFT_STORAGE_EQUIVALENCE.json').write_text(json.dumps(record, indent=2))
print('PASS annotation-only functional identity; existing 2048-pixel RGB/sync evidence reused, no repeated frame regression')
