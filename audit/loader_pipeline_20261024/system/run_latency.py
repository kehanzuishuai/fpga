"""Keyboard -> dual DAC latency (tests/display_integration_20261021/keyboard_latency.py)
for a given branch: same testbench, models and Gowin primitives as the
original test, sources = the enabled files of the branch's GPRJ.
Usage: run_latency.py <branch dir> <label>
"""
from pathlib import Path
import hashlib, json, re, subprocess, sys
import xml.etree.ElementTree as ET
R = Path(r'D:\gaoyun\piano_v2_audio_fix')
B = Path(sys.argv[1]); label = sys.argv[2]
O = Path(__file__).resolve().parent / label
O.mkdir(parents=True, exist_ok=True)
IV = Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
excluded = {'audio_pll.v', 'audio_pll_mod.v', 'visual_video_clock.v', 'visual_dvi_io.v', 'visual_pll_mod.v', 'pll_init.v',
            'piano_level_rom.v', 'piano_ratio_rom.v', 'piano_note_rom.v', 'piano_sine_rom.v', 'piano_exp_rom.v'}
src = [B / e.attrib['path'] for e in ET.parse(B / 'yinyue_fashengqi.gprj').findall('./FileList/File')
       if e.attrib.get('enable') == '1' and Path(e.attrib['path']).suffix in ('.v', '.sv') and Path(e.attrib['path']).name not in excluded]
# The aux voices now contain Gowin memory primitives that read GSR.GSRO:
# wrap the testbench with the global set/reset cell, GSRI high (no reset).
rec_check = len(sys.argv) > 3 and sys.argv[3] == 'rec'
if rec_check:
    # v13: force the recorder on and count the physical-key events the synth accepts.
    (O / 'kl_root.sv').write_text('''module tb_kl_root;GSR GSR(.GSRI(1'b1));tb_keyboard_latency tb();
 integer accepted=0;
 // No delay: this wrapper has no timescale, a #delay here would be seconds.
 initial force tb.dut.u_remote.core.control.rec_enabled=1'b1;
 always @(posedge tb.dut.clk_12m288)if(tb.dut.u_remote.key_valid && tb.dut.u_remote.key_ready)accepted=accepted+1;
 final $display("REC accepted %0d wp %0d rp %0d overflow %0d",accepted,tb.dut.u_remote.core.control.rec_wp,tb.dut.u_remote.core.control.rec_rp,tb.dut.u_remote.core.control.rec_overflow);
endmodule
''')
else:
    (O / 'kl_root.sv').write_text('module tb_kl_root;GSR GSR(.GSRI(1\'b1));tb_keyboard_latency tb();endmodule\n')
files = [O / 'kl_root.sv', *src, R / 'tests/display_integration_20261021/tb_keyboard_latency.sv', R / 'sim/models/piano_roms_fast.v',
         R / 'sim/models/gowin_pll_stub.v', R / 'sim/models/ttp229_bfm.v', R / 'sim/models/i2s_rx_model.v',
         R / 'tests/display_upgrade_20261018/video_boundary_stub.v', Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')]
for name, args in (('compile', [IV, '-g2012', '-s', 'tb_kl_root', '-o', O / 'kl.vvp', *files]),
                   ('simulation', [IV.with_name('vvp.exe'), O / 'kl.vvp'])):
    with (O / (name + '.log')).open('w') as log:
        p = subprocess.run(list(map(str, args)), cwd=R, stdout=log, stderr=subprocess.STDOUT)
    if p.returncode:
        print(label, name, 'FAILED rc', p.returncode); sys.exit(1)
text = (O / 'simulation.log').read_text(errors='replace')
fields = 'case mask phase accepted_keys_ns first_event_ns first_pcm_ns first_pt8211_word_ns first_pcm5102_frame_ns last_individual_voice_ns'.split()
rows = [dict(zip(fields, [int(x, 16) if i == 1 else int(x) for i, x in enumerate(m.split(','))])) for m in re.findall(r'^RESULT,(.*)$', text, re.M)]
m = re.search(r'REC accepted (\d+) wp (\d+) rp (\d+) overflow (\d+)', text)
rec = {'label': label, 'branch': str(B), 'status': 'PASS' if 'PASS focused' in text else 'FAIL', 'rows': rows,
       'recorder': dict(zip(('accepted', 'wp', 'rp', 'overflow'), map(int, m.groups()))) if m else None,
       'loader_sha256': hashlib.sha256((B / 'src/piano_note_loader.v').read_bytes()).hexdigest()}
(O / 'LATENCY.json').write_text(json.dumps(rec, indent=1))
print(label, rec['status'], [(r['case'], round(r['first_pcm5102_frame_ns'] / 1e6, 3), round(r['last_individual_voice_ns'] / 1e6, 3)) for r in rows], 'recorder', rec['recorder'])
