"""Short test only of the changed status CRC pipeline; no audio rerun."""
from run import ROOT,OUT,IVER,VVP,run
run('spi_timing_compile',[IVER,'-g2012','-s','tb_spi_timing','-o',OUT/'spi_timing.vvp','tests/remote_music_20261019/tb_spi_timing.sv','src/remote/wav_spi_stream.sv'])
run('spi_timing',[VVP,OUT/'spi_timing.vvp'],120)
