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
        'visual_renderer.sv','visual_labels.sv','visual_tmds.sv','audio_visualizer.sv']
sources=[ROOT/'src'/p for p in visual]
results=[]
def run(name,args,timeout=900):
    p=subprocess.run([str(a) for a in args],cwd=ROOT,env=env,text=True,
       stdout=subprocess.PIPE,stderr=subprocess.STDOUT,errors='replace',timeout=timeout)
    (OUT/(name+'.log')).write_text(p.stdout,encoding='utf-8')
    if p.returncode: raise RuntimeError(name+': '+p.stdout[-3000:])
    return p.stdout
def sim(name,extra=(),params=(),runtime=()):
    run(name+'_compile',[TC['iverilog'],'-g2012','-I',ROOT/'src','-s',name,*params,
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
    rom=(ROOT/'src/visual_twiddle_rom.v').read_text()
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
    tree=ET.parse(ROOT/'yinyue_fashengqi.gprj')
    all_board=[ROOT/f.attrib['path'] for f in tree.findall('.//File') if f.attrib.get('type')=='file.verilog']
    run('board_elaboration',[TC['iverilog'],'-g2012','-s','tang_mega_138k_pro_top',
         '-o',OUT/'board_elaboration.vvp',*all_board,ROOT/'sim/visual_primitive_stubs.v'])
    results.append('Actual board top port/hierarchy elaboration PASS (primitive interface stubs ONLY)')
    core=[ROOT/f.attrib['path'] for f in tree.findall('.//File') if f.attrib.get('type')=='file.verilog'
          and 'gowin_pll' not in f.attrib['path'] and Path(f.attrib['path']).name not in
          ('visual_video_clock.v','visual_dvi_io.v','pll_init.v','tang_mega_138k_pro_top.v.v')]
    extra=[p for p in core if p not in sources]
    sim('tb_visual_system',[*extra,ROOT/'sim/tmds_stream_checker.sv'],runtime=['+smoke'])
    sim('tb_visual_system',[*extra,ROOT/'sim/tmds_stream_checker.sv'])
    from PIL import Image
    Image.open(OUT/'rtl_display.ppm').save(OUT/'rtl_display.png')
    if Image.open(OUT/'rtl_display.ppm').tobytes()!=Image.open(OUT/'tmds_display.ppm').tobytes():
        raise RuntimeError('Four Voice final TMDS image differs from renderer')
    Image.open(OUT/'tmds_display.ppm').save(OUT/'tmds_display.png')
    sim('tb_visual_system',[*extra,ROOT/'sim/tmds_stream_checker.sv'],params=['-Ptb_visual_system.DIAGNOSTIC=1'])
    Image.open(OUT/'rtl_display_32.ppm').save(OUT/'rtl_display_32.png')
    if Image.open(OUT/'rtl_display_32.ppm').tobytes()!=Image.open(OUT/'tmds_display_32.ppm').tobytes():
        raise RuntimeError('32 Voice final TMDS image differs from renderer')
    Image.open(OUT/'tmds_display_32.ppm').save(OUT/'tmds_display_32.png')
    results.append('Final TMDS receiver recovers both640x480 RGB images bit-exact; blank/control/disparity/timing pipeline PASS (pre-OSER10)')
    pcm=np.loadtxt(OUT/'voice32_pcm.txt',dtype=np.int64)
    actual=np.loadtxt(OUT/'voice32_fft.txt',dtype=np.int64)
    frame_count=len(actual)//1024
    if frame_count<2 or len(actual)%1024:raise RuntimeError('Incomplete32 Voice FFT frames')
    for frame in range(frame_count):
        expected=fixed_fft(pcm[frame*2048:(frame+1)*2048],1,11)
        for k,exp in enumerate(expected):
            row=actual[frame*1024+k]
            if tuple(row[:2])!=(frame,k) or tuple(row[2:])!=exp:
                raise RuntimeError(f'Real32 Voice PCM->RTL FFT mismatch frame{frame} bin{k}')
    note_text=(ROOT/'src/test_mode.v').read_text()
    diagnostic_notes=[int(n) for n in re.findall(r"32'd\d+:midi_note=7'd(\d+);",note_text)]
    if len(diagnostic_notes)!=32 or len(set(diagnostic_notes))!=32:raise RuntimeError('Diagnostic note table')
    frequencies=[440*2**((n-69)/12) for n in diagnostic_notes]
    increments={int(n):int(v) for n,v in re.findall(r"7'd(\d+):\s*phase_inc_48k\s*=\s*32'd(\d+)",(ROOT/'src/note_freq_table.v').read_text())}
    dds_error=max(abs(increments[n]*48000/2**32-f) for n,f in zip(diagnostic_notes,frequencies))
    if min(np.diff(frequencies))<4*48000/2048:raise RuntimeError('Diagnostic notes too close')
    power=actual[1024:2048,4]
    real_peaks=[];errors=[]
    for frequency in frequencies:
        target=int(round(frequency*2048/48000))
        k=max(range(target-1,target+2),key=lambda j:power[j])
        if not(power[k]>power[k-1] and power[k]>power[k+1]):
            raise RuntimeError(f'Missing real Voice peak near{frequency:.3f}Hz')
        real_peaks.append(k);errors.append(abs(k*48000/2048-frequency))
    if len(set(real_peaks))!=32:raise RuntimeError('Non-independent real Voice peaks')
    display=(OUT/'voice32_display.txt').read_text().splitlines()
    peak_hz,sample_count,clips=map(int,display[0].split())
    if clips:raise RuntimeError('32 Voice diagnostic actual DAC PCM still clipped')
    dominant=int(np.argmax(power[1:]))+1
    if peak_hz!=(dominant*48000+1024)//2048:raise RuntimeError('Displayed peak readout mismatch')
    heights=[max(0,int(p).bit_length()-1)*6 for p in power]
    pooled=[max(heights[k:k+2]) for k in range(0,1024,2)]
    if list(map(int,display[1:]))!=pooled:raise RuntimeError('Displayed512 bars mismatch actual FFT')
    real_summary={'voices':32,'peaks':32,'bins':real_peaks,'midi_notes':diagnostic_notes,
                  'fft_max_grid_error_hz':max(errors),'peak_readout_hz':peak_hz,
                  'pcm_samples':sample_count,'clipping_ratio':clips/sample_count,
                  'dds_quantization_max_error_hz':dds_error,
                  'complex_power_bins_compared':frame_count*1024}
    (OUT/'voice32_verification.json').write_text(json.dumps(real_summary,indent=2))
    results.append(f'Real32 independent Voice->PCM->RTL FFT->512 displayed bars:32/32 peaks PASS; max FFT grid error{max(errors):.3f}Hz,clip ratio{clips/sample_count:.6%},dominant readout{peak_hz}Hz')
    results.append(f'Diagnostic DDS ROM quantization max error{dds_error:.9f}Hz (nominal48kHz; not analog measurement)')
    print(results[-1],flush=True)
    lint=run('verilator_visual',[TC['verilator'],'--lint-only','--Wall','--top-module','audio_visualizer',*sources])
    if '%Warning' in lint or '%Error' in lint:raise RuntimeError('Verilator warnings')
    results.append('audio_visualizer strict Verilator --Wall: 0 warnings PASS')
    diagnostic_lint=run('verilator_test_mode',[TC['verilator'],'--lint-only','--Wall',
                         '--top-module','test_mode',ROOT/'src/test_mode.v'])
    if '%Warning' in diagnostic_lint or '%Error' in diagnostic_lint:raise RuntimeError('Diagnostic table lint warnings')
    results.append('test_mode strict Verilator --Wall: 0 warnings PASS')
    command='read_verilog -sv -DSYNTHESIS '+' '.join('src/'+f for f in visual)+'; hierarchy -check -top audio_visualizer; proc; opt; memory_dff; memory_collect; opt_clean; check -assert; stat; log VISUAL_CHECK_COMPLETE'
    yosys=run('yosys_visual',[TC['yosys'],'-Q','-T','-p',command])
    if 'VISUAL_CHECK_COMPLETE\n' not in yosys or 'Found and reported 0 problems' not in yosys:
        raise RuntimeError('Yosys incomplete')
    if 'Warning:' in yosys or 'Replacing memory' in yosys:
        raise RuntimeError('Yosys warnings or unintended RAM expansion')
    results.append('Yosys RTL/memory synthesis and check -assert: 0 structural problems PASS (not Gowin mapping)')
    resources={key:int(re.findall(pattern,yosys)[-1]) for key,pattern in
               [('memory_cells',r'\n\s+(\d+)\s+\$mem_v2'),('generic_multipliers',r'\n\s+(\d+)\s+\$mul')]}
    results.append(f"Visual generic resources: {resources['memory_cells']} memory cells, {resources['generic_multipliers']} multiply cells; previous display-only baseline11/8, not device DSP/BRAM counts")
    report='# FPGA visualization verification\n\n'+'\n'.join('- '+r for r in results)
    report+='\n\nPython is ONLY a development oracle; hardware FFT runs from PCM in RTL.\nDefault 2048 points at48kHz:42.667ms observation,23.4375Hz bins.\nPhysical PLL lock, OSER10 timing, memory/DSP mapping, DVI monitor compatibility and flash boot are NOT verified.\n'
    (OUT/'verification_report.md').write_text(report,encoding='utf-8')
    (OUT/'verification.json').write_text(json.dumps({'results':results,'peaks':peak_counts,'real_voice32':real_summary,'resources':resources},indent=2))
    print('ALL VISUAL CHECKS PASS',flush=True)
except Exception as error:
    (OUT/'verification_report.md').write_text('# INCOMPLETE / FAILED\n\n'+'\n'.join(results)+'\n\n'+str(error),encoding='utf-8')
    print('FAIL',error,flush=True);sys.exit(1)
