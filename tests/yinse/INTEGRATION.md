# 接入检查表（本轮只提供说明）

原 src 没有改动，以下连接尚未实现。

1. **先保留默认钢琴**：ID0、gain=65535；PCM mux 必须透明，原事件行为和 DAC 捕获沿不能变化。
2. **按键独立验证**：确认两个用户按键管脚、有效电平。复位按键不能改作音色键。
3. **控制读数**：屏幕显示 current_id 和 switching；requested_id 可额外作为“正在切换到”提示。用快照/握手跨到像素域，多位编号不能逐位独立同步。
4. **音源选择**：钢琴继续用 src/piano_partial_voice 与 piano_note_loader；辅助 ID1..4 接 yinse_aux_bank。
5. **事件背压**：输入 FIFO 保持 ready/valid；block_events 只挡 Note On。先完成 loader，再在 gain0 时清理钢琴声部和旧事件。
   注意根 synth_top/synth_event_frontend 的外部 event_ready 是输入 FIFO 空间；不能用它的反相代替 loader_busy。应暴露 voice_bank 的 ld_busy，或用 frontend 内部 core_ready 的反相。辅助组 ready 也不是键盘 FIFO 的容量指示。
6. **清理顺序**：音符事件与切换清理同周期时清理优先；任何旧加载完成不能重新激活已清掉声部。
7. **实际样本对齐**：辅助组 pcm_valid 不直接替换 DAC sample_tick，也不直接充当屏幕的 DAC capture 标志。
8. **效果器**：只复用现有效果链或添加明确选择，不复制钢琴专用音板到全部音色；检查延迟 RAM 残留。
9. **资源**：先用4声部完成实物验证，再评估16声部；只有 Gowin 全部约束时序通过才能声称可上板。
10. **钢琴回归**：最终选ID0逐样本对照原黄金模型，运行原功能测试及双DAC逐bit验证；本轮未运行会写出 yinse 之外产物的旧测试。

第一版切换时保持静音直到所有琴键松开，因此“按着和弦切音色”需要松开重按。
提交后的 clear/flush 脉冲结束即可接收新 Note On，包括淡入期间的新按键；不能额外用 switching 屏蔽事件，否则会漏掉新按键唯一的按下沿。block_events 才是 Note On 的门控信号。
满声部抢占当前为直接重触发；防点击抢占、旧音色尾音与新音色共存属于后续明确扩展，不计入本轮完成范围。
