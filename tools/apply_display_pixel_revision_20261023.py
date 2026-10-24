"""Adopt only source-matched, focused-proven V8 display candidates."""
from pathlib import Path
import datetime,hashlib,json,shutil,xml.etree.ElementTree as E
from display_voice_pixel_20261023 import select_voice_pixel
from display_pane_geometry_20261023 import prepare_pane_geometry
from display_routed_fixes_20261023 import stage_completed_digits
from display_mod7_gap_20261023 import shorten_mod7
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
old=json.loads((A/'PACKED_READY.json').read_text())
enabled=[e.get('path') for e in E.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
assert all(sha(R/n)==old['current_enabled_sha256'][n] for n in enabled)
proof_names=['voice_pixel/RESULT.json','completed_digits/RESULT.json','pane_geometry/ALGEBRA_MAPPING.json','pane_geometry/RESULT.json','mod7_gap/RESULT.json']
for n in proof_names:assert json.loads((A/n).read_text())['status'].startswith('PASS'),n
voice=json.loads((A/proof_names[0]).read_text());digits=json.loads((A/proof_names[1]).read_text())
scene=R/'src/display/visual_scene.sv';labels=R/'src/display/visual_labels.sv';renderer=R/'src/display/visual_renderer.sv'
assert sha(scene)==voice['before_sha256'] and sha(labels)==digits['before_sha256']
assert sha(A/'voice_pixel/candidate_visual_scene.sv')==voice['candidate_sha256']
assert sha(A/'completed_digits/candidate_visual_labels.sv')==digits['candidate_sha256']
assert prepare_pane_geometry(select_voice_pixel(scene.read_text()))==(A/'voice_pixel/candidate_visual_scene.sv').read_text()
assert stage_completed_digits(labels.read_text())==(A/'completed_digits/candidate_visual_labels.sv').read_text()
assert shorten_mod7(renderer.read_text())==(A/'mod7_gap/candidate_visual_renderer.sv').read_text()
assert sha(R/'firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/web_page.h')=='3969c34b4d279eae7e16e1066441730b026b021e04ecf8e4ed52bece4bc719c1'
B=A/'v8_before';B.mkdir(exist_ok=False)
for p in [scene,labels,renderer]:
 out=B/p.relative_to(R);out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out)
shutil.copy2(A/'PACKED_READY.json',A/'PACKED_READY_hybrid_axis_clear_v7.json')
for p,c in [(scene,A/'voice_pixel/candidate_visual_scene.sv'),(labels,A/'completed_digits/candidate_visual_labels.sv'),(renderer,A/'mod7_gap/candidate_visual_renderer.sv')]:shutil.copy2(c,p)
for p,f in [(scene,lambda s:prepare_pane_geometry(select_voice_pixel(s))),(labels,stage_completed_digits),(renderer,shorten_mod7)]:assert f(p.read_text())==p.read_text()
new=dict(old);new.update(recorded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),candidate='V8_EARLY_VOICE_PIXEL_COMMON_PANE_COMPLETED_ASCII_MOD7',
 status='FOCUSED_CHECKS_PASSED_READY_FOR_FULL_SYNTHESIS',current_enabled_sha256={n:sha(R/n) for n in enabled})
new['proof_sha256']=dict(old['proof_sha256']);new['proof_sha256'].update({n:sha(A/n) for n in proof_names})
new['scope']='V7 plus exact early display indicator flags, common pane centers, staged completed text and modulo7. Physical32piano/audio/FFT/HDMI/DAC/GAO unchanged;40/21display clocks preserved. New full synthesis and STA pending.'
(A/'PACKED_READY.json').write_text(json.dumps(new,indent=2))
live=json.loads((A/'LIVE.json').read_text());live.update(updated_utc=new['recorded_utc'],current_root='V8displaysource applied after focused PASS. Rootimpl still coherent V7checkpoint until new build completes; not timing closed.',next_steps='Run fresh V8synthesis then placement/routing and all STA; no old placement hint, no flashing.')
(A/'LIVE.json').write_text(json.dumps(live,indent=2))
p=R/'README.md';text=p.read_text();import re
text=re.sub(r'^> 2026-10-23最新结论：.*$', '> 后续修复进行中：V8显示数据通路已通过定点像素对照，正在重新综合和实现；主目录impl暂为V7失败检查点。最近完成的V7位置提示对照仍未通过时序（Setup -12.768ns、Hold -0.439ns），不能烧录。',text,flags=re.M);p.write_text(text,encoding='utf-8')
with (A/'PROGRESS.md').open('a',encoding='utf-8') as f:f.write('''

V8候选已通过8704拍场景像素对照（32个Voice指示区域、逐拍变化位图/有效性）、11560拍字符对照（90区域/32键）、1638400轴圆角代数对照和4096个mod7输入穷举。应用到根目录3份已启用display文件；仅内部显示数据减少，音源不改。40/21拍延迟不变。V7原源码和READY保存在v8_before与PACKED_READY_hybrid_axis_clear_v7.json。主impl暂仍V7失败检查点，新SYN/PnR需完成才可对应新源码；release未更动、不烧录。
''')
print(json.dumps(dict(status=new['status'],candidate=new['candidate'],changed_display={str(p.relative_to(R)):sha(p) for p in [scene,labels,renderer]}),indent=2))
