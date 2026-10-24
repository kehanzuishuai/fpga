"""Record a finished experiment honestly, without promoting its failing FS."""
from pathlib import Path
import datetime,hashlib,json
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022'
tag='followup_hybrid_axis_clear_v5_hint';D=R/'audit/autonomous_timing_20261022_154006/runs'/tag
r=json.loads((D/'RESULT.json').read_text());check=json.loads((D/'STA_INSPECTION.json').read_text())
assert r['complete_implementation'] and r['status']=='ROUTED_TIMING_FAILED'
assert check['report_sha256']==r['artifacts']['yinyue_fashengqi.tr']['sha256']
rec=dict(tag=tag,status=r['status'],source_matches_current=True,elapsed_seconds=r['elapsed_seconds'],
 worst_slack_ns=r['worst_slack_ns'],violated_endpoints=r['violated_endpoints'],
 worst_path=dict(source='scene/STAGE_1.q_raw.pane_x_2_s0',destination='scene/STAGE_2.q_raw.halo_outer_geometry_10_s0',
 data_delay_ns=26.089,cell_ns=4.463,route_ns=21.244,clock_to_q_ns=.382,pixel_period_ns=13.468,
 route_fraction_percent=81.429,logic_levels=13),
 physical_resources=dict(logic=116852,logic_total=138240,cls=63882,cls_total=69120,bsram=317,bsram_total=340,dsp=252,dsp_total=298),
 next_action='Do not adopt old-position hint as timing improvement. Reduce per-pixel scene metadata and stage pane common centers; focused same-latency pixel checks before new synthesis.',
 scope='Actual fresh full route and STA; all12 clocks and27realIO pins independently checked. Setup/Hold still failing; no programming or release update.',programming=False)
(A/'HINT_ROUTED_DIAGNOSIS.json').write_text(json.dumps(rec,indent=2))
(A/'LATEST_COMPLETED_ROUTED.json').write_text(json.dumps(rec,indent=2))
live=json.loads((A/'LIVE.json').read_text());live['updated_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat()
live['runs'][0].update(status=r['status'],worst_slack_ns=r['worst_slack_ns'],violated_endpoints=r['violated_endpoints'])
live['awake']=dict(pid=20196,session=72939,started_local='2026-10-23 16:58:07',expires_local='2026-10-23 18:28:07')
live['next_steps']='V7hint completed route but WNS worsened; isolated same-pixel voice bitmap reduction plus pane preparation under test. New revision not applied to root yet.'
(A/'LIVE.json').write_text(json.dumps(live,indent=2))
with (A/'PROGRESS.md').open('a',encoding='utf-8') as f:f.write('''

16:55 实际完成 V7 + V5位置提示对照（2021.352秒）。全布线并生成新STA，独立校验12时钟、27真实管脚及原0.150ns hold uncertainty全部生效；Setup -12.768ns/536、Hold -0.439ns/53，仍失败。该结果没有提升时序，不能发布或烧录。

最差路径已变为STAGE1 pane_x到STAGE2光晕/面板圆角：26.089ns，其中单元4.463ns、布线21.244ns、C2Q0.382ns；像素周期13.468ns。布线单段出现6.266、5.648、3.835ns长绕线，逻辑在R11/R93/R48/R17/R94/R12之间往返。CLS63882/69120，报告多处routing congestion1.000，证明延时主要来自拥塞和位置分散，不能只看综合频率。

17:00 根据该证据准备新的显示局部候选：Voice32位状态先在STAGE0/1与当前像素匹配，改传shape/active两个标志；同拍圆角中心预处理、频谱mod7精简、完成计数ASCII前移。原物理32声部音源不改，不添加流水拍，不改UI。候选先独立验证，根工程此刻仍V7。新的临时90分钟运行请求PID20196，18:28到期；无永久电源策略改动。
''')
print(json.dumps(rec,indent=2))
