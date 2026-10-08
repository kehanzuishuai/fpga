# FPGA visualization verification

- 4096 Q1.15 coefficient pairs match analytic reference PASS
- tb_visual_cdc: PASS
- tb_visual_video: PASS
- tb_visual_reset: PASS
- tb_visual_fft: PASS
- N=1024, window=0: 2048 complex/power bins bit-exact, 32/32 actual FFT peaks PASS
- tb_visual_fft: PASS
- N=2048, window=1: 4096 complex/power bins bit-exact, 32/32 actual FFT peaks PASS
- tb_visual_fft: PASS
- N=4096, window=1: 8192 complex/power bins bit-exact, 32/32 actual FFT peaks PASS
- Actual board top port/hierarchy elaboration PASS (primitive interface stubs ONLY)
- tb_visual_system: PASS
- audio_visualizer strict Verilator --Wall: 0 warnings PASS
- Yosys RTL/memory synthesis and check -assert: 0 structural problems PASS (not Gowin mapping)

Python is ONLY a development oracle; hardware FFT runs from PCM in RTL.
Default 2048 points at48kHz:42.667ms observation,23.4375Hz bins.
Physical PLL lock, OSER10 timing, memory/DSP mapping, DVI monitor compatibility and flash boot are NOT verified.
