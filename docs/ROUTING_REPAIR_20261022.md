# 2026-10-22 未布通与显示移位存储修复

> 后续用户于14:33重新手动实现，未布通计数降到0、CLS降到63396/69120，但仍以错误退出，尚无新最终STA。最新CST/SDC修改及接手说明见 [CLOCK_CONSTRAINT_REPAIR_20261022.md](CLOCK_CONSTRAINT_REPAIR_20261022.md)。本文保留上一轮存储修改的历史。

主工程仍为 `D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`。

## 本次实际失败

用户手动实现于13:28结束，报 `PR0004: There are total 420 unrouted nets`。当前首先是布线未完成，不能认定已经产生本轮完整STA。工作目录的详细 `.tr.html`、`.timing_paths` 和FS仍为2026-10-20旧文件；不可用它们签核新显示。

失败运行使用的网表与 `SYN_TEXT_SUM_FINAL.json` 的哈希相同。配置为Place 3、Route 0，Timing Driven和Hold修复开启，宽RAM拆分关闭；本轮保持用户这些设置。失败报告及当时源码备份在 `audit/routing_repair_20261022/before/`，诊断收据为 `MANUAL_RUN_FAILURE.json`。

| 失败运行的实际资源 | 已用/总量 | 剩余 |
| --- | --- | --- |
| 逻辑 | 114420/138240 | 23820，约17% |
| 寄存器 | 62585/139140 | 76555，约55% |
| CLS | 65721/69120 | 3399，约5% |
| BSRAM | 331/340 | 9，约3% |
| DSP | 259/298 | 39，约13% |

虽然寄存器总量仍有空位，但逻辑、寄存器及其控制信号需要配合装入CLS，实际CLS占用已经接近满载；不能只凭寄存器百分比判断好布线。高CLS/BRAM占用是当前布线压力的重要风险，但420条网络是否因此全部解决，必须由新一次实际实现确认。

上次综合的331块BSRAM按顶层模块分解为：钢琴音源185块、显示/FFT114块、WAV11块、GAO在线逻辑分析仪21块，合计331。每个钢琴声部包含15个分音及hammer槽的参数、状态和查表，32声部本身占用较多运算/存储；显示还包含背景、字体和分析帧缓存。模块明细保存在 `audit/routing_repair_20261022/PREVIOUS_SYNTHESIS_MODULE_RESOURCES.json`。本轮未关闭既有GAO调试功能。

## 修改内容

仅将以下三个模块的 `syn_srlstyle="registers"` 改为 `syn_srlstyle="distributed_ram"`：

- `src/display/visual_scene.sv`
- `src/display/visual_renderer.sv`
- `src/display/visual_labels.sv`

对应三个 `tools/pipeline_display_*` / `align_display_scene_pipeline_20261021.py` 生成器同步修改。长移位链由分布式SSRAM实现，属于Gowin SUG550-2.1E第5.17节明确支持的实现方式。不是改用BSRAM，也没有修改显示坐标、字体、颜色、算术、流水级数或像素延迟。手机页面与音频RTL不修改，保留32钢琴Voice、FFT、HDMI和双DAC。

这是用少量分布式逻辑存储替代大量独立触发器的取舍：SSRAM及逻辑占用可能上升，寄存器和相关布线数量下降。最终CLS和布线效果以用户下一次实现报告为准，不能仅凭综合寄存器数量保证已经布通。

## 验证与构建

`tests/display_integration_20261021/verify_shift_storage_change.py` 已核对三个源码：只归一化上述存储属性后，功能代码与修改前完全相同；原2048组RGB/DE/HS/VS对照仿真的全部依赖也逐项核对。证据为 `out/SHIFT_STORAGE_EQUIVALENCE.json`。原像素仿真收据保留原哈希，没有改写成“本轮重新仿真通过”，也没有重复整帧HDMI回归。

当前工程展开及快速状态/CDC检查通过。正式完整显示核心包含光栅、真实存储、FFT、CDC、实际PLL/DCS/OSER10和TMDS，综合寄存器由20954降到7419，减少13535个；BSRAM保持114，像素预估81.521MHz。收据 `out/DISPLAY_CORE_TIMING_ESTIMATE.json` 同时记录当前源码与综合快照哈希，仅允许CRLF/LF换行格式差异。该结果不能代替整机或布线后STA。

两处属性的过渡综合在早期由本代理停止，以纳入字库延迟链额外4656个寄存器的释放；记录为 `SYN_DISTRIBUTED_SHIFT_FINAL.json`，没有作为交付网表。最终三处修改已冻结，整机综合于14:04完成，耗时约14分25秒，资源通过且源码没有漂移。记录为 `audit/display_integration_20261021/SYN_DISTRIBUTED_SHIFT_ALL.json`。

| 同阶段整机综合比较 | 修改前 | 修改后 |
| --- | --- | --- |
| 逻辑 | 113711 | 116423，增加2712 |
| 寄存器 | 62585 | 49161，减少13424 |
| BSRAM | 331 | 331 |
| 分布式SSRAM | 64 | 445 |
| DSP | 259 | 259 |
| 整机像素时钟预估 | 55.340MHz | 55.340MHz |

当前综合余量：逻辑21817/138240（约16%）、寄存器89979/139140（约65%）、BSRAM9/340（约3%）、DSP39/298（约13%）。**新的CLS占用尚无实际值，必须重新布局才能得到。** 不将显示核心减少13535寄存器直接当作整机值；整机实际减少13424。

整机像素预估没有提高，仍低于74.25MHz。此次修复的可验证结果是显著减少寄存器、改变长移位链的布线结构，不是已经解决所有时序违例。是否消除420条未布通网络、最终时序能否通过，需用新网表重新手动实现后判断。

本轮网表、报告、三份RTL与生成器、构建收据和功能等价证明归档在 `audit/routing_repair_20261022/final_synthesis/`。`RESULT.json` 记录余量及未执行新的布局布线/STA；集成主记录 `CURRENT.json` 为 `SYNTHESIS_PASSED_TIMING_REPAIR_REQUIRED`，明确保留像素预估不足的限制。旧FS和详细STA未改写。

## 手动接手

本轮整机综合已完成并确认源码/网表哈希一致。仍打开原GPRJ，从布局布线步骤完整重新运行。当前网表为 `impl/gwsynthesis/yinyue_fashengqi.vg`，与 `SYN_DISTRIBUTED_SHIFT_ALL.json` 哈希一致。不能复用失败运行的 `.p`/`.db` 当作新版本实现结果，也不能把旧FS当作本轮产物。

首先确认不再有未布通网络，再查看新生成的Setup、Hold、Recovery、Removal和Pulse Width报告。资源改善与时序通过分别确认。若仍失败，请以本轮新报告定位；不要放宽74.25MHz目标或用旧报告签核。

按用户再次明确选择，本代理不启动自动布局布线，也不烧录。实体键盘数字延迟的音频路径不变；单键低于5ms、32键最后声部约10.97ms的限制仍然存在，详见 `KEYBOARD_LATENCY_20261021.md`。
