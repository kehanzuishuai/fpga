# 音色参考与实现范围

阅读日期：2026-10-14。以下来源用于算法研究和架构借鉴。本包没有把外部仓库 RTL 或 C/C++ 整份复制进工程。

| 音色 | 来源 | 具体内容 |
|---|---|---|
| 钢琴 | https://github.com/shorepine/amy/blob/main/src/interp_partials.c | 已有 src 的 AMY-style 分音与参数加载，保持原实现 |
| 管风琴 | https://github.com/emard/synthowheel/blob/master/synth.vhd | 九音栓与权重合成思路；本包使用独立权重和运行时选择接口 |
| 管风琴 / 长笛 | https://github.com/electronics-club-iitm/vibeboard/blob/main/sources_1/new/preset_rom.v | 音色表、增益和 ADSR 配置思路，不照搬原 50 MHz 的时间参数实现 |
| 简化长笛 | https://github.com/thestk/stk/blob/master/include/Flute.h | 呼吸包络、气流噪声、颤音的思路；本包没有其管道延迟及非线性喷流模型 |
| 木吉他 | https://github.com/htfab/ks-guitar/blob/main/verilog/rtl/ks_string.v | 噪声激励、延迟、反馈、调音构成闭环的结构 |
| 木吉他 | https://github.com/shorepine/amy/blob/main/src/oscillators.c | render_ks 的环形延迟、两抽头平均、全通小数延迟调音；改写为同步 RAM 状态机 |
| FM 钟琴 | https://github.com/thestk/stk/blob/master/src/TubeBell.cpp | 非整数频率比、独立衰减；本包只实现一对简化算子 |
| FM 钟琴 | https://github.com/russell-merrick/fpga-synth/blob/master/src/voice.v | 调制器输出加到载波相位的硬件组织；本包扩展非整数比并使用自己的包络 |

控制层和整体组织补充阅读：

- https://github.com/KrasForge/Courant/blob/main/src/rtl/panel_ctrl.vhd
- https://github.com/KrasForge/Courant/blob/main/src/rtl/preset_bank.vhd
- https://github.com/kazunori279/xls32-fpga-synth/blob/main/core/synth.x

本包不引入 JTOPL/JT51/完整 OPL3 或 DX7，不依赖 CPU、Wishbone、AXI 或软件实时音源。
若后续直接复制第三方代码，应逐文件保留其许可证、来源及版权声明；本次来源记录不构成对第三方许可证的替代。
