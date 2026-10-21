"""Isolated original-project regressions and reproducible resource inventory.
All writes remain under yinse/sim/audit; original sources are never edited.
"""
from pathlib import Path
import subprocess, os, json, hashlib, shutil, sys, collections, math
import xml.etree.ElementTree as ET
BASE=Path(__file__).resolve().parents[2]
OUT=BASE/'yinse/sim/audit'; OUT.mkdir(parents=True,exist_ok=True)
PY=sys.executable
YOSYS=Path(os.environ['APPDATA'])/'Python/Python313/Scripts/yowasp-yosys.exe'
ENV=dict(os.environ,LANG='C',LC_ALL='C',FPGA_IVERILOG=str(BASE/'bin/iverilog.exe'),FPGA_VVP=str(BASE/'bin/vvp.exe'))
ENV['PATH']=str(Path(PY).parent)+';C:/Strawberry/perl/bin;'+ENV.get('PATH','')
def run(name,args,cwd,timeout=3600):
    with (OUT/(name+'.log')).open('w',encoding='utf-8') as f:
        p=subprocess.run(list(map(str,args)),cwd=cwd,env=ENV,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
    print(name, 'PASS' if p.returncode==0 else 'FAIL',flush=True)
    return p.returncode
def snapshot():
    files=subprocess.check_output(['git','-c','safe.directory='+str(BASE),'ls-files'],cwd=BASE,text=True).splitlines()
    stage=OUT/'original';stage.mkdir(exist_ok=True)
    hashes={}
    for name in files:
        src=BASE/name;dst=stage/name;dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(src,dst);hashes[name]=hashlib.sha256(src.read_bytes()).hexdigest()
    for name in ['iverilog.exe','vvp.exe']:
        dst=stage/'bin'/name;dst.parent.mkdir(exist_ok=True);shutil.copyfile(BASE/'bin'/name,dst)
    # Icarus executable needs its original lib/ivl runtime; only staged runner changes.
    runner=stage/'scripts/run_regression.ps1'
    text=runner.read_text(encoding='utf-8-sig')
    text=text.replace("$iv = Join-Path $root 'bin\\iverilog.exe'", "$iv = '"+str(BASE/'bin/iverilog.exe')+"'")
    text=text.replace("$vv = Join-Path $root 'bin\\vvp.exe'", "$vv = '"+str(BASE/'bin/vvp.exe')+"'")
    runner.write_text(text,encoding='utf-8-sig')
    (OUT/'original_hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
    return stage
def original():
    stage=snapshot()
    result={}
    result['legacy_root']=run('legacy_root',['pwsh','-NoProfile','-ExecutionPolicy','Bypass','-File',stage/'scripts/run_regression.ps1'],stage)
    board=stage/'boards/tang_mega_138k_pro'
    result['board']=run('board',[PY,'-B',board/'scripts/run_regression.py'],board,7200)
    (OUT/'original_results.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
def resource():
    result={}
    aux=sorted((BASE/'yinse').rglob('*.sv'))
    aux=[p for p in aux if 'sim' not in p.relative_to(BASE/'yinse').parts]
    project=ET.parse(BASE/'yinyue_fashengqi.gprj')
    main=[BASE/f.attrib['path'] for f in project.findall('.//File') if f.attrib.get('enable')=='1' and f.attrib.get('type')=='file.verilog']
    visual_names=['visual_frame_store.v','visual_twiddle_rom.v','visual_fft.sv','visual_raster.v','visual_renderer.sv','visual_labels.sv','visual_tmds.sv','audio_visualizer.sv']
    visual=[BASE/'boards/tang_mega_138k_pro/src'/p for p in visual_names]
    cases=[('piano32',main,'synth_top',None),('visual',visual,'audio_visualizer',0),
           ('keyboard_reader',[BASE/'src/ttp229_reader.v'],'ttp229_reader',None),
           ('keyboard_bridge',[BASE/'src/ttp229_event_bridge.v'],'ttp229_event_bridge',None),
           ('controls',aux,'yinse_controls',0),('mux',aux,'yinse_audio_mux',0)]
    cases += [(f'aux{n}',aux,'yinse_aux_bank',n) for n in [1,4,8,16]]
    for name,files,top,n in cases:
        net=OUT/(name+'.json')
        read='read_verilog '+('-sv ' if n is not None else '')+' '.join(p.relative_to(BASE).as_posix() for p in files)
        cmd=read+'; hierarchy -check -top '+top
        if n:cmd+=' -chparam VOICES '+str(n)
        cmd+='; proc; opt; memory_dff; memory_collect; opt; wreduce; opt_clean; check -assert; stat; write_json '+net.relative_to(BASE).as_posix()
        code=run('resource_'+name,[YOSYS,'-Q','-T','-p',cmd],BASE,900)
        if code:result[name]={'status':'FAIL','log':'resource_'+name+'.log'};continue
        data=json.loads(net.read_text());counts=collections.Counter();mem=[];mul=[]
        def number(v):return int(v,2) if isinstance(v,str) else v
        def visit(module,path):
            for key,c in data['modules'][module].get('cells',{}).items():
                typ=c['type'];p=c.get('parameters',{});counts[typ]+=1
                if typ in data['modules']:visit(typ,path+'/'+key)
                if typ=='$mem_v2':
                    width,size=number(p['WIDTH']),number(p['SIZE'])
                    mem.append({'path':path+'/'+key,'width':width,'depth':size,'bits':width*size,'sync_reads':p.get('RD_CLK_ENABLE'),'write_ports':number(p['WR_PORTS'])})
                if typ=='$mul':
                    conn=c['connections'];a,b=conn['A'],conn['B']
                    const_a=all(isinstance(x,str) for x in a);const_b=all(isinstance(x,str) for x in b)
                    mul.append({'path':path+'/'+key,'a':len(a),'b':len(b),'y':len(conn['Y']),'constant':const_a or const_b,
                                'tiles18x18_unshared':0 if const_a or const_b else math.ceil(len(a)/18)*math.ceil(len(b)/18)})
        visit(top,top)
        result[name]={'status':'PASS_GENERIC_ONLY','cells':dict(counts),'memory_bits':sum(m['bits'] for m in mem),'memories':mem,'multipliers':mul,
                      'runtime_multipliers':sum(not m['constant'] for m in mul),'unshared18x18_tile_estimate':sum(m['tiles18x18_unshared'] for m in mul)}
    (OUT/'resource_inventory.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
def current():
    project=ET.parse(BASE/'yinyue_fashengqi.gprj')
    files=[BASE/f.attrib['path'] for f in project.findall('.//File') if f.attrib.get('enable')=='1' and f.attrib.get('type')=='file.verilog' and 'gowin_pll' not in f.attrib['path'] and 'tang_mega' not in f.attrib['path']]
    results={}
    for top,name in [('tb_current_piano_zero','current_piano_zero')]:
        image=OUT/(name+'.vvp')
        code=run(name+'_compile',[BASE/'bin/iverilog.exe','-g2005','-s',top,'-o',image,*files,BASE/'yinse/sim'/(top+'.v')],BASE)
        results[name]=code or run(name,[BASE/'bin/vvp.exe',image],BASE,2400)
    results['current_piano_native']=run('current_native_runner',[PY,'-B',BASE/'yinse/sim/run_current_native.py'],BASE,1200)
    verilator=Path(os.environ['APPDATA'])/'Python/Python313/Scripts/verilator-cli.exe'
    results['strict_lint']=run('current_piano_lint',[verilator,'--lint-only','--Wall','+1364-2005ext+v','--top-module','synth_top','--Mdir',OUT/'obj_current',*files],BASE)
    (OUT/'current_results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
if __name__=='__main__':
    if sys.argv[1]=='original':original()
    elif sys.argv[1]=='resource':resource()
    elif sys.argv[1]=='current':current()
