Excerpt of https://github.com/shorepine/amy (MIT licence, see LICENSE)
commit 69a146930cbf2c52abb5ad92c26d2157f9095a6d (2026-10-08, version 1.2.192)

Only the files the piano port refers to are kept here:
  src/interp_partials.c/.h   piano note-on interpolation + the partial table (patch 256 "dpwe piano")
  src/envelope.c             breakpoint envelope evaluation
  src/oscillators.c          render_partial / render_lut_256
  src/delay.c/.h, filters.c  reverb, chorus, echo, EQ
  amy/piano.py, piano_params.py, experiments/*   Python version and the analysis notebook
  docs/piano.html            the write-up of the method
