"""Write the ROMs of the FPGA piano engine as Verilog.

    python tools/gen_piano_rom.py            (run from piano_v2)

Output (all generated, do not edit by hand):
    src/piano_level_rom.v    partial levels   21 notes x 3 velocities x 16 slots x 21 points, 12 bit
    src/piano_ratio_rom.v    partial ratios   21 notes x 16 slots, 20 bit
    src/piano_note_rom.v     per MIDI note:   damper release slope, 22 bit
    src/piano_sine_rom.v     quarter sine     512 x {17 bit value, 9 bit step}
    src/piano_exp_rom.v      2^-x             1024 x 18 bit

The ROMs are written as registered `case` look-ups, the form the existing
piano_dual_wavetable.v uses and GowinSynthesis already maps to pROM in this
project.  No $readmemh, so there is no file path to get wrong in the IDE.
Large tables are split into blocks of 1024 words (one case statement each).

A `case` with thousands of entries is very slow in Icarus Verilog, so the
same contents are also written as plain arrays:
    sim/models/piano_roms_fast.v   same module names, same ports, same timing
    sim/tb/tb_rom_equiv.v          sweeps every address of every ROM and
                                   compares the two forms
Simulations compile piano_roms_fast.v instead of src/piano_*_rom.v.
"""
import os

import numpy as np

import piano_tables as pt

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "src")
SIM = os.path.join(HERE, "..", "sim")
NL = "\n"

HEADER = """/* ============================================================
 * GENERATED FILE - do not edit.
 *
 * Written by tools/gen_piano_rom.py
 * %s
 * ============================================================ */

"""


def case_block(name, width, values, abits, indent="    "):
    hexw = (width + 3) // 4
    out = ["%salways @(posedge clk) begin" % indent, "%s    case (addr[%d:0])" % (indent, abits - 1)]
    line = []
    for i, v in enumerate(values):
        line.append("%d'd%d: %s <= %d'h%0*X;" % (abits, i, name, width, hexw, int(v)))
        if len(line) == 4:
            out.append("%s        %s" % (indent, " ".join(line)))
            line = []
    if line:
        out.append("%s        %s" % (indent, " ".join(line)))
    out.append("%s        default: %s <= %d'd0;" % (indent, name, width))
    out.append("%s    endcase" % indent)
    out.append("%send" % indent)
    return NL.join(out)


def rom_module(name, width, values, comment, default=0, block=1024):
    """Synchronous ROM: q is valid one clock after addr."""
    n = len(values)
    abits = max(1, int(np.ceil(np.log2(n))))
    text = [HEADER % comment]
    text.append("module %s (" % name)
    text.append("    input  wire        clk,")
    text.append("    input  wire [%d:0] addr," % (abits - 1))
    text.append("    output reg  [%d:0] q" % (width - 1))
    text.append(");" + NL)
    if n <= block:
        text.append(case_block("q", width, values, abits))
    else:
        nblk = (n + block - 1) // block
        bbits = int(np.log2(block))
        sbits = abits - bbits
        text.append("/* %d words in %d blocks of %d */" % (n, nblk, block) + NL)
        text.append("reg [%d:0] sel;" % (sbits - 1) + NL)
        text.append("always @(posedge clk)" + NL + "    sel <= addr[%d:%d];" % (abits - 1, bbits) + NL)
        for b in range(nblk):
            text.append("reg [%d:0] q%d;" % (width - 1, b) + NL)
            text.append(case_block("q%d" % b, width, values[b * block:(b + 1) * block], bbits, indent=""))
            text.append("")
        text.append("always @(*) begin" + NL + "    case (sel)")
        for b in range(nblk):
            text.append("        %d'd%d: q = q%d;" % (sbits, b, b))
        text.append("        default: q = %d'h%X;" % (width, default))
        text.append("    endcase" + NL + "end")
    text.append(NL + "endmodule" + NL)
    return NL.join(text)


def full_table(values, default=0, block=1024):
    """Contents for every possible address, with the defaults of rom_module()."""
    n = len(values)
    abits = max(1, int(np.ceil(np.log2(n))))
    if n <= block:
        full = [0] * (1 << abits)
    else:
        full = [int(default)] * (1 << abits)
        nblk = (n + block - 1) // block
        for i in range(nblk * block):
            full[i] = 0
    for i, v in enumerate(values):
        full[i] = int(v)
    return abits, full


