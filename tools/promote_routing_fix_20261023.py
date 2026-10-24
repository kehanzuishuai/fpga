"""Promote one verified follow-up build, archiving stale root implementation files."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022';runs=R/'audit/autonomous_timing_20261022_154006/runs'
p=argparse.ArgumentParser();p.add_argument('tag');o=p.parse_args();assert re.fullmatch('[a-z0-9_]+',o.tag)
D=runs/o.tag;r=json.loads((D/'RESULT.json').read_text());assert r['status']!='RUNNING'
readme=R/'README.md';readme_before=readme.read_text(encoding='utf-8')
header_match=re.search(r'^> (?:后续修复进行中|2026-10-23最新结论：).*$',readme_before,re.M)
assert header_match,'Latest follow-up status header must exist before promotion'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
enabled=[e.get('path') for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
assert len(enabled)==96
for n in enabled:
    assert sha(R/n)==sha(D/n)==r['inputs'][n],('Root or snapshot source drift',n)
log=(D/'console.log').read_text(errors='replace')
if 'GowinSynthesis finish' in log:
    assert not re.findall(r'^ERROR.*',log.split('GowinSynthesis finish',1)[0],re.M)
else:
    # A PnR-only attempt must carry the exact, successfully completed parent SYN.
    reuse=r.get('synthesis_reuse');assert reuse,'No completed synthesis provenance'
    parent=Path(reuse['parent']).resolve();assert parent.is_relative_to(runs.resolve())
    parent_record=json.loads((parent/'RESULT.json').read_text(encoding='utf-8-sig'))
    parent_log=(parent/'console.log').read_text(errors='replace')
    assert 'GowinSynthesis finish' in parent_log
    assert not re.findall(r'^ERROR.*',parent_log.split('GowinSynthesis finish',1)[0],re.M)
    for n in ['impl/gwsynthesis/yinyue_fashengqi.vg','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']:
        key='netlist_sha256' if n.endswith('.vg') else 'synthesis_report_sha256'
        assert sha(D/n)==sha(parent/n)==reuse[key],('Reused synthesis artifact drift',n)
    for n,h in parent_record['inputs'].items():
        if n.startswith(('src/','assets/')) or n=='yinyue_fashengqi.gprj':
            assert sha(parent/n)==h,('Parent synthesis input drift',n)
            if n not in {'src/integrated.sdc','src/integrated.cst'}:
                assert sha(D/n)==h,('Reused synthesis source drift',n)
assert r['inputs_unchanged'] and r['final_netlist_sha256']==sha(D/'impl/gwsynthesis/yinyue_fashengqi.vg')
config=json.loads((D/'impl/yinyue_fashengqi_process_config.json').read_text())
for key,opt in [('Place_Option','place'),('Route_Option','route'),('Clock_Route_Order','clock_order'),
                ('Run_Timing_Driven','timing_driven'),('Correct_Hold_Violation','correct_hold'),('Replicate_Resources','replicate')]:
    assert int(config[key])==int(r['options'][opt]),('Saved implementation configuration differs',key)
assert config['Generate_Plain_Text_Timing_Report'] and not config['Convert_SDP32_36_to_SDP16_18']
if r['status']=='PASS':
    check=json.loads((D/'STA_INSPECTION.json').read_text())
    assert check['status']=='PASS_REPORT_PROVENANCE_AND_CLOCKS'
    assert check['report_sha256']==sha(D/'impl/pnr/yinyue_fashengqi.tr')
    assert len(r['worst_slack_ns'])==5 and all(v is not None and v>=0 for v in r['worst_slack_ns'].values())
    assert r['violated_endpoints']=={'Setup':0,'Hold':0}
    assert r['artifacts']['ao_0.fs']['fresh'] and not r['errors'] and r['returncode']==0
proofs=json.loads((A/'PACKED_READY.json').read_text())
for n,h in proofs['proof_sha256'].items():assert sha(A/n)==h
if 'current_enabled_sha256' in proofs:
    assert all(sha(R/n)==proofs['current_enabled_sha256'][n] for n in enabled)
if 'current_asset_sha256' in proofs:
    for n,h in proofs['current_asset_sha256'].items():
        assert sha(R/n)==sha(D/n)==h==r['inputs'][n],('Asset drift',n)
assert sha(R/'release/latest/ao_0.fs')=='e483552fc9993df6e9464790a9ca29d7e8253e02a51002507d05ee2234884e0b'
stamp=datetime.datetime.now().strftime('%Y%m%d_%H%M%S');B=A/('root_before_'+o.tag+'_'+stamp);B.mkdir()
for n in ['src','assets']:shutil.copytree(R/n,B/n)
for n in ['yinyue_fashengqi.gprj','yinyue_fashengqi.gprj.user','README.md']:
    if (R/n).exists():shutil.copy2(R/n,B/n)
if (R/'impl/yinyue_fashengqi_process_config.json').exists():shutil.copy2(R/'impl/yinyue_fashengqi_process_config.json',B/'process_config.before.json')
moved=[]
try:
    for n in ['impl/gwsynthesis','impl/pnr']:
        s=(R/n).resolve();b=(B/n).resolve();assert s.is_relative_to(R.resolve()) and b.is_relative_to(B.resolve()) and s==R/n
        b.parent.mkdir(parents=True,exist_ok=True)
        if s.exists():shutil.move(str(s),str(b))
        moved.append(n);shutil.copytree(D/n,R/n)
except Exception:
    for n in reversed(moved):
        s=(R/n).resolve();b=(B/n).resolve();partial=(B/'partial_copy'/n).resolve()
        assert s.is_relative_to(R.resolve()) and b.is_relative_to(B.resolve()) and partial.is_relative_to(B.resolve())
        if s.exists():partial.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(s),str(partial))
        if b.exists():shutil.move(str(b),str(s))
    raise
for n in ['src','assets']:shutil.copytree(D/n,R/n,dirs_exist_ok=True)
for n in ['yinyue_fashengqi.gprj','yinyue_fashengqi.gprj.user','impl/yinyue_fashengqi_process_config.json']:
    if (D/n).exists():shutil.copy2(D/n,R/n)
assert all(sha(R/n)==r['inputs'][n] for n in enabled)
assert sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')==r['final_netlist_sha256']
for n,h in r['artifacts'].items():assert sha(R/'impl/pnr'/n)==h['sha256']
resources=ET.parse(R/'impl/gwsynthesis/yinyue_fashengqi_syn_rsc.xml').getroot().attrib
physical_text=(R/'impl/pnr/yinyue_fashengqi.rpt.txt').read_text(errors='replace') if (R/'impl/pnr/yinyue_fashengqi.rpt.txt').exists() else ''
physical_resources={}
for name in ['Logic','Register','CLS','BSRAM','DSP']:
    m=re.search(r'^\s*'+name+r'\s*\|\s*(\d+)/(\d+)',physical_text,re.M)
    if m:physical_resources[name]=dict(used=int(m[1]),total=int(m[2]),remaining=int(m[2])-int(m[1]))
final=dict(status='TIMING_PASS_NOT_PROGRAMMED' if r['status']=='PASS' else 'NOT_TIMING_CLOSED_NOT_PROGRAMMED',candidate=o.tag,
    completed_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),source_sha256={n:sha(R/n) for n in enabled},
    netlist_sha256=r['final_netlist_sha256'],artifacts=r['artifacts'],worst_slack_ns=r['worst_slack_ns'],violated_endpoints=r['violated_endpoints'],
    attempt_status=r['status'],errors=r['errors'],options=r['options'],synthesis_resources=resources,physical_resources=physical_resources,backup=str(B),
    proof_receipt='audit/routing_followup_20261022/PACKED_READY.json',asset_sha256={n:sha(R/n) for n in r['inputs'] if n.startswith('assets/')},programming=False,published=False,
    old_release_unchanged_sha256=sha(R/'release/latest/ao_0.fs'))
(A/'FINAL.json').write_text(json.dumps(final,indent=2))
current=R/'audit/display_integration_20261021/CURRENT.json'
if current.exists():shutil.copy2(current,B/'CURRENT.before.json')
current.write_text(json.dumps(dict(status=final['status'],receipt='audit/routing_followup_20261022/FINAL.json',note='Source, netlist and outputs all match this candidate; no programming.'),indent=2))
message='新组合版已通过完整实现及五类STA，未烧录。' if r['status']=='PASS' else '新组合版尚未通过完整实现与STA，未烧录。'
readme=R/'README.md';s=readme.read_text(encoding='utf-8');a=header_match.start();b=s.index('\n\n',a)
s=s[:a]+f'> 2026-10-23最新结论：{message}当前源码、综合网表和实现产物均对应`{o.tag}`。详见[本次修复结果](docs/ROUTING_FIX_20261023.md)和`audit/routing_followup_20261022/FINAL.json`。下方10月22日记录为历史；release/latest仍为10月20日旧基线。'+s[b:]
s=s.replace('> 2026-10-22本轮结论：','> 历史记录（2026-10-22）：')
if r['status']=='PASS':
    s=s.replace('当前FS仍是旧基线，未烧录。','旧归档FS为10月20日基线；当前新FS和实现结果以上方最新结论为准，未烧录。')
    s=s.replace('新版32键屏幕及指导模式正在做本轮集成验证。现有FS仍是旧版16键显示的已验证基线。','新版32键屏幕及指导模式已完成本轮数字实现及五类STA，仍待上板确认。新FS在`impl/pnr/ao_0.fs`，`release/latest`仍是原16键显示旧基线。')
    s=s.replace('当前 `impl/pnr/` 仅保留本轮对应源码的失败实现报告，没有新FS或完整STA。','当前 `impl/pnr/` 已包含10月23日新源码对应的FS和完整STA。')
    s=s.replace('新源码集成队友32键画面及真实状态，正在完成本轮时序验证；现有FS仍为原16键画面','新FS集成队友32键画面及真实状态，完整实现及五类STA通过，未上板确认')
    s=s.replace('新源码接通手机选择、屏幕目标提示和实体错键/松键判定，待本轮最终实现及上板确认','新源码接通手机选择、屏幕目标提示和实体错键/松键判定，数字实现已通过，仍待上板确认')
    s=s.replace('本轮**Placement 3 / Route 0**、Timing Driven和Hold修复开启、宽RAM拆分关闭的配置仍报PR0004，不能视为可通过的推荐设置。','10月23日的新源码已经完整实现；具体通过配置见本轮FINAL.json，不复用10月22日PR0004失败记录。')
readme.write_text(s,encoding='utf-8')
v4_details=''
if 'well_corner_0' in (D/'src/display/visual_scene.sv').read_text():
    v4_details='- 固定圆角的几何和查表判定拆到已有13/14级；600,084组边界/圆角和512个像素一致，场景仍40拍。数字位选择限定0～4位，替代宽整数位移；655,360组数字/去零比较及90区域2,912个像素一致，标签仍21拍。\n'
v5_details=''
if 'module visual_texture_address' in (D/'src/display/visual_background.sv').read_text():
    v5_details='- 按真实布线STA改写背景地址的行/列商余数合成，保留背景6拍及原始ROM纹素；8分区全部纹素和16,000次插值采样一致。\n'
if 'set_min_delay ' in (D/'src/integrated.sdc').read_text():
    v5_details+='- 对同像素时钟的显示存储写入路径加严最小延迟，原0.150ns Hold不确定度及其他时钟约束保留。具体值见当前integrated.sdc；独立检查核对Active约束和实际路径。\n'
v6_details=''
if 'static_character_q' in (D/'src/display/visual_labels.sv').read_text():
    v6_details+='- V6按真实STA将固定文字查找前移到已有属性寄存器拍；32键标签提前选择一个7位音高。11,560拍、90区域、全部32键索引与V5像素/字符/音高一致，标签仍21拍。\n'
if 'SCAN preparation clock uses the final registered peak bin' in (D/'src/display/visual_renderer.sv').read_text():
    v6_details+='- V6将频谱峰值比较与Hz换算分到已有COPY末拍和SCAN准备拍，并提前计算两个范围候选。12次FFT快照、6,144根频谱柱及发布握手一致；未增加扫描周期，Hz在发布前的准备拍更新。\n'
if 'V6_CHANGE.json' in proofs['proof_sha256'] and 'protected_voice_bitmap' not in (D/'src/display/visual_scene.sv').read_text():
    v6_details+='- V6显示延迟链改用寄存器，针对实际分布式RAM写入Hold短路径；保留渐变位置的10位寄存器。撤回V5无效的额外0.300ns最小延迟约束，SDC恢复原基线，0.150ns Hold不确定度和原时钟关系保留。具体资源及是否收敛以下方整机报告为准。\n'
v7_details=''
if 'protected_voice_bitmap' in (D/'src/display/visual_scene.sv').read_text():
    v7_details='- V7采用混合延迟存储：renderer保留寄存器保护，场景和标签其他长链恢复紧凑存储，场景声部状态位50～81单独使用寄存器。40级全部状态字段及512个像素与V6一致，仍40拍。V6全显示寄存器版曾因CLS达65,222/69,120和353条未布通被放弃，不能把它当成已通过版本。\n- V7坐标轴BCD提前到已有属性拍；11,560拍标签对照通过，仍21拍。XY清屏终止提前一拍预测，131,222拍控制/地址对照和两次65,536地址完整清屏、复位重启通过，清屏和COPY周期不变。\n- SDC恢复原基线，保留0.150ns Hold不确定度；没有降低时钟频率或豁免新增数据路径。键名小表与原电路映射相同、并行字符选择树映射更差，两项候选均未采用。\n'
report=f'''# 2026-10-23布线修复

结论：**{final['status']}**。主工程仍为`D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`，未烧录、未推送。源码、网表和本候选实现产物均已核对哈希并放回主目录。候选`{o.tag}`；旧实现备份`{B.relative_to(R).as_posix()}`。

## 修改和验收

- 显示琴键光效原长路径的减法前移到已有前一级，比较使用有效范围内8位数。画面、颜色和40拍流水不变，512组场景像素及14,880组有效距离算术一致。
- 依照第一版315块RAM整机综合指出的长路径，再将波形绝对值/符号恢复改为保留分组边界的前缀逻辑，面板/13与/5拆到已有两拍。全部2048和1024个除法输入、131072个16位符号恢复和131126个27位取负案例通过；场景512像素一致；renderer除两条表达式及组合助手外的顺序结构按字节核对，总延迟不变。
- 辅助音色吉他延迟线的低18位各自存储，两声部高6位使用一块2048x9真双口RAM的独立半区。不减24位精度、不加周期、不减少32个逻辑声部。独立综合每对由4块变3块；逐拍KS对照19,083周期通过；32声部四音色整库24,672周期PCM/控制/显示音符一致；实际三BSRAM网表6,826次读对照通过。
- 字形查找将233项宽比较表改为4096x8同步索引和256x41描述符，保留完整24位键比对以拒绝散列冲突。原覆盖图不变，655,360个键和90区域2,912个像素/字符一致；标签仍为21拍。新增两个HEX文件在assets内；单模块综合105.848MHz仅作诊断，不代表整机时序。
- HDMI复位前两级寄存器补齐PTR3附近位置约束；没有改管脚、时钟频率、相位或增加时序豁免。该约束的小型诊断通过，但V1整机网表的对照仍420条未布通，不能单凭它宣称已解决布线。
{v4_details}{v5_details}{v6_details}{v7_details}- 物理钢琴源、音符事件、音源ROM参数、FFT、HDMI串行输出和时钟RTL、双DAC、GAO配置与手机UI文件保持本轮开始时的哈希；声部数不变。没有仅凭非零PCM判断音质。
- 两组原网表控制与被停止的中间综合均保留收据；人工停止不计为工具实现失败。内存达到93%时停止过渡综合，之后最多两组大构建。

## 实际结果

综合资源原始数据：`{json.dumps(resources)}`。

实际布局资源与剩余：`{json.dumps(physical_resources)}`。

实现状态：`{r['status']}`；错误：`{r['errors']}`。

五类STA最差裕量(ns)：`{json.dumps(r['worst_slack_ns'])}`；Setup/Hold违例端点：`{json.dumps(r['violated_endpoints'])}`。空表表示没有新报告，不是0违例。PR0004即使计数0仍视为失败。

实际完整输入、网表、FS和报告SHA256及运行选项见`audit/routing_followup_20261022/FINAL.json`，原始日志见`audit/autonomous_timing_20261022_154006/runs/{o.tag}/`。`release/latest`没有更新，不能把旧基线当作新版本。

小型P16真实管脚时钟诊断和加入相同GAO配置的计数器诊断只用于定位，不替代整机。第一份小型诊断漏提取额外空格管脚行的问题已纠正；见`DIAGNOSTIC_CORRECTION.json`。00:07至08:00的系统待机中断不算持续计算时间，见PROGRESS.md。
'''
(R/'docs/ROUTING_FIX_20261023.md').write_text(report,encoding='utf-8')
print(json.dumps({k:final[k] for k in ['status','candidate','worst_slack_ns','violated_endpoints','synthesis_resources','backup']},indent=2))
