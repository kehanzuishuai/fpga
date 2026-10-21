# 高云工程手动接手

历史记录：下文为2026-10-20 17:45停止自动布线时的状态。用户后来明确取消交接，当前已复用同一综合网表，以Placement 3 / Route 0于21:53完成布局布线和五类时序检查，最终归档校验PASS。最新结果请读[最终验证报告](REMOTE_MUSIC_RESULTS_20261019.md)和 `audit/remote_music_20261019/FINAL_ACCEPTANCE.json`。没有自动烧录。

## 打开的工程

`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

主模块为 `tang_mega_138k_pro_top`，器件为 `GW5AST-LV138FPG676AC1/I0`，版本 C。工程有91个有效输入，测试平台没有参与综合。

## 已完成

- 完整综合通过；当前综合网表生成时间为2026-10-20 16:26。
- 网表：`impl/gwsynthesis/yinyue_fashengqi.vg`。
- 网表SHA256：`6ceb8babb23d570ae4b1dcc3744f1ba806b5fcecae836f9a79160de1ed6d6c41`。
- 综合报告：`impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html`。
- 实际综合网表32音Loader核对通过，12,800个参数字与模型一致，零差异。
- 本轮只补做XY峰值流水及SPI状态CRC短检查，均通过；其余结果按依赖哈希复用，未重复完整显示回归。
- 实体32键保持原钢琴音色，手机五音色用于MIDI/JSON曲谱；保留原16键屏幕对应、FFT、HDMI、双DAC。
- ESP32网页包维持恢复后的原版，SHA256为 `5428444eaa7aad9c41b0537b720fe516ef80e1186605d6154d6dbf38bfe253cf`。

## 尚未完成

最新RTL没有通过完整布局布线及五类时序验收，不能认为已经产生可用的新FS。

第一次实现于16:43收尾报 `PR0004`，虽然工具同时显示0个未布通网络，但没有生成新的FS和时序报告。随后仅把路由算法2改为1、复用同一综合网表重试；该轮在路由优化阶段按用户要求停止。

根目录 `impl/pnr/ao_0.fs` 和 `impl/pnr/yinyue_fashengqi.tr` 仍为此前版本，不能用来证明当前综合网表已通过。旧报告最差Setup为−0.554ns、Hold为−0.046ns，属于这次两处流水修复之前的实现。当前构建状态见 `audit/remote_music_20261019/BUILD.json`，明确标记为 `STOPPED_PER_USER`。

## 手动操作

1. 打开上述GPRJ，核对器件、主模块、有效源文件和约束文件。
2. 当前综合网表已经存在。源文件及综合选项不变时可直接运行布局布线；若更改RTL或综合选项，应重新综合。
3. 当前保存的布局策略为4、路由策略为1，Timing Driven和Hold修复已开启。算法1本轮耗时较长；更换策略是工具实现选项，不能保证一次通过或缩短至几分钟。
4. 布局布线成功后查看新生成的Setup、Hold、Recovery、Removal及最小脉宽报告。Setup/Hold违例端点应为0，其余各类裕量也应非负。
5. 核对FS和时序报告确实为本次生成，再决定手动下载。保留原时钟频率、视频复位相位及0.150ns像素Hold要求，不用放宽约束代替修复。

手动点击启动仍会执行同样的布局和路由计算。点击过程简单，计算时间取决于器件资源、布局、连线和时序目标。

## 记录

- 针对性验证：`audit/remote_music_20261019/TARGETED_VALIDATION.json`。
- 当前综合网表结构：`audit/remote_music_20261019/CURRENT_SYN_STRUCTURE.json`。
- 最新完整综合及失败实现归档：`audit/remote_music_20261019/routing_zero_unrouted_abort/`。
- 停止的路由重试日志：`tests/remote_music_20261019/out/retime.log`。
- XY峰值及SPI状态CRC修复前的路径报告：`audit/remote_music_20261019/routed_setup_negative_0554/`。

真实接线、Wi-Fi连续播放及主观音质仍需上板确认；本轮没有烧录。