def fast_module(name, width, values, default=0, block=1024):
    abits, full = full_table(values, default, block)
    hexw = (width + 3) // 4
    text = ["`ifdef ROM_EQUIV", "module %s_fast (" % name, "`else", "module %s (" % name, "`endif"]
    text.append("    input  wire        clk,")
    text.append("    input  wire [%d:0] addr," % (abits - 1))
    text.append("    output reg  [%d:0] q" % (width - 1))
    text.append(");" + NL)
    text.append("reg [%d:0] mem [0:%d];" % (width - 1, (1 << abits) - 1) + NL)
    text.append("initial begin")
    line = []
    for i, v in enumerate(full):
        line.append("mem[%d]=%d'h%0*X;" % (i, width, hexw, v))
        if len(line) == 6:
            text.append("    " + " ".join(line))
            line = []
    if line:
        text.append("    " + " ".join(line))
    text.append("end" + NL)
    text.append("always @(posedge clk)" + NL + "    q <= mem[addr];" + NL)
    text.append("endmodule" + NL)
    return NL.join(text), abits


def equiv_tb(roms):
    t = ["`timescale 1ns/1ps" + NL,
         "/* GENERATED by tools/gen_piano_rom.py: case ROMs against array ROMs */" + NL,
         "module tb_rom_equiv;" + NL, "reg clk = 1'b0;", "always #5 clk = ~clk;" + NL,
         "integer errors = 0;", "integer i;" + NL]
    for name, width, abits in roms:
        t.append("reg  [%d:0] a_%s = 0;" % (abits - 1, name))
        t.append("wire [%d:0] q_%s;" % (width - 1, name))
        t.append("wire [%d:0] f_%s;" % (width - 1, name))
        t.append("%s u_%s (.clk(clk), .addr(a_%s), .q(q_%s));" % (name, name, name, name))
        t.append("%s_fast v_%s (.clk(clk), .addr(a_%s), .q(f_%s));" % (name, name, name, name) + NL)
    t.append("initial begin")
    for name, width, abits in roms:
        t.append("    for (i = 0; i < %d; i = i + 1) begin" % (1 << abits))
        t.append("        a_%s = i;" % name)
        t.append("        @(posedge clk); #1;")
        t.append("        if (q_%s !== f_%s) begin" % (name, name))
        t.append("            errors = errors + 1;")
        t.append('            if (errors < 10) $display("ERROR %s[%%0d]: case %%h, array %%h", i, q_%s, f_%s);'
                 % (name, name, name))
        t.append("        end")
        t.append("    end")
        t.append('    $display("%s: %d addresses compared");' % (name, 1 << abits))
    t.append('    if (errors == 0) $display("PASS: ROM forms identical");')
    t.append('    else $display("FAIL: %0d differences", errors);')
    t.append("    $finish;")
    t.append("end" + NL + NL + "endmodule" + NL)
    return NL.join(t)


def write(name, text):
    path = os.path.join(SRC, name)
    with open(path, "w", encoding="ascii", newline="\r\n") as f:
        f.write(text)
    print("wrote src/%-22s %7d bytes" % (name, len(text)))


def main():
    t = pt.build()
    src = "Source data: AMY piano table, commit %s" % t["amy_commit"]
    sine = (t["sine_val"] << 9) | t["sine_delta"]

    roms = [
        ("piano_level_rom", 12, t["level"].reshape(-1), pt.L_MISSING,
         src + NL + " * addr = ((note*3 + vel)*16 + slot)*21 + point   level Q4.8, 12'hFFF = no partial"),
        ("piano_ratio_rom", 20, t["ratio"].reshape(-1), 0,
         src + NL + " * addr = note*16 + slot   partial frequency / note frequency, Q5.15, 0 = no partial"),
        ("piano_note_rom", 22, t["rel_slope"], 0,
         "addr = MIDI note   damper release slope, level units Q4.22 per sample"),
        ("piano_sine_rom", 26, sine, 0,
         "Quarter sine wave: q[25:9] = round(sin(pi/2 * addr/512) * (2^17-1)), q[8:0] = step to addr+1"),
        ("piano_exp_rom", 18, t["exp_mant"], 0,
         "q = round(2^-(addr/1024) * 2^18), limited to 18 bit"),
    ]

    fast = [HEADER % "Simulation-only array form of the ROMs in src/piano_*_rom.v (same contents)"]
    info = []
    for name, width, values, default, comment in roms:
        write(name + ".v", rom_module(name, width, values, comment, default=default))
        text, abits = fast_module(name, width, values, default)
        fast.append(text)
        info.append((name, width, abits))

    with open(os.path.join(SIM, "models", "piano_roms_fast.v"), "w", encoding="ascii", newline="\n") as f:
        f.write(NL.join(fast))
    with open(os.path.join(SIM, "tb", "tb_rom_equiv.v"), "w", encoding="ascii", newline="\n") as f:
        f.write(equiv_tb(info))
    print("wrote sim/models/piano_roms_fast.v and sim/tb/tb_rom_equiv.v")
    print("level words %d, ratio words %d" % (t["level"].size, t["ratio"].size))


if __name__ == "__main__":
    main()
