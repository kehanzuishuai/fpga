from pathlib import Path
import json,hashlib,datetime,shutil,xml.etree.ElementTree as ET,sys
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022';old=R/'audit/autonomous_timing_20261022_154006'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
proofs=['key_lip/verification_balanced_arithmetic/RESULT.json','display_arithmetic/verification/RESULT.json','packed_ks/verification/RESULT.json','packed_ks/bank_verification/RESULT.json','packed_ks/resource_pair/RESULT.json','packed_ks/pair_gate/RESULT.json']
assert all(json.loads((A/n).read_text())['status'].startswith('PASS') for n in proofs)
sys.path.insert(0,str(R/'tools'));from display_prefix_bits_20261023 import prefix_renderer
before=A/'display_arithmetic/before/src/display/visual_renderer.sv';current=R/'src/display/visual_renderer.sv'
assert prefix_renderer(before.read_text())==current.read_text()
(A/'display_arithmetic/RENDERER_STRUCTURE.json').write_text(json.dumps(dict(status='PASS',scope='Byte-exact reproduction from before source; only original magnitude/sign expressions replaced by combinational helper, no changed sequential schedule or metadata.',before_sha256=sha(before),current_sha256=sha(current)),indent=2))
proofs.append('display_arithmetic/RENDERER_STRUCTURE.json')
baseline=json.loads((old/'FINAL.json').read_text());enabled=[e.get('path') for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
changed=[n for n in enabled if sha(R/n)!=baseline['source_sha256'][n]]
assert set(changed)=={'src/display/visual_scene.sv','src/display/visual_renderer.sv','src/instruments/jita/yinse_ks_loop.sv','src/instruments/gongyong/yinse_aux_voice.sv','src/instruments/gongyong/yinse_aux_bank.sv'}
for n in ['firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/web_page.h']:
    assert sha(R/n)=='3969c34b4d279eae7e16e1066441730b026b021e04ecf8e4ed52bece4bc719c1'
prior=A/'PACKED_READY_memory_lip_v1.json'
if not prior.exists():shutil.copy2(A/'PACKED_READY.json',prior)
rec=dict(status='FOCUSED_EQUIVALENCE_PASS_FULL_BUILD_PENDING',recorded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    candidate='audit/autonomous_timing_20261022_154006/runs/followup_packed_balanced_p3_r0',changed_enabled_inputs=changed,enabled_input_count=len(enabled),
    current_enabled_sha256={n:sha(R/n) for n in enabled},proof_sha256={n:sha(A/n) for n in proofs},
    scope='Original physical32-piano engine, audio coefficients, event routing/count, FFT/HDMI/DAC/GAO and phone UI preserved; auxiliary KS lossless memory representation and exact same-latency display arithmetic only.',programming=False)
(A/'PACKED_READY.json').write_text(json.dumps(rec,indent=2))
with (A/'PROGRESS.md').open('a',encoding='utf-8') as f:f.write('''

08:44更新：第一版组合候选完整综合通过，实际BSRAM331→315、FF49168、DSP类型数量不变，像素预估55.340→60.656MHz（仍小于74.25）。目前该候选exec67592/PID36508已进入布局；保留它完成实际布线作为资源减负对照，不能称时序通过。

新关键路径是renderer波形绝对值到DSP输入的17级LUT链，以及scene面板11位/13除法。已在当前根源码做第二版显示优化：用分组前缀实现精确条件取负（无新寄存器），将/13和/5拆为前一已有拍的高位小表与后一拍的余数小表+加法；总40拍不变、颜色不变。全部2048个/13和1024个/5输入、131072个16位符号恢复、131126个27位取负案例通过；新场景与原交付512像素对照通过；renderer两条寄存器表达式之外的源结构字节级核对。

第二版READY收据已写PACKED_READY.json，第一版收据保留PACKED_READY_memory_lip_v1.json。主目录现在相对上轮baseline修改5份启用RTL（三个aux内存文件、两个display文件），96个启用输入，物理钢琴算法和UI哈希不变。下一步第二版完整综合与实现tag followup_packed_balanced_p3_r0，源需重新综合，不能拿第一版315网表当第二版源码结果。内存资源最多两组大任务，不烧录。
''')
print(json.dumps({k:rec[k] for k in ['status','candidate','changed_enabled_inputs','enabled_input_count']},indent=2))
