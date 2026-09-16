"""Compare the generic Yosys hierarchy against the recorded pre-upgrade baseline."""
from pathlib import Path
import json
import re

baseline = json.loads(Path("scripts/resource_baseline.json").read_text(encoding="utf-8"))
text = Path("sim_out/resource_after.log").read_text(encoding="utf-8", errors="replace")
marker = text.rfind("+----------Count including submodules.")
if marker < 0:
    raise SystemExit("FAIL: Yosys hierarchy resource summary not found")
summary = text[marker:]


def count_cell(name: str) -> int:
    match = re.search(rf"^\s+(\d+)\s+\${re.escape(name)}\s*$", summary, re.MULTILINE)
    return int(match.group(1)) if match else 0


cells_match = re.search(r"^\s+(\d+)\s+cells\s*$", summary, re.MULTILINE)
if not cells_match:
    raise SystemExit("FAIL: total cell count missing from Yosys summary")
after = {
    "cells": int(cells_match.group(1)),
    "div": count_cell("div"),
    "mul": count_cell("mul"),
    "mod": count_cell("mod"),
    "mux": count_cell("mux"),
    "shift": count_cell("shift"),
}
if after["div"] != 0 or after["mod"] != 0:
    raise SystemExit(f"FAIL: expensive generic arithmetic remains: div={after['div']} mod={after['mod']}")
if after["mul"] >= baseline["mul"]:
    raise SystemExit("FAIL: multiplier count did not improve")
metrics = {"result": "PASS", "before": baseline, "after": after,
           "delta": {key: after[key] - baseline[key] for key in after}}
Path("sim_out/resource_metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
print(f"RESOURCE PASS: div {baseline['div']}->{after['div']}, mul {baseline['mul']}->{after['mul']}, "
      f"mod {baseline['mod']}->{after['mod']}, cells {baseline['cells']}->{after['cells']}")
