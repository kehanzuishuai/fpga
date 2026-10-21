# KEYBOARD_MAPPING

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.254686+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

## 映射与实物证据

当前连续表：raw bit i -> MIDI60+i，i=0..15；RAW_MAP_ENABLE=0，未添加实体位序置换。KEY_MAPPING_CONFIRMED=0继续显示MAP=0。

旧keyboard_v2表按raw bit0..15为60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75。若实体序等于raw位序，第四到第五键将由72跳到61，下降11半音，能造成音区和音色突变；这是条件推论，未测实体顺序，不能称为唯一实物根因。上一轮已经去掉这个排列，本轮未再改音高表。

本轮再次读取四张原图：2000/067、2000/067、4000/071、8000/075，VOICE/PEAK均0。前两张是同一raw，照片未覆盖bit12或全16实体键；它们与旧表相符。当前同raw13/14/15应为73/74/75。原图路径和SHA256见PATH_VERSION_AUDIT.json。

