# 开发与验证

## 目录

| 路径 | 内容 |
|---|---|
| `src/`、`assets/` | FPGA RTL、IP、约束和初始化数据 |
| `firmware/remote_music_ble/` | 当前 ESP32 程序与手机网页 |
| `firmware/theremin/` | 当前 UNO 特雷门琴程序、来源与许可证 |
| `scripts/` | 当前构建、完整性校验与顶层展开入口 |
| `sim/models/` | 必要的 ROM、PLL 与视频边界仿真模型 |
| `tests/` | 手机与整曲传输回归、输入夹具 |
| `scores/` | 可导入的示例曲谱与生成器输入 |
| `release/v21_20261103/` | 当前固件、正式报告和可核对的验收记录 |

当前高云工程仅列出启用的 104 个依赖，器件、启用项及其顺序与已验收版本一致。RTL、初始化数据和固件未因目录整理而修改。`src/` 中保留的兼容模块属于同一份验收源码快照。

## 快速检查

```shell
python scripts/verify_current_release.py
node tests/phone_play_confirmation.js
node tests/phone_stream_dom.js
node tests/phone_timeline.js
```

完整性校验涵盖源文件哈希、启用工程依赖、ROM 数据、网页内嵌资源、发布文件和 FPGA ZIP 内部 FS。手机回归检查播放确认、空曲谱提示、MIDI 全轨导入、整曲传输及指导分段。

安装 Icarus Verilog 和 Gowin 后可执行完整顶层展开：

```shell
python scripts/elaborate_current_fpga.py --iverilog iverilog --prim-lib "本机Gowin目录/IDE/simlib/gw5a/prim_sim.v"
```

该检查使用配套 ROM/PLL/视频边界模型，并保留完整音频与显示逻辑。它不替代 Gowin 综合、布局布线和静态时序分析。

## 整曲传输回归

先创建 `build/` 输出目录，再运行：

```shell
g++ -std=c++11 -Ifirmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller tests/current/check_canon_stream.cpp -o build/check_canon_stream
build/check_canon_stream tests/current/canon_timeline.txt 4286
iverilog -g2012 -s tb_canon_stream -o build/canon.vvp tests/current/tb_canon_stream.sv src/remote/control/wifi_control.sv
vvp build/canon.vvp
```

Windows 下编译输出程序可能带 `.exe` 后缀。测试逐事件核对整首《卡农》的起音、松音、FIFO 回绕、供谱及下游等待，检查播放结束后全部松音。

## 历史与复现

当前目录聚焦可构建的工程、示例和必要验证。旧版本固件、实验副本及大批测试输出可从 [整理前的提交](https://github.com/kehanzuishuai/fpga/tree/b1b18e1d488687f72f4ba7c5fe08f70ee4ceb0f3) 查阅；Git 历史保留。

发布目录中 `*_ORIGINAL.json` 为原始构建快照，保留当时的工具和本机路径。当前交付关系以 `RELEASE.json` 和 `SOURCE_MANIFEST.json` 为准。修改 RTL、约束或初始化数据后，需重新完成实现和时序检查；仅通过哈希与仿真不能证明实板音质、校准或端到端延迟。
