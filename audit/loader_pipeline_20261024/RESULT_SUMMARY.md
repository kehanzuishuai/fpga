# 音符装载器流水化（32 键延迟，用户 2026-10-24 批准方案 A）

分支：branches/loader_pipe_20261024（v12 的副本 + 本改动），根目录未改。工具：tools/loader_pipeline_20261024.py（幂等，断言原文；第二次运行 unchanged）。
改动：src/piano_note_loader.v 只换了状态定义、ROM 地址选择和时序器；插值算术（pitch_weight、lo_w/hi_w、level_out、ratio_w）原样保留。
- 电平 ROM 每拍读一个字（ptr0..ptr3 轮流），4 拍一个包络点（原来 7 拍）；读出后一拍做音高插值，再一拍做力度插值并写入。
- 每个分音槽的频率字和 4 个槽头字由一个小时序器并行算出，在电平写口空闲的拍写入。
- 声部在写地址 0（槽 0 的 W_INC）时清空可闻记录 future_audible，之后累积各包络点：新装载器在 S_RUN 第 4 拍写地址 0，第 6 拍才写第一个包络点，记录结果与原来一致（下面的测试逐项比较了这个记录）。
- 不增加 BSRAM，不改写入的任何数据，只改顺序和用时。

## 等效验证（audit/loader_pipeline_20261024/verification）
新旧装载器各自按自己的节奏接收同一串请求（busy 降下后才给下一个，与音符 FIFO 相同）：前 77 个是音高 0/23/24/25/104/105/127 × 力度 0/39/40/41/79/80/81/119/120/121/127 的边界组合，其后随机；每个请求随机等待 0..63 拍的声部淡出（voice_ready）和 0..3 拍间隔。每次 ld_done 时记录：声部号、ld_rel_slope、按声部规则累积的 future_audible、该声部 16×25 个 RAM 字（请求时先置 X，漏写会显出 X）。
- 快速 ROM 模型（sim/models/piano_roms_fast.v，同内容、同 1 拍读延迟）600 次装载：两份记录逐行相同，0 个 X，写地址 0 之前的包络点写入 0 次。old: loads 600 max 2546 mean 2514 clocks request->done, bp_before_clear 0；new: loads 600 max 1414 mean 1382 clocks request->done, bp_before_clear 0。
- 真实 ROM（src/piano_*_rom.v）40 次装载：同样逐行相同、0 个 X。old: loads 40 max 2545 mean 2515 clocks request->done, bp_before_clear 0；new: loads 40 max 1413 mean 1383 clocks request->done, bp_before_clear 0。
- 第一次运行因测试台把"新请求清空 RAM 镜像"放在"记录上一次 done"之前而失败（两份记录仍逐行相同，但同一声部连续请求时出现 X），保留在 *_tb_order_bug；修正顺序后重跑通过。

## 整机数字延迟（audit/loader_pipeline_20261024/system，与 docs/KEYBOARD_LATENCY_20261021.md 同一测试台和模型）
| 场景 | v12 PCM5102 首帧 ms | 新 PCM5102 首帧 ms | v12 最后声部 ms | 新 最后声部 ms |
| --- | --- | --- | --- | --- |
| K1 单键，空闲期变化 | 4.681 | 4.577 | 4.629 | **4.525** |
| K32 单键，刚错过帧锁存 | 4.747 | 4.664 | 4.695 | **4.611** |
| K1+K32 | 4.747 | 4.664 | 4.903 | **4.715** |
| 全 32 键齐按 | 4.747 | 4.664 | 10.965 | **8.028** |

32 键齐按最后一个声部从 10.965 ms 降到 8.028 ms，满足 ≤10 ms。单键首帧也提前约 0.1 ms。触摸模块内部检测、DAC 模拟和扬声器延迟不在该数字仿真内（与原测试相同）。
另：原测试台缺全局复位单元（辅音色的打包 KS 存储用了高云原语，会引用 GSR.GSRO），本目录的 run_latency.py 在顶层包了一个 GSR（GSRI=1，不复位）。

## 构建
待整机构建（笔记本一次只跑一个高云进程；Astra 的 astra_p3_r0 正在构建）。
