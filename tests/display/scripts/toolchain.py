"""Discover tools without user-specific paths. FPGA_* overrides fail loudly."""
from pathlib import Path
import os, shutil, sys
ROOT=Path(__file__).resolve().parents[1]

def find_tool(variable,names,extras=()):
    override=os.environ.get(variable)
    if override:
        resolved=shutil.which(override) or (override if Path(override).is_file() else None)
        if not resolved:raise RuntimeError(f'{variable}={override!r} not found; set it to an executable')
        return Path(resolved).resolve()
    for name in names:
        resolved=shutil.which(name)
        if resolved:return Path(resolved).resolve()
    for folder in extras:
        for name in names:
            for suffix in ('','.exe'):
                candidate=folder/(name+suffix)
                if candidate.is_file():return candidate.resolve()
    raise RuntimeError(f'Missing {names[0]}; install on PATH or set {variable}')

def discover():
    users=sorted((Path(os.environ.get('APPDATA','__absent__'))/'Python').glob('*/Scripts'),reverse=True)
    local=[ROOT/'bin',ROOT.parent/'bin',ROOT.parent.parent/'bin',Path(sys.executable).parent/'Scripts',*users]
    return {key:find_tool('FPGA_'+key.upper(),names,local) for key,names in
            [('iverilog',('iverilog',)),('vvp',('vvp',))]}

def environment():
    env=dict(os.environ);env['LANG']=env['LC_ALL']='C'
    perl=Path(os.environ.get('SystemDrive','C:')+'/')/'Strawberry/perl/bin'
    if perl.is_dir():env['PATH']=str(perl)+os.pathsep+env.get('PATH','')
    return env
