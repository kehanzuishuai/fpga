"""Compare the files on disk with a regression manifest (run from piano_v2).

    python sim/check_manifest.py [docs/test_manifest_all.txt]

Prints every file whose contents changed since that regression ran, i.e. every
file for which the recorded test results are no longer evidence.
"""
import hashlib
import os
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "docs/test_manifest_all.txt"
changed, missing, same = [], [], 0
section = None
for line in open(path, encoding="utf-8"):
    line = line.rstrip("\n")
    if line.startswith("["):
        section = line
        continue
    if line.startswith("#"):
        print(line)
        continue
    if section != "[files]" or not line.strip():
        continue
    h, name = line.split(None, 1)
    if not os.path.exists(name):
        missing.append(name)
    elif hashlib.sha256(open(name, "rb").read()).hexdigest() != h:
        changed.append(name)
    else:
        same += 1
print("%d files unchanged since this regression" % same)
for name in changed:
    print("CHANGED  " + name)
for name in missing:
    print("MISSING  " + name)
sys.exit(1 if changed or missing else 0)
