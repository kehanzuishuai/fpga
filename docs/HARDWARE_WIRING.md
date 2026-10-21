# HARDWARE_WIRING

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.244408+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

有效管脚文件：`D:\gaoyun\piano_v2_audio_fix\src\integrated.cst`；时钟文件：`D:\gaoyun\piano_v2_audio_fix\src\integrated.sdc`。二者本轮内容未修改。管脚报告对比：PASS。

|信号|FPGA位置 / 已有接口|
|---|---|
|clk_50m / rst_n|P16 / K16|
|TTP229 SCL / SDO|C21 / B20，原PMOD2/J26连接|
|板载BCLK / LRCK / DATA|E22 / F24 / G24|
|板载耳放使能|H17|
|PCM5102A BCLK / LRCK / DATA|C24 / B24 / H15，原PMOD1连接|
|DVI三数据对 / 时钟对|AB24/AC24，V24/W24，AA22/AA23，Y22/Y23|

上述为当前CST声明及实现报告检查，不是本轮重新测量的电路连接。没有新增外部端口、分配新管脚或调整Bank电压。保留现有板载与外接DAC。外接DAC注释中的“未激活”属于历史注释；实际顶层EXT_PCM5102已定义且有效CST已有三管脚，应以实际工程/报告为准。实物BIT-TREE协议、键盘选件、电平与物理顺序仍待确认。

