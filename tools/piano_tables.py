"""Fixed-point tables of the FPGA piano engine, derived from the AMY table.

Used by gen_piano_rom.py (writes the Verilog ROMs) and by fpga_piano_model.py
(the bit-exact integer model of the RTL), so both always see the same numbers.

Number formats (all unsigned unless stated)
-------------------------------------------
level  L   attenuation in units of 6.0206 dB below amplitude 16.0
           amplitude = 16.0 * 2^-L          (AMY: 100 dB = amplitude 1.0)
           ROM: Q4.8  (12 bit, 0xFFF = "partial does not exist")
           voice accumulator: Q4.22 (26 bit)
ratio      partial frequency / equal-tempered note frequency, Q5.15 (20 bit)
phase      28 bit, one cycle = 2^28
sine ROM   quarter wave, 512 entries: 17 bit magnitude + 9 bit step to the
           next entry (linear interpolation with 10 fraction bits)
exp ROM    1024 entries of 2^-(i/1024), Q0.18
amplitude  24 bit, full scale = 16.0
"""
import numpy as np

import pianolib as pl

# ----------------------------------------------------------------------------
# Engine constants (mirrored by localparams in piano_partial_voice.v /
# piano_note_loader.v; the bit-exact test tb_piano_voice checks they agree)
# ----------------------------------------------------------------------------
SLOTS = 16                  # 15 sine partials + 1 hammer noise slot
PARTIALS = SLOTS - 1
HAMMER_SLOT = SLOTS - 1
NUM_BP = 21                 # 20 AMY breakpoints + 1 tail point
GRID_NOTES = 21             # MIDI 24, 28, ... 104
VEL_LAYERS = 3              # MIDI velocity 40, 80, 120

L_FRAC_ROM = 8
L_FRAC = 22
L_MISSING = 0xFFF
L_MAX_ROM = 0xFFE
L_INIT = 13 << L_FRAC       # start of the attack: just below audibility
L_TOP = (1 << 26) - 1

AMP_FS = 16.0               # amplitude that corresponds to L = 0
DB_OF_L0 = 100.0 + 20.0 * np.log10(AMP_FS)          # 124.082 dB
DB_PER_L = 20.0 * np.log10(2.0)                     # 6.0206 dB

AMP_OFFSET = int(round(0.001 / AMP_FS * (1 << 24)))  # AMY: lin = 10^(dB/20) - 0.001
AMP_GATE = int(0.0011 / AMP_FS * (1 << 24))          # AMY: amp <= 0.0011 -> 0

SEG_SHIFT = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 8]
SEG_BASE_LEN = 192          # 4 ms at 48 kHz; segment length = 192 << SEG_SHIFT
K3 = 87381                  # round(2^18 / 3)

RATIO_FRAC = 15
PHASE_BITS = 28

FADE_SLOPE = 1 << 20        # steal fade: 16 units in 64 samples
EXTRA_ATT_PER_VEL = 26      # Q4.8 per velocity step below 40 (0.61 dB)

# Hammer slot (engineering model, not AMY data)
HAMMER_REL_DB = -13.0       # hammer amplitude parameter relative to the loudest partial
HAMMER_SHAPE_DB = [-6, 0, -1, -2, -4, -6, -9, -11, -15, -19, -26, -32, -45, -70, -90,
                   -90, -90, -90, -90, -90]
TAIL_MIN_DB_PER_S = 4.0
MAX_PARTIAL_HZ = 20000.0
FREQ_RELIABLE_DB = 55.0


def db_to_l_rom(db):
    """dB (AMY scale) -> Q4.8 level code."""
    l = (DB_OF_L0 - min(float(db), 120.0)) / DB_PER_L
    return int(min(L_MAX_ROM, max(0, round(l * (1 << L_FRAC_ROM)))))


def _clean_ratios():
    """One frequency ratio per (grid note, partial).

    AMY stores a measured frequency for every harmonic of every note/velocity.
    Weak harmonics have unreliable frequencies (the fundamental of C1 is 2
    semitones off at mf), so per note the ratio is taken from the loudest
    velocity layer when that harmonic is strong, otherwise from a fit of the
    inharmonicity model  cents_k = c0 + 1200*log2(k*sqrt(1 + B k^2)).
    """
    p = pl.load_params()
    ratios = np.zeros((GRID_NOTES, SLOTS))
    info = []
    for j, note in enumerate(p["notes"]):
        rows = [pl.note_vel_rows(j, l) for l in range(VEL_LAYERS)]
        n = min(PARTIALS, max(len(r[0]) for r in rows))
        k = np.arange(1, n + 1)
        dev = np.full((VEL_LAYERS, n), np.nan)
        lev = np.full((VEL_LAYERS, n), -1.0)
        for l, (c, m) in enumerate(rows):
            nn = min(n, len(c))
            dev[l, :nn] = c[:nn] - 100.0 * note - 1200.0 * np.log2(k[:nn])
            lev[l, :nn] = m[:nn].max(axis=1)
        best = np.argmax(lev, axis=0)
        d = dev[best, np.arange(n)]
        lv = lev[best, np.arange(n)]
        good = lv >= FREQ_RELIABLE_DB
        # robust fit of c0 + g*k^2 (first-order inharmonicity) on the reliable partials
        c0, g = 0.0, 0.0
        for _ in range(4):
            if good.sum() >= 2:
                a = np.stack([np.ones(good.sum()), k[good] ** 2.0], axis=1)
                c0, g = np.linalg.lstsq(a, d[good], rcond=None)[0]
            elif good.sum() == 1:
                c0, g = d[good][0], 0.0
            fit = c0 + g * k ** 2.0
            res = np.abs(d - fit)
            new_good = good & (res <= 25.0)
            if new_good.sum() == good.sum():
                break
            good = new_good
        fit = c0 + max(g, 0.0) * k ** 2.0
        use = np.where(good, d, fit)
        ratios[j, :n] = k * 2.0 ** (use / 1200.0)
        info.append((note, n, int(good.sum()), c0, g))
    return ratios, info


