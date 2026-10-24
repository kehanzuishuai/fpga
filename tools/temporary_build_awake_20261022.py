"""Temporary process-only wake request during authorized local builds."""
from pathlib import Path
import ctypes,os,time
R=Path(__file__).resolve().parents[1]
D=R/'audit/routing_followup_20261022';D.mkdir(exist_ok=True)
(D/'awake_pid.txt').write_text(str(os.getpid()))
assert ctypes.windll.kernel32.SetThreadExecutionState(0x80000003)
try:
    deadline=time.monotonic()+4*3600
    while time.monotonic()<deadline and not (D/'stop_awake').exists():time.sleep(5)
finally:ctypes.windll.kernel32.SetThreadExecutionState(0x80000000)
