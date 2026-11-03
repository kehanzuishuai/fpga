# V21 三端完整发布 · 2026-11-03

配套版本：FPGA V21（2026-11-02）、ESP32 `v21-autoplay-confirm-20261103`、当前特雷门琴 UNO 桥接程序。根目录 GPRJ 和 `firmware/` 已同步为这些版本。

## 直接使用

| 文件 | 用途 |
|---|---|
| [FPGA_expression.fs.zip](FPGA_expression.fs.zip) | 解压后获得 FPGA_expression.fs，再由 Gowin Programmer 加载；GW5AST-LV138FPG676AC1/I0 |
| [ESP32_autoplay_0x0.bin](ESP32_autoplay_0x0.bin) | ESP32-S3 N32R16V、32MB OPI Flash / OPI PSRAM，完整镜像偏移 **0x0** |
| [Open_Theremin_FPGA.ino.hex](Open_Theremin_FPGA.ino.hex) | UNO 应用 HEX；标准串口上传推荐使用完整 Arduino 工程 |
| [Open_Theremin_FPGA.ino.with_bootloader.hex](Open_Theremin_FPGA.ino.with_bootloader.hex) | 包含引导器内容，供需要此镜像的 ISP 工作流使用 |
| [SHA256SUMS.txt](SHA256SUMS.txt) | 本发布目录所有交付文件的校验清单（不包含清单自身） |
| [SOURCE_MANIFEST.json](SOURCE_MANIFEST.json) | 仓库内三端源码、资源和关键验证脚本的 SHA256 |
| [RELEASE.json](RELEASE.json) | 本次组合发布的版本、产物与验收信息 |

FPGA FS SHA256：`ed1d070e1ec9839e63092b5c4ac5849ff91d11364080776861baf16dc860cf26`。

ESP32 合并 BIN SHA256：`51c2f450238fadc1d747c094e9fb5eaa775fcbe744b29b68219665ebcfa05841`。

FPGA 压缩包用于规避当前网络上传接口对大文本的限制；解压后的 FS 与原已验收文件逐字节相同。校验脚本同时验证 ZIP 和内部 FS 的 SHA256。

## 构建和核验依据

- [FPGA_BUILD.json](FPGA_BUILD.json)：当前 FPGA 构建信息；[实际时序报告](yinyue_fashengqi.tr)、[实际 PnR 资源报告](yinyue_fashengqi.rpt.txt) 和管脚报告一并提供。
- [ESP32_BUILD.json](ESP32_BUILD.json)：11 月 3 日编译记录，保存七个编译输入的哈希与二进制哈希；[ESP32_VALIDATION.json](ESP32_VALIDATION.json) 记录播放确认和网页检查。
- [THEREMIN_BUILD.json](THEREMIN_BUILD.json)：本次从 GitHub 发布副本重新编译的 UNO 程序、全部源文件和两个 HEX 的哈希。
- [verification/](verification/)：页面播放确认、真实页面导入/传输/播放/停止、ESP32 解析和 FPGA 整曲供谱的回归记录。
- `*_ORIGINAL.json` 是保留原值的历史构建快照，其中本机绝对路径、开始时的 ready 状态或旧配套 ESP32 哈希不定义本次组合发布；当前配套关系以 `RELEASE.json`、本页及根目录 README 为准。

FPGA 最差裕量：Setup +1.472 ns，Hold +0.001 ns，Recovery +8.464 ns，Removal +0.257 ns，最小脉宽 +2.893 ns；Setup/Hold 违规端点均为 0。关闭效果的 21,911 帧 PCM 与 V20 基线一致，开启效果的 21,913 帧通过合成链路仿真。

完整工程检查不连接设备：

```shell
python scripts/verify_current_release.py
node tests/phone_play_confirmation.js
node tests/phone_stream_dom.js
node tests/phone_timeline.js
```

命令从仓库根目录运行。FPGA 文件沿用已验收的实现；本次发布没有重新运行完整综合布局布线，也没有给设备烧录。编译、数字仿真及 STA 不能替代天线校准、实际 32 声部演奏、模拟听感和端到端延迟测量。

## 操作入口

- [三端构建与烧录](../../docs/BUILD_AND_PROGRAM.md)
- [特雷门琴接线和校准](../../firmware/theremin/README.md)
- [ESP32 和手机操作](../../firmware/remote_music_ble/README_BLE.md)
- [最新多音轨卡农](../../scores/卡农_最新ESP32_20261103/)

导入曲谱后还需点击“传入设备”；看到“整曲已缓存，点击播放”后播放。更新 ESP32 后刷新手机页面。
