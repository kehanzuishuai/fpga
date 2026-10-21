"""Install an isolated official Arduino toolchain in this workspace. No flash."""
from pathlib import Path
import urllib.request,zipfile,json,subprocess,hashlib,sys,time
root=Path(__file__).resolve().parents[1]
dest=root/'tools/toolchains/arduino';dest.mkdir(parents=True,exist_ok=True)
if '--probe-mirror' in sys.argv or '--probe-speed' in sys.argv:
 url='https://jihulab.com/esp-mirror/espressif/arduino-esp32/-/raw/gh-pages/package_esp32_index_cn.json'
 with urllib.request.urlopen(url,timeout=30) as response:payload=response.read()
 path=dest/'package_esp32_index_cn.json';path.write_bytes(payload)
 package=json.loads(payload)['packages'][0]
 latest=package['platforms'][0]
 if '--probe-speed' in sys.argv:
  tool=next(t for t in package['tools'] if t['name']=='esp-x32' and t['version']==next(d['version'] for d in latest['toolsDependencies'] if d['name']=='esp-x32'))
  archive=next(s for s in tool['systems'] if s['host']=='x86_64-mingw32')
  begun=time.time();request=urllib.request.Request(archive['url'],headers={'Range':'bytes=0-1048575'})
  with urllib.request.urlopen(request,timeout=30) as response:
   test=response.read(1048576);print('Mirror probe:',response.status,len(test),'bytes,',round(time.time()-begun,2),'seconds,',response.headers.get('Content-Range'))
  raise SystemExit(0)
 print('Official China mirror version',latest['version'])
 for tool in package['tools']:
  if any(d['name']==tool['name'] and d['version']==tool['version'] for d in latest['toolsDependencies']):
   for system in tool['systems']:
    if system['host']=='x86_64-mingw32':print(tool['name'],tool['version'],system['url'])
 print('Core',latest['url']);raise SystemExit(0)
def download(url,path):
 if not path.exists():
  print('Downloading',url,flush=True)
  with urllib.request.urlopen(url,timeout=90) as r,path.open('wb') as f:
   while b:=r.read(1024*1024):f.write(b)
 return path
cli=dest/'arduino-cli.exe'
if not cli.exists():
 archive=download('https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Windows_64bit.zip',dest/'arduino-cli.zip')
 with zipfile.ZipFile(archive) as z:
  members=[n for n in z.namelist() if Path(n).name=='arduino-cli.exe']
  assert len(members)==1
  cli.write_bytes(z.read(members[0]))
config=dest/'arduino-cli.yaml'
china='--china' in sys.argv
index_url=('https://jihulab.com/esp-mirror/espressif/arduino-esp32/-/raw/gh-pages/package_esp32_index_cn.json' if china else 'https://espressif.github.io/arduino-esp32/package_esp32_index.json')
config.write_text('board_manager:\n  additional_urls:\n    - '+index_url+'\ndirectories:\n'+''.join(f'  {key}: "{(dest/path).as_posix()}"\n' for key,path in [('data','data'),('downloads','downloads'),('user','user')])+'build_cache:\n  path: "'+(dest/'cache').as_posix()+'"\n',encoding='utf-8')
for command in [['version'],['core','update-index']]:
 subprocess.run([str(cli),'--config-file',str(config),*command],check=True)
index=dest/('data/package_esp32_index_cn.json' if china else 'data/package_esp32_index.json')
platforms=json.loads(index.read_text())['packages'][0]['platforms']
version=next(p['version'] for p in platforms if p['architecture']=='esp32' and '-' not in (p['version'][:-3] if p['version'].endswith('-cn') else p['version']))
print('Official ESP32 core:',version,flush=True)
with (dest/'install.log').open('w',encoding='utf-8') as log:
 subprocess.run([str(cli),'--config-file',str(config),'core','install','esp32:esp32@'+version],check=True,stdout=log,stderr=subprocess.STDOUT)
receipt={'cli_sha256':hashlib.sha256(cli.read_bytes()).hexdigest(),'core_version':version,'config':str(config),'no_programming':True}
(dest/'TOOLCHAIN.json').write_text(json.dumps(receipt,indent=2))
print('Isolated compiler ready; no user Arduino settings were modified.',flush=True)
