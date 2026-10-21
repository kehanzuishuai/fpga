"""Apply the timing-checked small clock probe to the real display boundary."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[2]
P=Path(__file__).resolve().parent/'clock_probes/half_fine_trim'
for src,dst in [('probe_dvi.v','src/display/visual_dvi_io.v'),('visual_video_clock.v','src/display/visual_video_clock.v'),('visual_pll_mod.v','src/display/gowin_pll/visual_pll_mod.v')]:
    shutil.copy2(P/src,R/dst)
p=R/'src/display/visual_dvi_io.v'
s=p.read_text().replace('// reset registers and the hard IOLOGIC clock have bounded insertion skew.','// the hard IOLOGIC clock has controlled insertion delay. Fabric reset logic\n // uses the separate185.625MHz clock, avoiding371.25MHz fabric pulse limits.')
a=s.index(' // Five shared settling');b=s.index(' (* async_reg=',a)
s=s[:a]+''' // Six release stages on the dedicated185.625MHz PLL output. Its phase
 // and duty trim are represented explicitly in integrated.sdc. Local stage
 // placement bounds reset skew; OSER10 recovery/removal remain timed.
'''+s[b:]
s=s.replace('// Assert asynchronously; release all channels on the same falling edge.','// Assert asynchronously; release all channels on the same reset-clock edge.')
p.write_text(s)
p=R/'src/tang_mega_138k_pro_top.v.v';s=p.read_text()
s=s.replace('wire pixel_clk,serial_clk,video_locked;','wire pixel_clk,serial_clk,video_locked,serial_reset_clk;')
s=s.replace('visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked);','visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked,serial_reset_clk);')
s=s.replace(' video_d_p,video_d_n,video_ck_p,video_ck_n);',' video_d_p,video_d_n,video_ck_p,video_ck_n,serial_reset_clk);')
p.write_text(s)
p=R/'src/integrated.sdc';s=p.read_text()
lines=[q for q in (P/'probe.sdc').read_text().splitlines() if q.startswith('create_generated_clock -name video_serial_reset')]
assert len(lines)==2
s=s.replace('# All audio/pixel crossings','\n'.join(lines)+'\n# All audio/pixel crossings')
s=s.replace('{video_ref video_pixel video_serial video_serial_global}','{video_ref video_pixel video_serial video_serial_global video_serial_reset video_serial_reset_global}')
p.write_text(s)
p=R/'src/integrated.cst';s=p.read_text()
locations=[q for q in (P/'probe.cst').read_text().splitlines() if q.startswith('INS_LOC')]
assert len(locations)==3
p.write_text(s+'\n// Local serializer reset registers: preserve measured recovery/removal skew.\n'+'\n'.join(locations)+'\n')
print('Applied185.625MHz reset clock, explicit waveform and3 internal placements; IO definitions preserved.')
