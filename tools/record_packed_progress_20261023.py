from pathlib import Path
import json,datetime,xml.etree.ElementTree as ET,shutil
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022';old=R/'audit/autonomous_timing_20261022_154006'
p=old/'runs/followup_key_lip_syn/RESULT.json';j=json.loads(p.read_text())
j.update(status='STOPPED_FOR_MEMORY_AND_SUPERSEDED',reason='Own PID4208 stopped at93% physical memory; scene-only revision superseded by combined validated KS memory packing plus pixel-path revision. Not a completed synthesis error.')
p.write_text(json.dumps(j,indent=2))
user=R/'yinyue_fashengqi.gprj.user';backup=A/'gprj_user_before_pending.xml'
if user.exists() and not backup.exists():
    shutil.copy2(user,backup);tree=ET.parse(user)
    for e in tree.findall('./FlowState/Process'):
        if e.get('ID') in ['Synthesis','Pnr']:e.set('State','0')
    tree.write(user,encoding='utf-8',xml_declaration=True)
p=R/'README.md';s=p.read_text(encoding='utf-8');a=s.index('> 后续修复进行中：');b=s.index('\n\n',a)
s=s[:a]+'> 后续修复进行中（2026-10-23）：当前源码已加入像素边缘运算等价改写和吉他延迟线24位无损存储重排，正在做必要验证；尚待新的整机综合与实现。`impl/`仍属于上轮PLL候选，不能当作当前源码的通过证据；工程缓存已将综合/实现标为待运行。并行隔离快照的原网表布局/布线仍在进行。记录见`audit/routing_followup_20261022/`。不烧录。'+s[b:]
p.write_text(s,encoding='utf-8')
(A/'PROGRESS.md').write_text('''# 2026-10-23 布线修复继续记录

用户要求继续解决布线失败。本轮无固定截止时间，不烧录、不改UI、不减32 Voice/FFT/HDMI/双DAC/GAO。

当前主目录新增4份RTL修改：visual_scene.sv的琴键边缘减法前移一拍（总40拍不变），以及yinse_ks_loop.sv、yinse_aux_voice.sv、yinse_aux_bank.sv的无损RAM配对。旧impl仍为上一轮PLL候选，源码已更新，不能混用旧网表宣告通过。

已确认：P16/K16小型真实时钟测试完成；加入相同GAO配置的计数器诊断也完成布线。原第一份诊断漏掉IO_LOC额外空格，实际时钟P4，该证据已纠正。小型结果不能代替整机。

像素改写：512组改动前后场景像素完全一致；14,880组有效距离算术一致；40拍不变。大样本含字符的旧脚本和8192场景脚本超时，不计为PASS，不复用旧测试日志。

RAM配对：每个1024x24单端口延迟线的低18位独立存储；两条线的高6位分别使用同一2048x9真双口块的两个不重叠半区。无仲裁、无精度降低、无额外周期。真实Gowin原语仿真与修改前KS RTL逐拍19,083周期一致。独立综合确认每对3块BSRAM，原每对4块，预期32声部释放16块，预计整机331→315；整机资源以之后新综合实测为准。32声部整库对照仍在运行，收据位于packed_ks/bank_verification/RESULT.json；不存在收据时不能声称通过全部音色。

followup_key_lip_syn中间综合被主动停止：93%内存，且已被光效+RAM减负组合版本替代。保留STOPPED_FOR_MEMORY_AND_SUPERSEDED记录，不算工具综合失败。

两个原网表PnR控制：audit/autonomous_timing_20261022_154006/runs/followup_pll_p0_r0 与 followup_pll_p3_r1_inc。08:15都已进入详细布线；尚无新整机STA。无效LOCAL_CLOCK约束实验因CT1018明确不支持已停止，未采用。新组合版整机综合/布线需待资源空闲启动，避免超过两组大任务。

00:07系统进入待机/休眠，08:00恢复，中间不计工程计算。原Python防待机请求未阻止Screen Off Request。08:01建立C#临时线程级系统+显示请求，期限两小时；PID在awake_csharp_pid.txt，exec38113。不改变电源方案，完成后结束此PID或等待自然退出；不要杀其他进程。powercfg /requests需要管理员，当前令牌只获得沙箱外执行，未取得管理员，读取失败，不声称已验证系统接受请求。

后续先收集两组PnR结果，再运行组合版完整综合/布局布线/STA。只有新的五类裕量非负、Setup/Hold端点0、时钟频率和实际IO位置均核对，才称整机通过。release/latest保留旧基线，不改写、不烧录。
''',encoding='utf-8')
print('Recorded pending production cache, new source/old netlist distinction and scoped verification evidence.')
