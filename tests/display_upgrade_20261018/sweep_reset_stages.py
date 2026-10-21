from pathlib import Path
import subprocess,sys,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
s=(R/'src/display/visual_dvi_io.v').read_text()
for count in range(3,13):
    q=s.replace('reg [2:0] reset_release',f'reg [{count-2}:0] reset_release').replace('reset_release[1:0]',f'reset_release[{count-3}:0]').replace('local_rst_n<=reset_release[2]',f'local_rst_n<=reset_release[{count-2}]')
    p=O/f'reset_stage_{count}.v';p.write_text(q)
    z=subprocess.run([sys.executable,'-X','utf8','-B','-u',str(O/'boundary_checks.py'),str(p)],cwd=R,capture_output=True)
    print(count,z.returncode,z.stdout.decode(errors='replace').strip(),flush=True)
    (O/f'reset_stage_{count}.log').write_bytes(z.stdout+z.stderr)
