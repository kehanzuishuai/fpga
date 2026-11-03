# 当前三端工程：构建与烧录

所有命令从仓库根目录执行。构建与烧录是独立步骤，以下构建命令不会连接硬件上传。

## FPGA

- Gowin V1.9.12 64-bit / GowinSynthesis / SystemVerilog 2017。
- 器件 `GW5AST-LV138FPG676AC1/I0`，Device Version C。
- 打开根目录 `yinyue_fashengqi.gprj`，顶层 `tang_mega_138k_pro_top`。
- 保留 `src/`、`assets/`、`impl/yinyue_fashengqi_process_config.json`；相对 ROM 初始化路径以仓库根目录为基准。
- 约束为 `src/integrated.cst`、`src/integrated.sdc`；Place=3、Route=2、Maxfan=100、Timing-driven 与 Correct-hold 开启，资源复制关闭。

命令行使用 Gowin 的 `gw_sh` 或 Windows `gw_sh.exe`：

```shell
gw_sh scripts/build_current_fpga.tcl
```

脚本按源码执行综合、布局布线和时序分析，生成 `impl/pnr/ao_0.fs`。发布的现成 FS 压缩包位于 `release/v21_20261103/FPGA_expression.fs.zip`，解压获得 `FPGA_expression.fs`；原始验收使用的输入、五类时序报告、资源报告和哈希同时归档。重新构建时仍需检查新报告，不能将旧 STA 结果套到修改后的设计。

直接烧录时在 Gowin Programmer 手动选择发布 FS；SRAM Program 临时加载，Flash 固化方式按板卡配置选择。个人 `.gprj.user` 缓存不包含在仓库中。

## ESP32-S3

板型为 **ESP32-S3 N32R16V**，32MB OPI Flash、OPI PSRAM，Huge APP（无 OTA）。本次验证工具包版本是 `esp32:esp32@3.3.10-cn`；Arduino CLI 使用的额外索引是：

```text
https://jihulab.com/esp-mirror/espressif/arduino-esp32/-/raw/gh-pages/package_esp32_index_cn.json
```

构建 FQBN 不能换成早期 4MB 配置：

```shell
python firmware/remote_music_ble/esp32/build_web.py
arduino-cli compile --fqbn "esp32:esp32:esp32s3:FlashMode=opi,FlashSize=32M,PSRAM=opi,PartitionScheme=huge_app" --build-path build/esp32 firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller
```

`build_web.py` 只更新草图内的 `web_page.h`。如尚未安装上述平台，先通过 Arduino IDE/CLI 配置索引并安装对应版本；第三方库均来自该平台所带 Wi-Fi、WebServer、BLE、FreeRTOS 等组件。

直接烧录选择 `release/v21_20261103/ESP32_autoplay_0x0.bin`，这是完整 32MB 合并镜像，**烧录偏移 0x0**。它包含引导器、分区表与应用，不能把该完整镜像当成 `0x10000` 的独立应用文件。IDE 按上述板型配置上传完整草图同样可用。

启动后连接 `FPGA_MUSIC` / `fpga2026`，打开 `http://192.168.4.1` 并刷新缓存。诊断固件标识应为 `v21-autoplay-confirm-20261103`。

## 特雷门琴 UNO

Arduino AVR Boards **1.8.8**，经典 UNO / ATmega328P、16 MHz：

```shell
arduino-cli compile --fqbn arduino:avr:uno --build-path build/uno firmware/theremin/Open_Theremin_FPGA
```

在 Arduino IDE 打开完整草图、选择 Arduino Uno 和实际串口上传。发布的 `.ino.hex` 是不含引导器的应用文件；`.with_bootloader.hex` 用于需要引导器内容的 ISP 工作流，不作为普通串口上传的替代文件。标准串口上传优先使用完整工程和 Arduino 工具。

UNO 到 FPGA 使用 D1/TX、5V→3.3V 电平转换、J24 第7脚 / L17、共地。首次桥接固件校准步骤见 [特雷门琴说明](../firmware/theremin/README.md)。

## 核验发布副本

```shell
python scripts/verify_current_release.py
node tests/phone_play_confirmation.js
node tests/phone_stream_dom.js
node tests/phone_timeline.js
```

第一项使用 Python 标准库，检查源码清单、所有启用的 GPRJ 文件、ROM 初始化文件、九项网页嵌入资源和发布校验清单。其余项目使用 Node.js，不连接硬件。测试输出写入本地构建目录或标准输出，不代表实板试听。

安装 Icarus Verilog 后，还可对完整 FPGA 顶层作接口展开检查：

```shell
python scripts/elaborate_current_fpga.py --iverilog iverilog --prim-lib "本机Gowin目录/IDE/simlib/gw5a/prim_sim.v"
```

该检查保留全部音频及显示逻辑，使用配套 ROM/PLL/视频边界模型和厂商原语库；它不替代 Gowin 综合与时序检查。特定曲谱的 FPGA 仿真输入位于 `tests/current/`。

`tools/`、`tests/` 中早期实验和验收脚本可能保留原电脑路径；当前构建入口为本页的 `scripts/build_current_fpga.tcl`，当前交付依据为本次发布清单。
