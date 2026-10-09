"""Standalone MCP3208 acquisition checks; never edits pins or existing audio RTL."""
from pathlib import Path
import json,subprocess,sys,hashlib
from datetime import datetime,timezone
from toolchain import ROOT,discover,environment

OUT=ROOT/'sim_out_adc';OUT.mkdir(exist_ok=True)
SOURCES=[ROOT/'src'/n for n in ('mcp3208_dual_reader.sv','hall_scan_store.sv','hall_adc_scan.sv')]
TESTS=[ROOT/'sim'/n for n in ('mcp3208_model.sv','tb_mcp3208_dual_reader.sv','tb_hall_adc_scan.sv','tb_hall_scan_store.sv')]
report={'status':'RUNNING','physical_validation':False,'started_utc':datetime.now(timezone.utc).isoformat(),'results':[]}
report['source_sha256']={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCES+TESTS+[Path(__file__)]}
(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

def run(name,args):
    p=subprocess.run([str(a) for a in args],cwd=ROOT,env=environment(),capture_output=True,text=True,errors='replace',timeout=180)
    output=p.stdout+p.stderr;(OUT/(name+'.log')).write_text(output,encoding='utf-8')
    if p.returncode:raise RuntimeError(name+': '+output[-4000:])
    return output

def main():
    tc=discover()
    for stale in (1,17,257):
        label=f'store_stale_{stale}';image=OUT/(label+'.vvp')
        run(label+'_compile',[tc['iverilog'],'-g2012','-s','tb_hall_scan_store',f'-Ptb_hall_scan_store.STALE_CYCLES={stale}','-o',image,*SOURCES,*TESTS])
        output=run(label,[tc['vvp'],image])
        if 'PASS' not in output or 'WARNING:' in output or 'FATAL' in output:raise RuntimeError(output)
        report['results'].append(output.strip());print(output,flush=True)
    for clk,spi,channels,rate in ((50000000,1000000,8,2000),(12288000,1000000,8,2000),(27000000,750000,3,1800),(50000000,500000,1,2000)):
        params={'CLK_HZ':clk,'SPI_HZ':spi}
        for top in ('tb_mcp3208_dual_reader','tb_hall_adc_scan'):
            label=f'{top}_{clk}_{spi}_{channels}'
            values=params if top.endswith('dual_reader') else dict(params,CHANNELS=channels,KEY_RATE_HZ=rate)
            image=OUT/(label+'.vvp')
            compilation=run(label+'_compile',[tc['iverilog'],'-g2012','-s',top,*[f'-P{top}.{k}={v}' for k,v in values.items()],'-o',image,*SOURCES,*TESTS])
            if 'warning' in compilation.lower():raise RuntimeError(compilation)
            output=run(label,[tc['vvp'],image])
            if 'PASS' not in output or 'WARNING:' in output or 'FATAL' in output:raise RuntimeError(output)
            report['results'].append(output.strip());print(output,flush=True)
        lint=run(f'verilator_adc_{clk}_{spi}_{channels}',[tc['verilator'],'--lint-only','--Wall','--top-module','hall_adc_scan',
            *[f'-G{k}={v}' for k,v in dict(params,CHANNELS=channels,KEY_RATE_HZ=rate).items()],*SOURCES])
        if '%Warning' in lint or '%Error' in lint:raise RuntimeError(lint)
    report['results'].append('Strict Verilator --Wall all4 configurations:0 warnings PASS')
    for label,top,params,reason in (
        ('reject_fast_scan','tb_hall_adc_scan',{'KEY_RATE_HZ':100000},'cadence cannot fit'),
        ('reject_spi2mhz','tb_mcp3208_dual_reader',{'SPI_HZ':2000000},'conservative2.7..3.3V profile'),
        ('reject_sync_margin','tb_mcp3208_dual_reader',{'CLK_HZ':2000000},'divider lacks')):
        image=OUT/(label+'.vvp')
        run(label+'_compile',[tc['iverilog'],'-g2012','-s',top,*[f'-P{top}.{k}={v}' for k,v in params.items()],'-o',image,*SOURCES,*TESTS])
        p=subprocess.run([str(tc['vvp']),str(image)],cwd=ROOT,env=environment(),capture_output=True,text=True,timeout=10)
        output=p.stdout+p.stderr;(OUT/(label+'.log')).write_text(output,encoding='utf-8')
        # The bundled old vvp returns0 even for $fatal: require the exact guard,
        # at time0, with no PASS; all positive tests reject any FATAL regardless exit.
        if 'FATAL:' not in output or reason not in output or 'Time: 0' not in output or 'PASS' in output:
            raise RuntimeError('Invalid ADC configuration was not rejected: '+label)
        report['results'].append(label+': expected parameter rejection PASS')
    for top in ('mcp3208_dual_reader','hall_scan_store','hall_adc_scan'):
        command='read_verilog -sv -DSYNTHESIS '+' '.join(str(p.relative_to(ROOT)).replace('\\','/') for p in SOURCES)+f'; hierarchy -check -top {top}; proc; opt; check -assert; stat; log ADC_CHECK_COMPLETE'
        output=run('yosys_'+top,[tc['yosys'],'-Q','-T','-p',command])
        if 'Found and reported 0 problems' not in output or 'ADC_CHECK_COMPLETE\n' not in output:raise RuntimeError(output)
        if 'Warning:' in output or '$div' in output or '$mod' in output or '$dlatch' in output:raise RuntimeError('ADC unexpected warning/divider/latch: '+output[-4000:])
    report['results'].append('Yosys all3 modules:0 problems,no runtime div/mod/latches PASS')
    for relative,expected in report['source_sha256'].items():
        if hashlib.sha256((ROOT/relative).read_bytes()).hexdigest()!=expected:raise RuntimeError('Source changed during ADC tests')
    report['nominal_default']={'input_clock_hz':50000000,'spi_clock_hz':1000000,'pair_period_cycles':3125,'key_update_period_us':500,'keys':16}
    report['scope']='Standalone raw acquisition; not wired to board top or audio, no GPIO/PLL changes; stale is data age not reliable ADC presence detection'
    report['status']='PASS'

try:main()
except Exception as exc:report['status']='FAIL';report['error']=str(exc);print('FAIL',exc,flush=True)
report['finished_utc']=datetime.now(timezone.utc).isoformat()
(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(OUT/'verification_report.md').write_text('# MCP3208 acquisition '+report['status']+'\n\n'+'\n'.join('- '+r for r in report['results'])+'\n\n'+report.get('error',report.get('scope','')),encoding='utf-8')
print('ALL ADC CHECKS '+report['status'],flush=True)
sys.exit(0 if report['status']=='PASS' else 1)
