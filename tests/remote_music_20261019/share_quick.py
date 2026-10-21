"""Short diagnostic of reference/frame comparison; does not replace the long run."""
from pathlib import Path
p=Path(__file__).with_name('share_equiv.py');s=p.read_text()
s=s.replace('share_equiv','share_quick').replace('frames<512','frames<16').replace('frames<128','frames<4')
s=s.replace('module tb_share_quick;', '''module tb_share_quick;
initial begin $dumpfile("tests/remote_music_20261019/out/share_quick.vcd");$dumpvars(0,cycles,frames);end
''')
exec(compile(s,str(p),'exec'),{'__file__':str(__file__)})
