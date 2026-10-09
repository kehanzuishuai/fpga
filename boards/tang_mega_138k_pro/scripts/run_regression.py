"""Unified source regression; all failures return nonzero and produce a report."""
from pathlib import Path
import sys,subprocess,json,argparse,importlib.util,traceback,hashlib
from datetime import datetime,timezone
from toolchain import discover,environment,ROOT

def source_hashes():
    return {str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
        for folder in ('src','sim','scripts') for p in sorted((ROOT/folder).rglob('*'))
        if p.is_file() and '__pycache__' not in p.parts}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check-tools',action='store_true')
    args=parser.parse_args()
    out=ROOT/'sim_out_visual';out.mkdir(exist_ok=True)
    report={'status':'RUNNING','mode':'preflight' if args.check_tools else 'full','suites':{},'physical_validation':False,
            'started_utc':datetime.now(timezone.utc).isoformat()}
    name='tools_summary.json' if args.check_tools else 'regression_summary.json'
    report['source_sha256']=source_hashes()
    (out/name).write_text(json.dumps(report,indent=2),encoding='utf-8')
    try:
        missing=[p for p in ('numpy','PIL') if importlib.util.find_spec(p) is None]
        if missing:raise RuntimeError('Missing packages: '+','.join(missing)+'. Run python -m pip install -r scripts/requirements.txt')
        report['tools']={k:str(v) for k,v in discover().items()};report['python']=sys.executable
        print(json.dumps(report['tools'],indent=2),flush=True)
        if not args.check_tools:
            for script in ('test_toolchain.py','verify_adc.py','verify_audio_quality.py','verify_visual.py','verify_pcm5102a.py'):
                p=subprocess.run([sys.executable,str(Path(__file__).parent/script)],cwd=ROOT,env=environment())
                report['suites'][script]='PASS' if p.returncode==0 else 'FAIL'
                if p.returncode:raise RuntimeError(script+' failed')
        if source_hashes()!=report['source_sha256']:
            raise RuntimeError('Sources changed during regression; rerun from frozen sources')
        report['status']='PASS'
    except Exception as exc:
        report['status']='FAIL';report['error']=str(exc);print('FAIL:',exc,flush=True);traceback.print_exc()
    report['finished_utc']=datetime.now(timezone.utc).isoformat()
    (out/name).write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('ALL REQUESTED CHECKS '+report['status'],flush=True)
    return 0 if report['status']=='PASS' else 1
if __name__=='__main__':sys.exit(main())
