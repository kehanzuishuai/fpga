# 2026-10-22自主时序迭代记录

当前结论：**NOT_TIMING_CLOSED_NOT_PROGRAMMED**。主工程仍为`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`，本轮未烧录。

主目录采用候选：`pll_bypass_p3_r0`。源码、综合网表、实现报告已对应；原主目录的旧网表、旧FS和旧STA均保存在`audit/autonomous_timing_20261022_154006/root_before_promote_pll_bypass_p3_r0`。`release/latest`仍为10月20日旧基线，不代表新显示工程。

本轮实际可运行时间约157.3分钟；系统多次现代待机累计315.2分钟不计入计算窗口，见`audit/autonomous_timing_20261022_154006/SYSTEM_SLEEP.json`。

## 实际实现结果

| 候选 | 结果 | 工具错误 |
|---|---|---|
| clock_first_p3_r2 | STOPPED_FOR_TIMEBOX | — |
| dcs_global_p3_r0 | IMPLEMENTATION_FAILED | ERROR  (PR0004) : There are total 567 unrouted nets |
| dcs_global_p3_r1_inc | STOPPED_FOR_TIMEBOX | — |
| dcs_global_p3_r2 | STOPPED_FOR_TIMEBOX | — |
| dcs_global_p4_r1 | STOPPED_FOR_MEMORY_PRESSURE | — |
| pll_bypass_p3_r0 | IMPLEMENTATION_FAILED | ERROR  (PR0004) : There are total 0 unrouted nets |
| pll_compact_p3_r0_inc | IMPLEMENTATION_FAILED | ERROR  (PR0004) : There are total 595 unrouted nets |
| pll_diagnostic_p3_r0_inc | IMPLEMENTATION_FAILED | ERROR  (PR0004) : There are total 0 unrouted nets |

最终候选五类STA裕量(ns)：`{}`；Setup/Hold违例端点：`{}`。空表表示未取得本候选STA，绝不表示0违例。PR0004即使显示0条未布通也仍是实现失败。

完整输入、网表与产物SHA256见`audit/autonomous_timing_20261022_154006/FINAL.json`。原始日志、Tcl和报告保留在各候选`runs/`目录。诊断版若关闭自动时序优化/Hold修补，SDC及五类STA验收仍保持，不能把关闭修补当作通过。

## 功能与专项验证

- 保留32 Voice实体钢琴、FFT、HDMI、双DAC、ESP32接口和既有UI；未改音源、声部分配、ROM、按键事件与音色算法。
- PLL输入旁路真实原语1000周期及整板展开通过；只改旁路选择和内部端口，不改音频PLL输出0的分频、相位与VCO设置。
- 文字减负候选先选当前标签音高，仍为21拍；原90区域、2912动态像素/字符及全部65536个BCD输入等价检查通过。综合SSRAM445→390，逻辑减少330，寄存器增加224。但该候选实际仍有595条未布通，本轮未采用到最终主目录；完整源码及验证证据保留在`runs/pll_compact_p3_r0_inc/`。它只改显示数据，没有改32 Voice音频路径。
- PLL基础版键盘至双DAC专项通过，单键数字链路约4.7ms；32键齐按最后声部约10.97ms。触摸模块内部检测、模拟DAC及扬声器延迟不在该数字仿真内。
- 手机网页SHA256保持`3969c34b4d279eae7e16e1066441730b026b021e04ecf8e4ed52bece4bc719c1`。文字音高选择只影响当前像素的标签数据，不减少同时发声或显示的键数。

## 继续工作

先阅读本文件和FINAL.json，再核对本候选新的实现结果。只有布线完成、最新STA五类裕量非负且Setup/Hold端点为0，并核对所有时钟定义，才能称为新工程通过。若尚未闭合，应继续定位PR0004、时钟分配及高密度布局；本轮不以小工程通过替代整机结果。

最后的低占用诊断工程保留三组真实PLL、HDMI串行器、相同相关管脚及reset/DCS位置约束，完成了实现并生成自己的STA/FS；不包含完整音源、显示逻辑或GAO，不能作为整机通过证据。说明基本时钟拓扑在低负载时可以实现，但尚不能区分整机密度、GAO或其他资源交互的影响。另外，保持SDC、关闭自动Timing Driven/Hold修补的整机诊断版仍报PR0004且计数0，未定位出该错误的确定根因。

## 后续复核：小型诊断管脚更正

前述`clock_topology_probe`的约束提取遗漏额外空格，实际时钟为未约束P4，不能支撑P16板级结论。后续已修正解析，逐项核对10个端口在实际报告中的位置及约束标记；`clock_topology_p16_verified`真实采用P16/K16及相同相关输出管脚，完成实现并生成自己的STA/FS。仅为小型诊断，整机结论仍是未通过。详见`audit/routing_followup_20261022/DIAGNOSTIC_CORRECTION.json`。
