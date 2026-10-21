from pathlib import Path
import xml.etree.ElementTree as ET,subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
files=[R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1' and Path(e.attrib['path']).suffix in ['.v','.sv']]
hashes={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
iv=r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe'
z=subprocess.run(list(map(str,[iv,'-g2012','-I',R,'-s','tb_hardware_elaboration','-o',O/'board_final.vvp',*files,R/'tests/integration/tb_hardware_elaboration.sv',r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v'])),cwd=R,capture_output=True)
(O/'board_final.log').write_bytes(z.stdout+z.stderr);assert z.returncode==0,z.stderr[-2000:]
result={'status':'PASS','source_sha256':hashes,'scope':'Full current main project elaborated with actual Gowin GW5A primitive definitions; no physical monitor claim'}
(O/'BOARD_FINAL.json').write_text(json.dumps(result,indent=2));print('PASS current main project, actual Gowin primitive elaboration')
