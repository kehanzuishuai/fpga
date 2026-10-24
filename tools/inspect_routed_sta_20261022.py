"""Read actual routed reports; independently check required clocks and freshness."""
from pathlib import Path
import argparse, hashlib, json, re

p = argparse.ArgumentParser()
p.add_argument('snapshot', type=Path)
o = p.parse_args()
D = o.snapshot.resolve()
r = json.loads((D / 'RESULT.json').read_text())
T = D / 'impl/pnr/yinyue_fashengqi.tr'
assert T.exists(), 'No complete STA report exists for this snapshot'
s = T.read_text(errors='replace')
sha = lambda f: hashlib.sha256(f.read_bytes()).hexdigest()
assert sha(T) == r['artifacts'][T.name]['sha256'] and r['artifacts'][T.name]['fresh']
assert all(sha(D / n) == h for n,h in r['inputs'].items() if n != 'impl/gwsynthesis/yinyue_fashengqi.vg')
clocks = {}
for m in re.finditer(r'^\s*\d+\s+(\S+)\s+(Base|Generated)\s+([\d.]+)\s+([\d.]+)MHz\s+([\d.]+)\s+([\d.]+)',s,re.M):
    clocks[m[1]] = dict(type=m[2],period_ns=float(m[3]),frequency_mhz=float(m[4]),rise_ns=float(m[5]),fall_ns=float(m[6]))
expected = {'clk_50m':50., 'audio_clk':12.288, 'video_ref':27.,
            'video_serial':371.25, 'video_pixel_pll':74.25, 'video_pixel':74.25,
            'video_serial_global':371.25, 'video_serial_reset':74.25,
            'video_serial_reset_regional':74.25, 'gao_tck_pad':20., 'gao_tck':20.}
if re.search(r'create_generated_clock\s+-name\s+fabric_50m\b', (D / 'src/integrated.sdc').read_text()):
    expected['fabric_50m'] = 50.
assert set(clocks) == set(expected), (clocks.keys(),expected.keys())
assert all(abs(clocks[n]['frequency_mhz']-v) < .002 for n,v in expected.items())
assert abs(clocks['video_pixel']['period_ns']-13.468) < .002
uncertainty_checks=[]
for command in (D/'src/integrated.sdc').read_text().splitlines():
    if not command.startswith('set_clock_uncertainty '):continue
    normalized=' '.join(command.split())
    active=[line for line in s.splitlines() if re.search(r'\bActived\s+set_clock_uncertainty\b',line)]
    assert any(' '.join(line.split()).endswith(normalized) for line in active),('Clock uncertainty constraint not active',command)
    uncertainty_checks.append(dict(command=command,active=True))
min_delay_checks=[]
for command in (D/'src/integrated.sdc').read_text().splitlines():
    if not command.startswith('set_min_delay '):continue
    normalized=' '.join(command.split())
    active=[line for line in s.splitlines() if re.search(r'\bActived\s+set_min_delay\b',line)]
    assert any(' '.join(line.split()).endswith(normalized) for line in active),('Minimum delay constraint not active',command)
    a=s.index('\n3.7.2 Hold Analysis Report');b=s.index('\n3.7.3 Recovery Analysis Report',a)
    excerpt=s[a:b]
    assert 'No timing exceptions to report!' not in excerpt,'Minimum delay matched no reported hold paths'
    min_delay_checks.append(dict(command=command,active=True,hold_exception_excerpt=excerpt[:4000]))
# Check physical IO from the real report, including generated negative pairs.
# Never infer correctness merely from the CST text (a prior probe exposed that).
physical=D/'impl/pnr/yinyue_fashengqi.rpt.txt'
assert sha(physical)==r['artifacts'][physical.name]['sha256'] and r['artifacts'][physical.name]['fresh']
pin_report=physical.read_text(errors='replace')
expected_pins={}
for m in re.finditer(r'^\s*IO_LOC\s+"([^"]+)"\s+([^;]+);',(D/'src/integrated.cst').read_text(),re.M):
    pins=[p.strip() for p in m[2].split(',')]
    expected_pins[m[1]]=pins[0]
    if len(pins)==2:
        assert '_p' in m[1],m[1]
        expected_pins[m[1].replace('_p','_n')]=pins[1]
    else:assert len(pins)==1
actual_pins={}
for n,pin in expected_pins.items():
    m=re.search(r'^'+re.escape(n)+r'\s*\|\s*[^|]+\|\s*([^|]+)\|\s*([YN])\s*\|',pin_report,re.M)
    assert m,('Missing IO report row',n)
    actual=m[1].strip().split('/')[0]
    assert actual==pin and m[2]=='Y',('Pin location not applied',n,actual,pin,m[2])
    actual_pins[n]=actual
assert expected_pins.get('clk_50m')=='P16' and expected_pins.get('rst_n')=='K16'
sections = {}
for name,begin,end in [('fmax','2.3 Max Frequency Summary','2.4 Total Negative Slack Summary'),
                       ('setup','3.1.1 Setup Paths Table','3.1.2 Hold Paths Table'),
                       ('hold','3.1.2 Hold Paths Table','3.1.3 Recovery Paths Table'),
                       ('recovery','3.1.3 Recovery Paths Table','3.1.4 Removal Paths Table'),
                       ('removal','3.1.4 Removal Paths Table','3.2 Minimum Pulse Width Table')]:
    a=s.find('\n'+begin);b=s.find('\n'+end,a+len(begin));sections[name]=s[a:b]
result=dict(status='PASS_REPORT_PROVENANCE_AND_CLOCKS',snapshot=str(D),report_sha256=sha(T),
            clocks=clocks,implementation_status=r['status'],minimum_delay_constraints=min_delay_checks,clock_uncertainty_constraints=uncertainty_checks,
            worst_slack_ns=r['worst_slack_ns'],violated_endpoints=r['violated_endpoints'],actual_io_pins=actual_pins,physical_report_sha256=sha(physical),
            scope='Checks source/report identity and actual full routed clock definitions; does not override any failing STA check.')
(D / 'STA_INSPECTION.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
for name,section in sections.items():
    print('\n'+name+'\n'+'\n'.join(section.splitlines()[:10]))
