from pathlib import Path
import json,datetime,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022';A.mkdir(exist_ok=True)
old=R/'audit/autonomous_timing_20261022_154006'
f=old/'runs/followup_pll_local_raw/RESULT.json';j=json.loads(f.read_text())
j.update(status='STOPPED_UNSUPPORTED_CONSTRAINT',reason='CT1018 explicitly says LOCAL_CLOCK unavailable for clk_50m_d; stopped own gw_sh PID28900 before detailed routing. Not a completed routing failure.')
f.write_text(json.dumps(j,indent=2))
corr=dict(status='CORRECTED',old_diagnostic='clock_topology_probe',issue='Whitespace-sensitive IO_LOC filter omitted actual clk/reset/audio pins; prior clock was unconstrained P4. Old diagnostic is not evidence for production P16.',
    replacement='audit/autonomous_timing_20261022_154006/clock_topology_p16_verified/RESULT.json',replacement_actual_pin='P16',replacement_actual_reset_pin='K16',replacement_returncode=0,
    scope='Small corrected diagnostic completed. Does not prove main FPGA implementation.',programming=False)
(A/'DIAGNOSTIC_CORRECTION.json').write_text(json.dumps(corr,indent=2))
oldreport=R/'docs/AUTONOMOUS_TIMING_20261022.md';s=oldreport.read_text(encoding='utf-8')
if '小型诊断管脚更正' not in s:
    s+='\n## 后续复核：小型诊断管脚更正\n\n前述`clock_topology_probe`的约束提取遗漏额外空格，实际时钟为未约束P4，不能支撑P16板级结论。后续已修正解析，逐项核对10个端口在实际报告中的位置及约束标记；`clock_topology_p16_verified`真实采用P16/K16及相同相关输出管脚，完成实现并生成自己的STA/FS。仅为小型诊断，整机结论仍是未通过。详见`audit/routing_followup_20261022/DIAGNOSTIC_CORRECTION.json`。\n'
    oldreport.write_text(s,encoding='utf-8')
readme=R/'README.md';s=readme.read_text(encoding='utf-8')
notice='> 后续修复进行中：用户再次授权继续解决布线失败。正以冻结的同一综合网表进行新布局/布线定位；原本轮结论保留为历史，尚无新整机通过结果。记录见`audit/routing_followup_20261022/`。不烧录。\n\n'
if notice not in s:s=s.replace('# Tang Mega 138K Pro FPGA电子钢琴\n\n','# Tang Mega 138K Pro FPGA电子钢琴\n\n'+notice,1);readme.write_text(s,encoding='utf-8')
(A/'START.json').write_text(json.dumps(dict(started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),authorization='Continue resolving routing failure; no feature/UI deletion or flashing',
    baseline=json.loads((old/'FINAL.json').read_text()),programming=False),indent=2))
print('Recorded follow-up authorization, invalid-constraint stop and corrected physical probe scope.')
