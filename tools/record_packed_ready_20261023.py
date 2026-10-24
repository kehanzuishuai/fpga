from pathlib import Path
import json,datetime,hashlib,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022';old=R/'audit/autonomous_timing_20261022_154006'
proofs=['key_lip/verification/RESULT.json','packed_ks/verification/RESULT.json','packed_ks/bank_verification/RESULT.json','packed_ks/resource_pair/RESULT.json','packed_ks/pair_gate/RESULT.json']
assert all(json.loads((A/n).read_text())['status'].startswith('PASS') for n in proofs)
p=old/'runs/followup_pll_p3_r1_inc/RESULT.json';j=json.loads(p.read_text())
j.update(status='STOPPED_FOR_NEW_VALIDATED_REVISION',reason='Own PID25588 stopped during detailed routing; release memory for complete new combined lossless RAM/pixel revision. No completion/no STA; not a completed tool routing error.')
p.write_text(json.dumps(j,indent=2))
baseline=json.loads((old/'FINAL.json').read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
enabled=[e.get('path') for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
changed=[n for n in enabled if sha(R/n)!=baseline['source_sha256'][n]]
assert set(changed)=={'src/display/visual_scene.sv','src/instruments/jita/yinse_ks_loop.sv','src/instruments/gongyong/yinse_aux_voice.sv','src/instruments/gongyong/yinse_aux_bank.sv'}
assert sha(R/'firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/web_page.h')=='3969c34b4d279eae7e16e1066441730b026b021e04ecf8e4ed52bece4bc719c1'
record=dict(status='FOCUSED_EQUIVALENCE_AND_PAIR_SYNTHESIS_PASS_FULL_BUILD_RUNNING',recorded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    candidate='audit/autonomous_timing_20261022_154006/runs/followup_packed_ks_key_lip_p3_r0',
    changed_enabled_inputs=changed,enabled_input_count=len(enabled),proof_sha256={n:sha(A/n) for n in proofs},
    scope='Only pixel edge arithmetic and auxiliary guitar memory representation changed from prior clock candidate. Physical32-piano engine, waveforms, note events, scheduler counts, HDMI/FFT/DACs and phone UI inputs unchanged.',programming=False)
(A/'PACKED_READY.json').write_text(json.dumps(record,indent=2))
with (A/'PROGRESS.md').open('a',encoding='utf-8') as f:f.write('''

08:18更新：32声部整库对照已全部通过。四种辅助音色均32声部发声，24,672周期PCM、分配、忙闲、显示音符、溢出/削波标志逐拍一致。真实综合出的三块BSRAM网表另做6,826次端口读比较通过，两半区1024地址及非对称并发写覆盖。只做与本次存储结构相关的必要测试，未重跑44音长音频/整帧HDMI。

旧网表Route1进程25588已主动停止并记STOPPED_FOR_NEW_VALIDATED_REVISION，不算完成的工具错误；旧网表P0/R0仍继续。新组合版`followup_packed_ks_key_lip_p3_r0`已从当前源码完整综合再PnR/STA，exec67592。没有使用旧网表代替新源码，没有使用旧布局hint。物理钢琴相关所有输入与上轮baseline哈希一致；新改动只有一份显示RTL和三份辅助音色内存RTL。工程仍96个已启用输入，新模块写在已启用文件中，无需新增GPRJ条目。
''')
print(json.dumps(record,indent=2))
