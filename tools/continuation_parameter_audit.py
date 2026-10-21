from pathlib import Path
import sys
from continue_audio_audit import R,O,A,IV,VV,PY,run
tb=(R/'tests/audio_diagnosis/tb_audio_loader.v').read_text().replace('tests/audio_diagnosis/loader_words.csv','tests/continuation_20261017/loader_words.csv')
(O/'tb_loader.v').write_text(tb,encoding='utf8')
commands=[('loader_compile',[IV,'-g2012','-s','tb_audio_loader','-o',O/'loader.vvp',O/'tb_loader.v','src/piano_note_loader.v','src/note_freq_table.v','src/piano_level_rom.v','src/piano_ratio_rom.v','src/piano_note_rom.v']),('loader',[VV,O/'loader.vvp'])]
for n,args in commands:
    if not run(n,args):sys.exit(1)
for script in ['audio_static_audit.py','audio_source_audit.py']:
    code="from pathlib import Path; p=Path('tools/"+script+"'); s=p.read_text().replace(\"O=R/'tests/audio_diagnosis'\",\"O=R/'tests/continuation_20261017'\"); exec(compile(s,str(p),'exec'),{'__file__':str(p.resolve()),'__name__':'__main__'})"
    if not run(script[:-3],[PY,'-X','utf8','-B','-c',code]):sys.exit(1)