def build():
    """Returns a dict with all integer tables."""
    p = pl.load_params()
    notes = p["notes"]
    ratios_f, ratio_info = _clean_ratios()

    level = np.full((GRID_NOTES, VEL_LAYERS, SLOTS, NUM_BP), L_MISSING, dtype=np.int64)
    ratio = np.zeros((GRID_NOTES, SLOTS), dtype=np.int64)
    tail_units = TAIL_MIN_DB_PER_S * 1.024 / DB_PER_L          # minimum decay over the tail segment

    for j, note in enumerate(notes):
        f_note = 440.0 * 2.0 ** ((note - 69) / 12.0)
        for s in range(PARTIALS):
            if ratios_f[j, s] > 0 and f_note * ratios_f[j, s] < MAX_PARTIAL_HZ:
                ratio[j, s] = int(round(ratios_f[j, s] * (1 << RATIO_FRAC)))
        for l in range(VEL_LAYERS):
            cents, mags = pl.note_vel_rows(j, l)
            ref_db = -1e9
            for s in range(PARTIALS):
                if s >= len(cents) or ratio[j, s] == 0:
                    continue
                codes = [db_to_l_rom(v) for v in mags[s]]
                last_step = (codes[19] - codes[18]) / float(1 << L_FRAC_ROM)
                tail = codes[19] + int(round(max(last_step, tail_units) * (1 << L_FRAC_ROM)))
                codes.append(min(L_MAX_ROM, tail))
                level[j, l, s, :] = codes
                ref_db = max(ref_db, float(np.max(mags[s])))
            # hammer slot
            hpk = min(ref_db, 120.0) + HAMMER_REL_DB - 0.25 * max(0, note - 60)
            hcodes = [db_to_l_rom(hpk + d) for d in HAMMER_SHAPE_DB]
            hcodes.append(L_MAX_ROM)
            level[j, l, HAMMER_SLOT, :] = hcodes

    # per MIDI note: damper release slope, Q4.22 per sample
    rel = np.zeros(128, dtype=np.int64)
    anchors_n = [0, 36, 60, 84, 89, 92, 127]
    anchors_t = [0.40, 0.40, 0.20, 0.12, 0.12, 1.5, 1.5]      # T60 in seconds
    for n in range(128):
        t60 = float(np.interp(n, anchors_n, anchors_t))
        rel[n] = int(round((60.0 / DB_PER_L) * (1 << L_FRAC) / (t60 * pl.FS)))

    # quarter-wave sine: 17 bit magnitude + 9 bit step
    i = np.arange(513)
    sv = np.round(np.sin(np.pi / 2.0 * i / 512.0) * ((1 << 17) - 1)).astype(np.int64)
    sine_val = sv[:512]
    sine_delta = sv[1:] - sv[:512]
    assert sine_delta.max() < 512 and sine_delta.min() >= 0

    # 2^-(i/1024) in Q0.18
    exp_mant = np.round(2.0 ** (-np.arange(1024) / 1024.0) * (1 << 18)).astype(np.int64)
    exp_mant = np.minimum(exp_mant, (1 << 18) - 1)

    return {
        "level": level, "ratio": ratio, "rel_slope": rel,
        "sine_val": sine_val, "sine_delta": sine_delta, "exp_mant": exp_mant,
        "notes": list(notes), "velocities": list(p["velocities"]),
        "ratio_info": ratio_info, "amy_commit": p.get("amy_commit", "unknown"),
    }


if __name__ == "__main__":
    t = build()
    print("level ROM words:", t["level"].size, " ratio ROM words:", t["ratio"].size)
    print("note  partials  reliable  c0[cent]  g[cent/k^2]")
    for note, n, ng, c0, g in t["ratio_info"]:
        print("%4d %8d %9d %9.1f %10.4f" % (note, n, ng, c0, g))
    j = t["notes"].index(60)
    print("C4 ratios:", np.round(t["ratio"][j] / float(1 << RATIO_FRAC), 4))
    print("C4 mf level codes partial 1:", t["level"][j, 1, 0])
    print("C4 mf hammer codes:", t["level"][j, 1, HAMMER_SLOT])
    print("release slope C2/C4/C6:", t["rel_slope"][36], t["rel_slope"][60], t["rel_slope"][84])
