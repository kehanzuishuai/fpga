"""Exercise a relocated project, spaces, explicit overrides and failure exit codes."""
from pathlib import Path
import tempfile,shutil,subprocess,sys,json
from toolchain import ROOT,discover,environment

tc=discover();env=environment()
for k,v in tc.items():env['FPGA_'+k.upper()]=str(v)
with tempfile.TemporaryDirectory(prefix='fpga relocated project ') as tmp:
    clone=Path(tmp)/'board with spaces'
    shutil.copytree(ROOT,clone,ignore=shutil.ignore_patterns('sim_out*','__pycache__'))
    command=[sys.executable,str(clone/'scripts/run_regression.py'),'--check-tools']
    p=subprocess.run(command,env=env,text=True,capture_output=True)
    assert p.returncode==0,p.stdout+p.stderr
    result=json.loads((clone/'sim_out_visual/tools_summary.json').read_text())
    assert result['status']=='PASS' and result['mode']=='preflight'
    image=clone/'sim_out_visual/readout.vvp'
    p=subprocess.run([str(tc['iverilog']),'-g2012','-s','tb_visual_readout','-o',str(image),
        'src/visual_renderer.sv','src/visual_labels.sv','sim/tb_visual_readout.sv'],cwd=clone,env=env,capture_output=True,text=True)
    assert p.returncode==0,p.stdout+p.stderr
    p=subprocess.run([str(tc['vvp']),str(image)],cwd=clone,env=env,capture_output=True,text=True)
    assert p.returncode==0 and 'PASS' in p.stdout,p.stdout+p.stderr
    env['FPGA_IVERILOG']=str(clone/'missing-tool')
    p=subprocess.run(command,env=env,capture_output=True,text=True)
    assert p.returncode!=0,'Missing override incorrectly accepted'
    result=json.loads((clone/'sim_out_visual/tools_summary.json').read_text())
    assert result['status']=='FAIL' and 'FPGA_IVERILOG' in result['error']
print('PASS relocated project with spaces, override discovery, compilation/simulation and actionable missing-tool failure')
