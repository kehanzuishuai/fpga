"""Cover the remaining advertised PCM modes, including 3-byte frame division."""
from run import ROOT,OUT,run,IVER,VVP
import re
cases=[('mono24_44100',24,1,44100,97),('mono24_48000',24,1,48000,97),('mono16_48000',16,1,48000,97),('stereo16_44100',16,2,44100,97),('stereo24_44100',24,2,44100,97)]
generator=ROOT/'tests/remote_music_20261019/make_fixtures.py'
s,n=re.subn(r'^for name,bits,channels,rate,n in .*:$','for name,bits,channels,rate,n in '+repr(cases)+':',generator.read_text(),count=1,flags=re.M)
assert n==1
# Only new fixture names are emitted; an ongoing original regression keeps its files.
exec(compile(s,str(generator),'exec'),{'__file__':str(generator)})
tb=(ROOT/'tests/remote_music_20261019/tb_wav.sv').read_text()
a=tb.index('  fixture_test("stereo24_48000",0);');b=tb.index('  $display("PASS WAV integration")',a)
tb=tb[:a]+''.join(f'  fixture_test("{c[0]}",{i});\n' for i,c in enumerate(cases))+tb[b:]
tb=tb.replace('PASS WAV integration','PASS remaining five WAV formats: all eight PCM width/channel/rate combinations covered')
(OUT/'tb_wav_formats.sv').write_text(tb)
run('wav_formats_compile',[IVER,'-g2012','-s','tb_wav','-o',OUT/'wav_formats.vvp',OUT/'tb_wav_formats.sv','src/remote/wav_spi_stream.sv','src/remote/wav_pcm_player.sv'])
run('wav_formats',[VVP,OUT/'wav_formats.vvp'])
