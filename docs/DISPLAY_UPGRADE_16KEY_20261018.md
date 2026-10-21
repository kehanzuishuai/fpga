# 显示升级与李萨如修复：保留16键（2026-10-18）

已依据 `E:\xianshi(shengjiban)` 合入主工程并修复视频暴露的低频正交幅值错误。最终完整综合、布局布线、五类静态时序和集成仿真通过。未自动烧录，实际显示器兼容性和复位恢复仍待板上验收。

## 打开与输出

- 打开 `D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`，沿用原顶层。
- 最新FS：`impl/pnr/ao_0.fs`；同哈希归档：`tests/display_upgrade_20261018/final_build/ao_0.fs`。
- SHA256：`fe3a994356854fe3d51d541a655b411d7adc426eb3d703a4e0d67ab94a16edd2`。
- 原升级资料只读副本：`ref/display_upgrade_20261018`；本轮修改前备份：`audit/display_upgrade_20261018/backup`。
- 上轮声音修复FS仍在 `tests/recording_20261018_150135/final_build/ao_0.fs`，原哈希未变。

## 显示行为与修改

1920×1080p30，640×360逻辑画布精确3倍显示，保留中文、波形、青色X/Y轨迹、彩色频谱及真实NOTE/MIDI/VOICE/PEAK。16个矩形逐位对应 `key_state[15:0]`，当前MIDI60～75音名不变；没有扩成32键，没有修改键位表或确认未知实体键序。VOICE显示0～32，与16键指示独立。PEAK保持50ms窗口和垂直消隐邮箱更新，存在窗口与帧传输延迟。

原63抽头Hilbert在C4将Y轴衰减至X的0.3556倍；新1023抽头、4路MAC匹配511采样实部延迟，C4实际RTL拟合Y/X=0.99933、相位−90.000°。MIDI48～91显示滤波频响逐音通过。预热约21.3ms，群延迟约10.65ms，仅作用于显示；两轴共同增益，保留真实钢琴泛音形成的多圈和不对称轮廓。这些显示指标不代表44音音源音质评级。

- `audio_visualizer.sv`、`visual_xy_source.sv`、`visual_xy_plot.sv`：成对16bit波形/正交数据、共同缩放/去均值、轨迹缓存/连线及流水线；58bit真实状态邮箱保留。
- `visual_renderer.sv`、`visual_labels.sv`、`piano_status_overlay.sv`：中文、频谱池化、数字/字形流水线与16个指示；补齐B字形，图形/HUD/同步延迟对齐。
- `visual_tmds.sv`：正确缩窄运行偏差计数位宽，65536编码字逐字等价。
- 视频PLL、`visual_video_clock.v`、`visual_raster.v`：50→27→371.25/74.25MHz，两个视频PLL的VCO分别675/742.5MHz；空闲PLL输出用于与像素同频、固定相位的74.25MHz复位时钟，无新增PLL实例。
- `visual_dvi_io.v`、`integrated.sdc`：三级复位释放，PTR3[0]地区时钟靠近串行器IO，显式PLL相位/占空比及生成时钟，两级约束均保持实际非50%占空比；OSER10 RESET的Recovery/Removal仍计时，仅复位同步器异步CLEAR采用窄范围例外。像素全局时钟的同域Hold保护提高到0.150ns。
- 顶层只增加3处显示复位时钟连线；CST只追加3个复位寄存器和1个地区时钟选择器内部位置，全部IO定义及实际Pin Details不变。
- 55份受保护非显示源码逐字哈希不变；音阶表、音源算法、32 Voice、双DAC、原音频PLL、FFT保留。实际综合网表包含Voice0～31。
- GPRJ新增3份启用显示源，总计67个启用文件；说明与测试以 `enable=0` 登记。完整差异：`audit/display_upgrade_20261018/DISPLAY_CHANGES.patch`。

## 验证

|检查|结果|
|---|---|
|显示包9组|Hilbert、XY几何、1080p30整帧/TMDS、CDC、复位、PCM配对、1024/2048/4096 FFT、绘制预算、真实器件例化及PLL计算全部通过|
|实际RTL Hilbert|9217输出对与独立整数卷积完全一致；纯音幅相、直通、过载和复位通过|
|实际综合网表Hilbert|与RTL同输入逐采样比较通过，DSP/RAM使用实际Gowin原语模型|
|16键/HUD|256逐位对应、16音名字形、原状态CDC通过，450560像素流水版与组合版一致|
|标签/数字/TMDS|921600像素原字形对照、176十进制值、65536编码字通过|
|双系统声音保持|120ms逐音频时钟比较新工程和关闭显示的原顶层，PCM/双DAC引脚/PA/键盘完全一致；真实FFT/状态/TMDS通过，视频失锁200us不影响声音|
|实际综合网表Loader|16音6400参数字，与独立模型0差异，原音源修复保留|
|视频边界|Gowin OSER10/DCS模型100次重锁，输出仅差完整像素，10bit字边界保持；40次PLL就绪丢失/恢复同步器检查通过|
|PLL输出|Gowin PLL数字模型测量74.25MHz复位输出与像素同频，相位差约2.625ns、高电平约6.634ns，与SDC一致；私有模型副本仅将7个参数译码块改为always_comb，以修正Icarus不执行空敏感表always@(*)的问题，频率/相位/占空比算法不变，生产源码与安装文件未改|

系统仿真的物理PLL/串行输出边界使用替代模型，串行器另有上述器件模型检查；物理时序由最终Gowin实现验证。RTL画面预览 `tests/display_upgrade_20261018/preview_1080p30_16keys.png` 使用合成输入，不是板上截图。没有声称运行未安装的Verilator/Yosys。

## 最终实现

最终完整综合、布局布线和时序日志：`tests/display_upgrade_20261018/gowin_reset74_final.log`；记录：`audit/display_upgrade_20261018/FINAL_ACCEPTANCE.json`。此前失败尝试不作为交付。实际Hilbert综合网表逐采样比较完成后，最后一次时钟实现中的整个Hilbert模块与全部被测试子模块逐字相同，完整文本哈希核对后复用该结果；这不是整个FPGA的门级仿真。Setup/Hold违反端点均为0。

|检查|最差裕量ns|
|---|---:|
|setup|1.926|
|hold|0.011|
|recovery|0.848|
|removal|0.123|
|min_pulse_width|3.064|

复位Recovery/Removal裕量较小，仍需上板进行多次复位、HDMI重连和温度变化验收。未忽略OSER10复位时序来取得通过结果。

|时钟|MHz|
|---|---:|
|clk_50m|50.000|
|audio_clk|12.288|
|video_ref|27.000|
|video_serial|371.250|
|video_pixel_pll|74.250|
|video_pixel|74.250|
|video_serial_global|371.250|
|video_serial_reset|74.250|
|video_serial_reset_regional|74.250|
|tck_pad_i|20.000|

|资源|用量/总量|
|---|---:|
|Logic|48554/138240|
|Register|18585/139140|
|BSRAM|268/340|
|DSP|131/298|
|PLL|3/12|

实际Pin Details的403行全部单元格与修改前一致。手动使用最新FS后检查1080p30兼容性、16个指示/音名、低音轨迹比例、松键/持续演奏及多次复位/HDMI重连。32键实体接入和32复音仍是独立验收项目，本轮不重新宣称44音音质合格。
