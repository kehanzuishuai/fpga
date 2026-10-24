"""Rerun clock topology at verified production IO locations; never program."""
from pathlib import Path
import json,hashlib,re,shutil,subprocess,datetime
R=Path(__file__).resolve().parents[1];A=R/'audit/autonomous_timing_20261022_154006'
S=A/'clock_topology_probe';D=A/'clock_topology_p16_verified'
D.mkdir(exist_ok=False)
for n in ['src','top.v','probe.gprj','probe.sdc']:
    if (S/n).is_dir():shutil.copytree(S/n,D/n)
    else:shutil.copy2(S/n,D/n)
ports={'clk_50m','rst_n','video_d_p[0]','video_d_p[1]','video_d_p[2]','video_ck_p','i2s_bclk','i2s_lrck','i2s_data','audio_pa_en'}
lines=[]
for l in (R/'src/integrated.cst').read_text().splitlines():
    m=re.match(r'\s*(IO_LOC|IO_PORT)\s+"([^"]+)"',l)
    if m and m[2] in ports or re.match(r'\s*INS_LOC\s+"u_video_io/',l):lines.append(l)
locs={m[1]:m[2] for l in lines if (m:=re.match(r'\s*IO_LOC\s+"([^"]+)"\s+([^;]+);',l))}
assert set(locs)==ports and locs['clk_50m']=='P16' and locs['rst_n']=='K16',locs
(D/'probe.cst').write_text('\n'.join(lines)+'\n')
(D/'run.tcl').write_text((S/'run.tcl').read_text().replace(S.as_posix(),D.as_posix()))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rec=dict(status='RUNNING',started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),production_pin_constraints=locs,
         scope='Small diagnostic, not a production pass. IO pin constraints parsed with whitespace tolerance and independently verified in actual report.',programming=False,
         inputs={p.relative_to(D).as_posix():sha(p) for p in D.rglob('*') if p.is_file()})
(D/'RESULT.json').write_text(json.dumps(rec,indent=2))
with (D/'console.log').open('w') as f:
    p=subprocess.Popen(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(D/'run.tcl')],cwd=D,stdout=f,stderr=subprocess.STDOUT)
    rec['pid']=p.pid;(D/'RESULT.json').write_text(json.dumps(rec,indent=2));code=p.wait()
log=(D/'console.log').read_text(errors='replace');errors=re.findall(r'^ERROR.*',log,re.M)
report=(D/'impl/pnr/probe.rpt.txt').read_text(errors='replace') if (D/'impl/pnr/probe.rpt.txt').exists() else ''
actual={}
for name,loc in locs.items():
    m=re.search(r'^'+re.escape(name)+r'\s*\|\s*[^|]+\|\s*([^|]+)\|\s*([YN])\s*\|',report,re.M)
    actual[name]=dict(pin=m[1].strip().split('/')[0],constrained=m[2]=='Y') if m else None
pins_ok=all(v and v['pin']==locs[n].split(',')[0] and v['constrained'] for n,v in actual.items())
rec.update(status='PASS_DIAGNOSTIC_ONLY' if code==0 and not errors and pins_ok else 'FAILED_DIAGNOSTIC',returncode=code,errors=errors,
           actual_report_pins=actual,pins_verified=pins_ok,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
(D/'RESULT.json').write_text(json.dumps(rec,indent=2));print(json.dumps(rec,indent=2),flush=True)
