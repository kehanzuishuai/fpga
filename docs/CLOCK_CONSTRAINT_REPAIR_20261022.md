# 2026-10-22 主时钟及GAO TCK约束修复

主工程仍为 `D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`。本轮只修改工程中已启用的 `src/integrated.cst` 和 `src/integrated.sdc`，RTL、GPRJ文件列表和现有综合网表均不变。

## 最新手动运行结果

用户本次运行于14:33:05结束。相比13:28失败版本：

| 项目 | 上次 | 本次 |
| --- | --- | --- |
| 工具报告的未布通网络数 | 420 | 0 |
| 寄存器 | 62585 | 49161 |
| CLS | 65721/69120 | 63396/69120 |

但本次仍报 `ERROR(PR0004): There are total 0 unrouted nets`，不能将“0”当作完整实现成功。日志同时含：

- `TA1132: 'tck_pad_i' was determined to be a clock but was not created`。
- `PR1014: Generic routing resource will be used to clock signal 'clk_50m_d'`。

详细STA和FS仍为10月20日文件，没有本轮成功的新报告。PR1014说明时钟路径包含普通布线，存在延迟/偏斜风险，见[高云官方消息说明](https://cdn.gowinsemi.com.cn/SUG937E.pdf)。这些是本次明确检查到的问题；尚不能证明任意一条警告就是PR0004的唯一原因。

其他项目的维护者曾记录“0 unrouted”与未定义时钟相关的版本问题，见[原始问题记录](https://github.com/MiSTle-Dev/NanoMig/issues/49)。该案例主要针对1.9.11.03，不能直接证明当前1.9.12完全同源；本轮依据实际日志补齐本工程缺失的时钟定义，不据此宣告工具缺陷或实现通过。

## 实际修改

在CST末尾追加 `CLOCK_LOC "clk_50m_d" BUFG = CLK;`，明确要求50MHz主时钟的时钟负载使用专用主时钟网络。没有改板上P16管脚，也没有给该网随意指定具体BUFG编号。依据本机SUG1018-1.7E第2.7节的Arora V时钟网络约束语法。

在SDC末尾定义GAO自动插入的外部 `tck_pad_i` 时钟，以及 `gw_gao_inst_0/u_gw_jtag/tck_o` 输出的派生调试时钟。TCK按20MHz上界约束：本机SUG114-3.4.1E第4.1节列出的默认值为2.5MHz，选项最高15MHz，均受此上界覆盖；使用本约束时实际GAO/编程器TCK应不超过20MHz。TCK与板上PLL时钟独立，添加的异步分组只针对厂商GAO调试域，不改变原音频/像素时钟之间的关系。

原50MHz、12.288MHz、27MHz、74.25MHz及序列化时钟约束完整保留，原有引脚、复位和保持时间约束未改，也没有添加新的 `set_false_path`。保留GAO的21块RAM、32钢琴Voice、FFT、HDMI及双DAC，手机和显示UI均不改。

## 检查结果与范围

已核对：

1. 当前映射网表确实有TCK顶层端口、JTAG的 `tck_o` 引脚，以及输出为 `clk_50m_d` 的输入缓冲器。
2. 两份约束只在原内容后追加，原有时钟/引脚约束保持一致。
3. 所有非约束综合输入及当前 `.vg` 哈希与 `SYN_DISTRIBUTED_SHIFT_ALL.json` 相同，现有网表可复用。
4. 用高云附带Tcl解释器检查了完整SDC的语法及11个时钟的名称引用。该检查使用命令桩，没有打开设计执行PnR约束映射，**不是实际STA通过**。

入口为 `tests/display_integration_20261021/verify_clock_constraints.py`，证据为 `audit/clock_constraints_20261022/RESULT.json`。原失败日志、两份旧约束及旧候选记录已备份在该目录的 `before/`。当前约束和候选记录保存在 `final/`。

`audit/display_integration_20261021/CURRENT.json` 状态为 `SYNTHESIS_REUSED_CLOCK_CONSTRAINTS_PENDING_MANUAL_IMPLEMENTATION`：明确表示“旧RTL综合网表不变、实现约束已更新”，并非声称旧综合运行使用过新约束。原像素时钟综合预估55.340MHz的限制仍保留，不能用新约束宣告已经达到74.25MHz。

## 下一步由用户手动实现

仍打开原GPRJ，使用当前 `impl/gwsynthesis/yinyue_fashengqi.vg` 从布局布线步骤完整重新运行；本轮没有必要重复综合，也不能复用上次 `.p`/`.db` 作为新约束已经实现的结果。

重点核对TA1132是否消失、主时钟是否仍报PR1014、是否仍存在PR0004及约束目标找不到的警告。只有实现正常结束、生成本轮新STA/FS，并核对五类时序后，才能确认通过。若CST/SDC实际映射仍报目标不存在，或主时钟仍无法使用专用路径，应以新日志继续定位；本轮静态检查不能代替这一确认。

遵照用户再次明确选择，不自动布局布线，不烧录，不删除GAO来规避缺失的时钟约束。
