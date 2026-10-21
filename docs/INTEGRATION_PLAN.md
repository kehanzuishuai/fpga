# INTEGRATION_PLAN

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.254686+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

数字验证：**PASS**。实物功能验收：**PENDING**。

本轮修复测试平台跨复位半帧残留，增加真实事件链GAO诊断，对齐GUI/CLI过程选项，并针对已复现的视频串行器复位恢复负裕量增加逐通道局部复位。未修改AMY参数、ROM、Loader算法、Partial算法、Allocator调度、增益或FX算法。raw bit0..15→MIDI60..75是上一轮已存在的映射，本轮保留；实体键位与实物协议仍未确认。

最后四个实体键无声：当前协议模型下未复现，不能报告实物故障已修复。原照片只证明mapper状态和组合MIDI曾显示，不能确定Note On已被FIFO接受或声音已启动；照片中的旧表MIDI为67/71/75，不能混作当前73/74/75。

本轮记录 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\VALIDATION.json` 为唯一当前汇总；`audit/audio_diagnosis`、`tests/audio_diagnosis` 内既有记录是历史基线，不能替代本轮结果。原docs已备份到 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\backup\docs`。

本轮执行顺序：只读路径/哈希与实物证据确认 → 当前工程内备份 → 原PCM FATAL分类与A/B → 保留原检查并补齐逐键观测 → 真实GAO计数接入 → 键盘/背压/双DAC/显示/完整钢琴/固定力度音色回归 → 相关仿真通过后单次Gowin实现 → 哈希、时序与管脚门禁 → 用户最小上板测量。

GUI原打开值与CLI的差异为语言标准、显式顶层和文本时序报告。本轮新建当前impl下最小process_config，仅设置这些必要值及CST警告升级；再由Gowin saveto -all_options分别导出GUI_ON_OPEN.tcl和CLI_EFFECTIVE.tcl，验证选项相同。没有复制旧工程整份生成配置，不更改Bank电压/下载配置。生产gprj仍使用原相对文件路径，新增RTL诊断在已入工程模块中直接实现，未并列加入冲突版本。

第一次实现通过后，复核发现FIFO写入On/Off计数尚未加入GAO捕获清单，因此补探针和实际接受点默认触发，作必要的第二次实现；该次报告三条OSER10复位恢复负裕量，最差-0.469ns，判FAIL。随后压缩新增计数探针到低8位，第三次仍有一条恢复-0.020ns。详细路径显示共享像素复位源到三个串行器的布线延迟达3.57..4.00ns，挤占4ns恢复关系；因此增加三个受保留的局部复位寄存器，缩小每个复位源扇出到一个串行器，相关专门仿真通过后进行第四次实现。声音RTL、管脚、时钟和SDC不变。前三次产物分别保存在audit/continuation_20261017/build_attempt1、build_attempt2、build_attempt3；最终以BUILD.json和当前Gowin日志为准。基线与本轮均出现tck_pad_i自动时钟及clk_50m_d普通布线警告，完整保留，不通过删除约束掩盖；以最终实际时序及最小脉宽报告判断数字实现门禁，物理接口仍需硬件验证。

待真实板上确认：实体1..16到raw位序；BIT-TREE芯片/选件及SDO整帧；正常键与异常键GAO握手差值；板载模拟输出与同MIDI数字PCM的对照。若计数链全部前进而模拟仍无声，再测板载DAC串行/耳放/负载。只有硬件证据定位后才针对相关级修改；音色算法变更须先局部A/B与资源评估。

数字检查若仍有NOT_RUN/RUNNING/FAIL，继续对应日志中的实际命令，不把历史PASS当作当前结果。硬件验收未完成前保持MAP=0，不发布“实物全修复”结论，不自动下载。

