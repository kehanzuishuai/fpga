from pathlib import Path
import sys, json, re, hashlib, importlib.util, concurrent.futures as cf, time
from continue_audio_audit import R,O,A,IV,VV,PY,run,sha,now

def notes():
    import audio_diagnose as d
    d.O=O/'notes';d.O.mkdir(exist_ok=True)
    def logged(args,log,timeout=7200):
        name='note_'+str(log.relative_to(d.O)).replace('\\','_').replace('/','_').replace('.log','')
        if not run(name,args,timeout):raise RuntimeError(name+' failed')
        text=(O/(name+'.log')).read_text(encoding='utf8')
        log.parent.mkdir(parents=True,exist_ok=True);log.write_text(text,encoding='utf8')
        return text
    d.run=logged
    logged([IV,'-g2012','-s','tb_piano_voice','-o',d.O/'voice.vvp','sim/tb/tb_piano_voice.v','src/piano_partial_voice.v','src/piano_note_loader.v','src/note_freq_table.v','sim/models/piano_roms_fast.v'],d.O/'voice_compile.log')
    logged([IV,'-g2005','-s','tb_audio_fx','-o',d.O/'fx.vvp','tests/audio_diagnosis/tb_audio_fx.v','src/piano_fx.v'],d.O/'fx_compile.log')
    results=[];failed=[]
    with cf.ThreadPoolExecutor(max_workers=4) as ex:
        jobs={ex.submit(d.voice,n):n for n in d.NOTES}
        for f in cf.as_completed(jobs):
            try:results.append(f.result())
            except Exception as e:failed.append({'note':jobs[f],'error':str(e)})
    (d.O/'RESULTS.json').write_text(json.dumps({'status':'PASS' if not failed else 'FAIL','results':results,'failures':failed},indent=2),encoding='utf8')
    return not failed

def syntax():
    import xml.etree.ElementTree as ET
    src=[R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1' and Path(e.attrib['path']).suffix in ['.v','.sv']]
    return run('hardware_syntax',[IV,'-g2012','-tnull','-s','tb_hardware_elaboration','tests/integration/tb_hardware_elaboration.sv',*src,r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\simlib\gw5a\prim_sim.v'])

def dvi_reset():
    if not run('dvi_local_reset_compile',[IV,'-g2012','-s','tb_dvi_local_reset','-o',O/'dvi_reset.vvp','tests/continuation_20261017/tb_dvi_local_reset.sv','src/display/visual_dvi_io.v']):return False
    if not run('dvi_local_reset',[VV,O/'dvi_reset.vvp']):return False
    return syntax()

def dvi_vendor():
    text=(A/'backup/src/display/visual_dvi_io.v').read_text().replace('module visual_dvi_io','module baseline_visual_dvi_io')
    ref=O/'baseline_visual_dvi_io.v';ref.write_text(text,encoding='utf8')
    if not run('dvi_vendor_compile',[IV,'-g2012','-s','tb_dvi_vendor','-o',O/'dvi_vendor.vvp','tests/continuation_20261017/tb_dvi_vendor.sv','src/display/visual_dvi_io.v',ref,r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\simlib\gw5a\prim_sim.v']):return False
    return run('dvi_vendor',[VV,O/'dvi_vendor.vvp'])

def build():
    import xml.etree.ElementTree as ET
    inp={str(R/e.attrib['path']):sha(R/e.attrib['path']) for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1'}
    for rel in ['src/piano_fx.v','yinyue_fashengqi.gprj','tools/build_gowin.tcl','impl/yinyue_fashengqi_process_config.json']:
        inp[str(R/rel)]=sha(R/rel)
    started=time.time()
    (A/'BUILD.json').write_text(json.dumps({'status':'RUNNING','started':now(),'input_sha256':inp},indent=2),encoding='utf8')
    good=run('gowin',[r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe',R/'tools/build_gowin.tcl'])
    fs=R/'impl/pnr/ao_0.fs'; tr=R/'impl/pnr/yinyue_fashengqi.tr'
    text=tr.read_text(errors='replace') if tr.exists() else ''
    fresh=fs.exists() and fs.stat().st_mtime>=started
    same=all(sha(Path(p))==h for p,h in inp.items())
    timing=all(f'<Numbers of {t} Violated Endpoints>:0' in text for t in ['Setup','Hold'])
    result={'status':'PASS' if good and fresh and same and timing else 'FAIL','finished':now(),'input_sha256':inp,'inputs_unchanged':same,'fresh_bitstream':fresh,'timing_zero_violations':timing,'fs':str(fs),'sha256':sha(fs) if fs.exists() else None,'note':'Implementation validation only; physical key order and analog output still unverified'}
    (A/'BUILD.json').write_text(json.dumps(result,indent=2),encoding='utf8')
    print(json.dumps(result,indent=2));return result['status']=='PASS'

def manual():
    from pypdf import PdfReader
    doc=Path(r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\doc\EN\SUG1220-1.0E_Gowin Software Tcl Commands User Guide.pdf')
    reader=PdfReader(doc);parts=[]
    for i,p in enumerate(reader.pages):
        t=p.extract_text() or ''
        if any(word in t for word in ['save_project','get_option','set_option','write_project','process_config']):parts.append(f'PAGE {i+1}\n{t}')
    (A/'gowin_tcl_manual.txt').write_text('\n\n'.join(parts),encoding='utf8')
    print('Extracted',len(parts),'relevant pages from',doc)
    return True

if __name__=='__main__':sys.exit(not globals()[sys.argv[1]]())
