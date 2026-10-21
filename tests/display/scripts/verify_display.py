"""Development-only golden model. Not part of bitstream or offline operation."""
from pathlib import Path
from toolchain import discover, environment
import os,sys,subprocess,math,json,re,xml.etree.ElementTree as ET
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sim_out_visual'; OUT.mkdir(exist_ok=True)
(OUT/'verification_report.md').write_text('# RUNNING / INCOMPLETE\n',encoding='utf-8')
TC=discover()
env=environment()
visual=['visual_frame_store.v','visual_twiddle_rom.v','visual_fft.sv','visual_raster.v',
        'visual_renderer.sv','visual_labels.sv','visual_tmds.sv','audio_visualizer.sv',
        'piano_status_cdc.v','piano_status_overlay.sv','yinse_display_info.sv']
sources=[ROOT.parents[1]/'src/display'/p for p in visual]
results=[]
def run(name,args,timeout=900):
    p=subprocess.run([str(a) for a in args],cwd=ROOT,env=env,text=True,
       stdout=subprocess.PIPE,stderr=subprocess.STDOUT,errors='replace',timeout=timeout)
    (OUT/(name+'.log')).write_text(p.stdout,encoding='utf-8')
    if p.returncode: raise RuntimeError(name+': '+p.stdout[-3000:])
    return p.stdout
def sim(name,extra=(),params=(),runtime=()):
    run(name+'_compile',[TC['iverilog'],'-g2012','-I',ROOT.parents[1]/'src/display','-s',name,*params,
        '-o',OUT/(name+'.vvp'),*sources,*extra,ROOT/'sim'/(name+'.sv')])
    output=run(name,[TC['vvp'],OUT/(name+'.vvp'),*runtime])
    if 'PASS' not in output or 'FATAL' in output or 'WARNING:' in output:raise RuntimeError(name+': '+output)
    print(output,flush=True);results.append(name+': PASS')
def fixed_fft(x,window,logn):
    n=len(x)
    c=[math.floor(32767*math.cos(2*math.pi*k/4096)+.5) for k in range(4096)]
    s=[math.floor(-32767*math.sin(2*math.pi*k/4096)+.5) for k in range(4096)]
    r=[0]*n;im=[0]*n
    for k,v in enumerate(x):
        rev=int(f'{k:0{logn}b}'[::-1],2)
        r[rev]=(int(v)*((32767-c[k<<(12-logn)])>>1))>>15 if window else int(v)
    h=1
    for stage in range(1,logn+1):
        for base in range(0,n,2*h):
            for j in range(h):
                a=base+j;b=a+h;t=j<<(12-stage)
                tr=r[b]*c[t]-im[b]*s[t];ti=r[b]*s[t]+im[b]*c[t]
                ar=r[a]*32768;ai=im[a]*32768
                r[a]=(ar+tr)>>16;im[a]=(ai+ti)>>16
                r[b]=(ar-tr)>>16;im[b]=(ai-ti)>>16
        h*=2
    return [(r[k],im[k],r[k]**2+im[k]**2) for k in range(n//2)]
try:
    rom=(ROOT.parents[1]/'src/display/visual_twiddle_rom.v').read_text()
    coeffs=re.findall(r"rom\[(\d+)\]=32'h([0-9a-f]{4})([0-9a-f]{4});",rom)
    if len(coeffs)!=4096:raise RuntimeError('coefficient ROM incomplete')
    for k,c,s in coeffs:
        angle=2*math.pi*int(k)/4096
        if int(c,16)!=(math.floor(32767*math.cos(angle)+.5)&65535) or int(s,16)!=(math.floor(-32767*math.sin(angle)+.5)&65535):
            raise RuntimeError('coefficient ROM mismatch')
    results.append('4096 Q1.15 coefficient pairs match analytic reference PASS')
    sim('tb_visual_cdc');sim('tb_visual_video');sim('tb_visual_reset');sim('tb_visual_readout')
    sim('tb_tmds_receiver',[ROOT/'sim/tmds_stream_checker.sv'])
    peak_counts={}
    for logn,window in [(10,0),(11,1),(12,1)]:
        n=1<<logn;t=np.arange(n)
        bins=list(range(8,8+32*6,6))
        rng=np.random.default_rng(26)
        vectors=[np.zeros(n,dtype=int),np.rint(26000*np.sin(2*np.pi*37*t/n)).astype(int),
          np.rint(sum(700*np.sin(2*np.pi*k*t/n) for k in bins)).astype(int),
          rng.choice([-32768,-20000,-1,0,1,20000,32767],n)]
        (OUT/'fft_input.hex').write_text(''.join(f'{int(v)&65535:04x}\n' for a in vectors for v in a),encoding='ascii')
        sim('tb_visual_fft',params=[f'-Ptb_visual_fft.LOGN={logn}',f'-Ptb_visual_fft.WINDOW={window}'])
        rows=[list(map(int,line.split())) for line in (OUT/'fft_rtl.txt').read_text().splitlines()]
        if len(rows)!=4*n//2:raise RuntimeError('FFT incomplete output')
        for frame,a in enumerate(vectors):
            expected=fixed_fft(a,window,logn)
            for k,exp in enumerate(expected):
                row=rows[frame*n//2+k]
                if row[:2]!=[frame,k] or tuple(row[2:])!=exp:
                    raise RuntimeError(f'bit-exact mismatch N={n} frame={frame} bin={k}: {row} != {exp}')
        power=np.array([row[4] for row in rows[n:3*n//2]],dtype=float)
        detected=int(sum(power[k]>power[k-1] and power[k]>power[k+1] for k in bins))
        if detected!=32:raise RuntimeError(f'{n}: only {detected}/32 peaks')
        peak_counts[n]=detected
        results.append(f'N={n}, window={window}: {4*n//2} complex/power bins bit-exact, 32/32 actual FFT peaks PASS')
        print(results[-1],flush=True)
        (OUT/f'fft_rtl_{n}.txt').write_text((OUT/'fft_rtl.txt').read_text())
    report = '# Display-only package verification\n\n' + '\n'.join('- '+r for r in results)
    report += '\n\nScope: portable RTL simulation only. No piano_v2 integration, Gowin implementation, PLL/OSER10 or physical monitor validation.\n'
    (OUT/'verification_report.md').write_text(report, encoding='utf-8')
    print('ALL DISPLAY-ONLY CHECKS PASS', flush=True)
except Exception as error:
    (OUT/'verification_report.md').write_text('# FAILED / INCOMPLETE\n\n'+'\n'.join(results)+'\n\n'+str(error), encoding='utf-8')
    print('FAIL', error, flush=True)
    sys.exit(1)

