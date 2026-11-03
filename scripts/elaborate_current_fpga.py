"""Elaborate the complete current top with the existing ROM/PLL/video test models."""
from pathlib import Path
import argparse
import os
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iverilog', default='iverilog')
    parser.add_argument('--prim-lib', type=Path, required=True, help='Gowin IDE/simlib/gw5a/prim_sim.v')
    args = parser.parse_args()
    excluded = {'audio_pll.v', 'audio_pll_mod.v', 'visual_video_clock.v', 'visual_dvi_io.v', 'visual_pll_mod.v',
                'visual_ref_pll_mod.v', 'pll_init.v', 'piano_level_rom.v', 'piano_ratio_rom.v', 'piano_note_rom.v',
                'piano_sine_rom.v', 'piano_exp_rom.v'}
    sources = [ROOT / item.get('path') for item in ET.parse(ROOT / 'yinyue_fashengqi.gprj').findall('.//File')
               if item.get('enable') == '1' and Path(item.get('path')).suffix in ('.v', '.sv')
               and Path(item.get('path')).name not in excluded]
    sources += [ROOT / 'tests/current/tb_top_elaboration.sv', ROOT / 'sim/models/piano_roms_fast.v', ROOT / 'sim/models/gowin_pll_stub.v',
                ROOT / 'tests/display_upgrade_20261018/video_boundary_stub.v', args.prim_lib]
    assert all(path.is_file() for path in sources), 'Missing elaboration input'
    output = ROOT / 'build/publication'
    output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, TEMP=str(output), TMP=str(output))
    command = [args.iverilog, '-g2012', '-s', 'tb_top_elaboration', '-o', str(output / 'top.vvp'), *map(str, sources)]
    result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True)
    (output / 'elaborate.txt').write_text(result.stdout + result.stderr, encoding='utf-8')
    if result.returncode:
        print((result.stdout + result.stderr)[-6000:])
        raise SystemExit(result.returncode)
    print(f'PASS complete FPGA top elaboration: {len(sources)} RTL/model inputs; vendor PLL/ROM/video boundaries replaced by test models')


if __name__ == '__main__':
    main()
