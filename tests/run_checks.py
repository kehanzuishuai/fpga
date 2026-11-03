"""Focused V14 checks. Every output stays inside this branch."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

B=Path(__file__).resolve().parents[1]
R=B.parents[1]
IV=R.parent/'piano_v2/codex_test/tools/iverilog/bin/iverilog.exe'
VV=IV.with_name('vvp.exe')
O=B/'tests/out';O.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()


def run(name,args,cwd=B,timeout=600):
    with (O/(name+'.log')).open('w',encoding='utf-8') as log:
        p=subprocess.run(list(map(str,args)),cwd=cwd,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
    text=(O/(name+'.log')).read_text(encoding='utf-8',errors='replace')
    assert p.returncode==0,(name,text[-4000:])
    print(name,text[-1100:] or 'PASS',flush=True)
    return text


def sim(name,files,top=None,timeout=600):
    target=O/(name+'.vvp')
    inputs={str(p):sha(p) for p in files}
    started=time.monotonic()
    receipt=O/(name+'.json')
    receipt.write_text(json.dumps(dict(status='RUNNING',inputs=inputs,programming=False),indent=2))
    try:
        run(name+'_compile',[IV,'-g2012','-s',top or name,'-o',target,*files])
        text=run(name,[VV,target],timeout=timeout)
        assert 'PASS' in text and 'ERROR:' not in text,text[-4000:]
        assert inputs=={str(p):sha(p) for p in files}
    except Exception as error:
        receipt.write_text(json.dumps(dict(status='FAILED',reason=str(error),inputs=inputs,programming=False),indent=2))
        raise
    receipt.write_text(json.dumps(dict(status='PASS',inputs=inputs,elapsed_seconds=time.monotonic()-started,programming=False),indent=2))


control_files=[B/'src/remote/live_remote_control.sv',B/'src/remote/wifi_core.sv',
 B/'src/remote/control/wifi_control.sv',B/'src/remote/control/wifi_score_player.sv',
 B/'src/display/visual_guide_controller.sv',B/'src/display/display_status_adapter.sv',
 B/'src/ttp229_event_bridge.v',*sorted((B/'src/remote/uart').glob('*.sv'))]


def mode_compatibility():
    s=(R/'tests/physical_keymap_20261024/tb_modes.sv').read_text()
    s=s.replace('remote_control #(','live_remote_control #(')
    s=s.replace('.clk(clk),.rst_n(rst_n),.sample_tick(1\'b1),.uart_rx',
                ".timbre_next(1'b0),.source_next(1'b0),.engine_clear_done(1'b1),\n  .clk(clk),.rst_n(rst_n),.sample_tick(1'b1),.uart_rx")
    s=s.replace('if(instrument!==0)$fatal(1,"physical piano was not restored");',
                'if(instrument!==3)$fatal(1,"selected live timbre was not retained");')
    s=s.replace('instrument!==0)', 'instrument!==(pass==0?3\'d0:3\'d3))')
    p=O/'tb_modes.sv';p.write_text(s)
    sim('mode_compatibility',[p,*control_files],top='tb_modes')


def full_sources():
    excluded={'audio_pll.v','audio_pll_mod.v','visual_video_clock.v','visual_dvi_io.v','visual_pll_mod.v',
              'visual_ref_pll_mod.v','pll_init.v','piano_level_rom.v','piano_ratio_rom.v','piano_note_rom.v',
              'piano_sine_rom.v','piano_exp_rom.v'}
    files=[B/e.get('path') for e in ET.parse(B/'yinyue_fashengqi.gprj').findall('./FileList/File')
           if e.get('enable')=='1' and Path(e.get('path')).suffix in ('.v','.sv') and Path(e.get('path')).name not in excluded]
    return files+[R/'sim/models/piano_roms_fast.v',R/'sim/models/gowin_pll_stub.v',
                  R/'tests/display_upgrade_20261018/video_boundary_stub.v',
                  Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')]


def source_protection():
    base=B.parent/'v17_full_build_20261031'
    receipt=json.loads((base/'audit/native_runs/clean_r1/RESULT.json').read_text())
    assert all(sha(base/n)==h for n,h in receipt['inputs'].items())
    print('PASS original V17 protected inputs unchanged',flush=True)


if __name__=='__main__':
    action=sys.argv[1]
    if action=='compat':mode_compatibility()
    elif action=='stream':sim('tb_stream_control',[B/'tests/tb_stream_control.sv',*control_files])
    elif action=='control':sim('tb_live_control',[B/'tests/tb_live_control.sv',*control_files])
    elif action=='adsr_screen':sim('tb_adsr_screen',[B/'tests/tb_adsr_screen.sv',*full_sources()],timeout=3600)
    elif action=='stream_system':sim('tb_stream_system',[B/'tests/tb_stream_system.sv',*full_sources(),R/'sim/models/i2s_rx_model.v'],timeout=1800)
    elif action=='system':sim('tb_live_system',[B/'tests/tb_live_system.sv',*full_sources(),R/'sim/models/i2s_rx_model.v'],timeout=3600)
    elif action=='audio':sim('tb_live_audio',[B/'tests/tb_live_audio.sv',B/'src/remote/live_instrument_master.sv'])
    source_protection()
