# 双DAC音频输出：板载PT8211 + 外接PCM5102A

本文对应本目录的 [yinyue_fashengqi.gprj](yinyue_fashengqi.gprj)，是从原开发工程增量保留的双DAC实现。原音色、32 Voice、触摸输入、音频PLL、板载DAC与功放使能均保留；不替换合成核心，不播放录音，不移植参考仓库的派生时钟。最新工程还包含独立的视频输出链，见[可视化说明](VISUALIZATION_README.md)。

## 接线（已确认的三个GPIO）

| PCM5102A模块 | 工程输出 | FPGA引脚 | Dock J24 |
|---|---|---|---|
| BCK | pcm_bclk | C24 | 11 |
| LCK（LRCK） | pcm_lrclk | B24 | 12 |
| DIN | pcm_data | H15 | 6 |
| GND | 共地 | — | 3或4 |

三路输出为LVCMOS33；需要确认Dock BANK5仍是3.3V，且这些PMOD引脚没有接其他外设。
VIN仍按用户要求不选择：本次没有分配电源引脚，不要把VIN接到GPIO；供电必须按具体模块稳压电路确认，芯片3.3V供电要求不等同于模块VIN规格。

三线I2S工作时，模块SCK应接GND（先确认模块是否已有接地焊桥），**不要连接板载PT8211的BCLK/WS代替新增输出**。PCM5102A配置要求：FMT低（I2S）、XSMT高（解除静音）、DEMP低（关闭去加重）；FLT低选择常规数字滤波。先断电检查实际焊桥与电平，不能只凭照片假设H1/H2/H3/H4的默认状态。不要将A3V3输出与另一电源直接并联。

模块3.5mm插孔是LINE OUT：接有源音箱/功放的线路输入，不直接驱动无源扬声器；首次试听降低后级音量。

## 代码连接与时序

- `src/pcm5102_i2s_tx.v`：新建标准I2S发送器，默认24bit有符号PCM、双声道32bit slot，WS低为左、高为右，MSB在WS切换后一位发送，DATA/WS在BCLK下降沿更新、上升沿采样。slot多余位补零。
- `src/i2s_tx.v`：原PT8211发送器，仅新增 `frame_capture` 组合观察输出；时序always块与备份相同。板载继续输出PCM高16bit，仍是唯一sample_tick来源。
- `src/synth_top.v`：两个发送器接同一 `audio_out`；外接模块在原DAC捕获边界同时锁存左右PCM，下一I2S帧开始发送。当前单声道合成信号复制到左右声道。外接发送器不产生第二个sample_tick。
- `src/tang_mega_138k_pro_top.v.v`：引出三路外接I2S端口。
- `src/yinyue_fashengqi.cst`：新增已确认的C24/B24/H15约束，原引脚未改变。
- `yinyue_fashengqi.gprj`：包含外接发送器源码；使用工程列出的活动 `src/yinyue_fashengqi.cst`，没有另行发布或加载备用约束。

分频公式：BCLK半周期计数 = CLK_HZ / (4 × SAMPLE_RATE × SLOT_W)。名义12.288MHz时每2个主时钟翻转BCLK，得到3.072MHz；每256个主时钟一帧，LRCLK=48kHz。实际频率跟随现有音频PLL真实输出及晶振误差，新增外接DAC未修改音频PLL。当前工程另有视频PLL，不能将本段理解为“工程没有PLL”。仅支持整除的主时钟；不整除参数在仿真启动时明确报错。

## 验证与复现

在本板级目录运行 `scripts/run_pcm5102a_tests.ps1`。脚本使用原开发机器的Python、Icarus、Verilator和Yosys安装位置，换电脑需要调整工具路径。新运行日志和报告写入 `sim_out_pcm5102a`；仓库已归档的通过记录在[verification/pcm5102a.md](verification/pcm5102a.md)，不是克隆后自动生成的结果。

- 24/32、16/16、32/32逐bit自检：左右不同数据、正负满幅、最低位、补零、连续随机更新与同时锁存、帧中复位，以及BCLK边沿和LRCLK周期。
- 双DAC：117次共享PCM捕获、117次合成节拍；PT8211每一位验证为对应PCM高16bit，外接I2S验证完整24bit。
- 真实E盘合成链集成：4音和32音发声，321帧I2S逐bit正确（320帧非零）；复位后Voice清零且PCM清零。
- 对比修改前备份：原PT8211时序always块未改变。
- 新发送器严格Verilator `--Wall`：无RTL warning，不使用屏蔽选项。
- 新发送器Yosys `synth -noabc; check -assert`：通用综合/结构检查，不等同于厂商器件映射或时序收敛。使用完成标记确认实际执行到最后，不能仅以工具退出码判定成功。

上述是双DAC改动的专项验证，不代表整个板级核心重新冻结或实物输出通过。未提供经新的Gowin综合/布局布线及实物验证的固件；任何修改前的FS都不能用于验证新增PCM5102A或视频接口。请在Gowin重新运行Synthesize和Place & Route，检查时序/管脚报告，再下载新FS。原开发工程时序裕量很小，需重新确认当前版本的收敛。

仓库仅保留 `backup_before_pcm5102a_20261007/i2s_tx.v` 这一份历史逻辑比较基准，供回归确认板载DAC时序未改变。原开发机器的完整六文件备份未上传；不能将仓库中的该目录当成完整恢复备份。

## 参考来源

- [TI PCM5102A官方手册](https://www.ti.com/lit/ds/symlink/pcm5102a.pdf)：I2S格式、三线时钟模式与硬件配置依据。
- [noscene/ice40_audio](https://github.com/noscene/ice40_audio)：参考FPGA直接驱动PCM5102的时序思路，没有复制16bit测试发生器及派生时钟。
- [Giuseppe499/KiCad-GY-PCM5102A](https://github.com/Giuseppe499/KiCad-GY-PCM5102A)：同类模块硬件参考，不作为当前实物焊桥已确认的证据。
- [gowinsemi/USB2I2S](https://github.com/gowinsemi/USB2I2S)：工程组织参考，未引入其PLL、USB或管脚。
