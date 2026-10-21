# FPGA接入：本轮有新增端口

只在lanya提供实现，没有修改src、boards、yinse或teleimenqin。rtl_sources.f目前包含11个RTL文件。主入口wifi_remote_control，默认控制时钟12.288MHz、采样48kHz、UART115200。

## 原模式与音色

仍接mode_requested/actual_mode、timbre_requested/actual_timbre、两类switching、fault及本地消抖事件。模块输出remote_mode_next、remote_timbre_next。

remote脉冲接原tl_mode_control.next_mode或yinse_selector.next_pulse，与本地事件做本地优先仲裁：next = local_next | (remote_next & ~local_event)。local_timbre_event包含next和previous任一事件；previous仍走原本地路径。

现有yinse_controls、teleimenqin_core把按钮和选择器包在内部，合并时须暴露远程脉冲入口及requested反馈，或在实际顶层展开对应实例连接。不能用层次引用强写内部寄存器。actual必须来自current_mode/current_id，不是请求目标。

## 音量

新增sample_tick、pcm_valid、pcm_in、pcm_out_valid、pcm_out。sample_tick是原48kHz采样使能；pcm_in接最终混音，pcm_out及其valid作为后续DAC捕获输入。wifi_volume在原音频时钟上延迟一个周期输出，每个sample_tick将增益最多改变256，满量程到静音约5.33ms。65535精确透传，0静音；中间增益按Q0.16乘法衰减，负数采用算术右移。

不能只接控制接口却继续把未缩放的pcm_in送DAC，否则页面能确认数字增益，实际声音不会变化。若主工程已有总音量，要只保留一个总音量入口，避免重复衰减。保留DAC/音频PLL和左右声道时序，不用UART派生时钟。

03返回实际已应用增益与BPM，不是cfg请求回显。02的历史音量字段仍是最后接收命令记录，手机新滑条使用03。

## 曲谱播放器

新增score_event_valid/ready、score_event_on、score_note、score_velocity、score_playing、loaded_score_count、score_start_safe。

- valid/ready是一个音符事件握手，on=1发音、on=0松音，note/velocity为MIDI值。事件须送到原声部管理器的事件输入仲裁，而不是直接接琴键扫描原始位。
- score_event_ready只在真正能接收事件时置1，不能丢弃事件却硬绑1。NoteOff在反压下保持，停止/故障/模式切换时也等待松音被接收后结束，防止卡音。
- score_start_safe接“无本地持键、旧事件队列已处理、loader空闲且允许开始自动演奏”。不能硬绑1冒充整机安全。开始还要求琴键或合奏模式、有效曲谱、事件消费者ready；特雷门独奏模式不开始曲谱。
- 播放期间应让播放器独占琴键音符事件入口，暂停新的手动NoteOn；避免同音手动键与播放器互相松音。恢复手动演奏时按原键位重装/松开重按机制处理持键。特雷门声部可在合奏模式独立发声。
- 使用当前琴键音色；不创建另一套声部或音源。结束/停止时保证最后一个发声音符有NoteOff。断开Wi-Fi继续播放到结束；本地操作切换乐器时会停止曲谱。
- 时长按120 BPM基准毫秒保存，播放器在sample_tick上累加BPM生成时间基准，30～240 BPM可边播放边修改；不改音符频率，不在速度变化时重新触发音符。

下载先写暂存表，完整且播放器空闲、无切换/故障时才提交。版本号每次提交加1，04返回实际表数量、playing和版本。新曲谱在播放中提交会被拒绝，旧表不受影响。每段32个事件，未实现多段自动串联、Flash持久化或多轨和弦。

## 时钟和验收

上述逻辑与原控制器、声部事件队列都应在同一音频时钟域；跨域时必须另做请求/状态CDC。rst_n同步释放。根据真实时钟设置CLK_HZ，根据真实采样率设置SAMPLE_RATE，不把串口9600或默认12.288MHz当成板上事实。

先验证原音色和模式，再验证PCM静音/半音量/满音量、BPM时长比例、曲谱事件到真实声部、停止不悬挂音符，以及下载中断保留旧表。当前回归直接实例化原yinse/tl控制器，未集成真实整机或做Gowin布局布线。

## 32键映射的主工程改动（由队友完成）

本轮没有修改lanya以外文件。`wifi_remote_control`与`wifi_instrument_control`新增以下端口，必须由真实主工程连接：

| 端口 | 方向 | 用途 |
|---|---|---|
| key_index[4:0] | 输入 | 查询0..31键映射，组合读 |
| key_note[6:0] | 输出 | 当前活动表对应MIDI音符 |
| keymap_safe | 输入 | 允许原子替换键位的真实安全条件 |
| keymap_committed | 输出 | 成功替换活动表后一个时钟周期脉冲 |
| keymap_revision[15:0] | 输出 | 实际提交版本，复位0，提交后加1，可回绕 |

索引约定：第一块琴K1..K16为0..15，第二块为16..31，即 `{board_id, channel_index[3:0]}`。这里的channel_index应是经过物理键位映射后的逻辑K编号；请先实测确认触摸通道与物理K1..K16的对应关系，不按扫描位序猜测黑白键排列。两块琴共32键是输入数量，不代表单旋律播放器已支持和弦。

在琴键事件生成入口，使用当前逻辑键索引查询key_note，将结果锁存进NoteOn/NoteOff事件，替换原硬编码 `BASE_NOTE + key_index`。valid受反压时保持事件及其音符不变，查询端口可供扫描器逐键使用，不能在排队事件发出前随意改写其note。主扫描器应处理两块模块的事件仲裁，不能同时强驱动一个查询地址。

keymap_safe必须来自“两个琴全部松开、旧琴键事件FIFO为空、loader空闲、允许替换映射”，不能硬绑1。模块还会检查曲谱播放器空闲、无模式/音色切换及无系统故障。换表后可以利用keymap_committed重新装载扫描/重按状态，但不能把它接成全局复位。NoteOff仍须完成握手，避免旧映射留下悬挂音符。

默认表第一块60..75、第二块72..87，与页面一致。主工程如果需要其他默认物理音域，须同时修改RTL复位表与页面defaultMap，不仅改网页。当前总音域36..96，允许不同物理键映射到相同音符；同音重叠的声部分配行为由主工程既有策略决定。

交付验收顺序：停止自动播放并松开所有键 → 手机读取32项 → 改第一块K1和第二块K16 → 应用后核对版本与32项回读 → 实体按键发出新音高 → NoteOff正常释放 → 按住键时提交返回忙、旧映射不变 → 断电恢复默认。未接主工程之前，软件回读成功只证明活动映射表已替换，不能作为实体发声验收。

### 实物布局与页面编号（界面更新）

用户已确认每块是9白键、6黑键、最后黑键右上方的1个附加高音键。页面同时呈现两块琴，白键逻辑编号K1/K3/K5/K6/K8/K10/K12/K13/K15，黑键K2/K4/K7/K9/K11/K14，附加键K16；这是沿用原半音顺序的逻辑编号，保持32键协议、RTL表和复位默认值不变。不能把照片外观或页面K编号直接当作TTP229通道号。队友实测两块琴全部16个触摸通道后，将通道号转为上述逻辑K编号再查询key_index。附加键也走独立第16项，不能与K14黑键或K15白键合并。

主页面按压/等待/成功效果只表示网页操作状态；音色/模式稳定选中态依然来自actual反馈。键位页高亮表示编辑位置，蓝点表示草稿相对上次回读的差异；没有增加琴键实时遥测或点击网页试听。按下网页琴键不会向音源发送NoteOn。


### 曲谱页演奏方式：待队友接入

新增独立枚举performance_mode：0自由演奏、1自动演奏、2指导模式。它与现有mode=琴键/特雷门琴/合奏分开，不能复用0x10或改动原三种音源输入模式的含义。本轮只增加页面及ESP32预留HTTP入口，没有修改RTL、发送新UART命令或实现指导判分。

ESP32入口为performanceMode()，GET/POST /api/performance；POST表单mode=0/1/2。当前参数非法返回400，合法请求及GET均返回501、ok:false、supported:false、mode:null。前端保持选择并显示“待设备接入”，不会显示已应用。以后实现时POST沿用现有DeviceJob队列/202与/api/job结果查询；不得直接在HTTP线程等待UART。最终成功返回200、ok:true、supported:true、mode:实际回读值；拒绝、故障、超时不能回显请求值充当实际值。GET也应读取实际状态。

建议队友确认后分配UART SET_PERFORMANCE=0x16（payload 1字节0/1/2）及QUERY_PERFORMANCE=0x06（无payload，ACK value低字节返回实际方式）。这是预留方案，当前解析器尚未支持、ESP32不发送这些帧。应复用既有seq/CRC/ACK/重试规则，并增加能力检测；旧FPGA仍返回不支持，网页维持未应用。需要同步扩展ControlLink、DeviceJob及UART RTL后才开启supported:true。

主链路建议：自由演奏接收两块触摸琴，播放器停止；自动演奏由现有曲谱播放器推进，播放/停止仍走既有控制；指导模式由曲谱给出目标音符，在有效触摸NoteOn匹配目标后推进，不由网页定时器伪造进度。具体同音、多键、休止及跳过规则需队友实现前统一，当前页面不展示虚构的指导进度。手动NoteOn使用应用后的键位映射。

方式切换必须等待安全边界：停止播放器、释放/完成旧NoteOff、排空旧事件，避免悬挂音。忙/故障时返回拒绝，保持旧方式；提交后查询实际值一致才确认。参考测试：旧FPGA不支持不假成功、三种方式往返、播放中切换、按住键切换、错误音不推进、正确音仅推进一次、断线重连回读。指导进度/目标音符遥测字段本轮未定义实现，应由主链路能力确定后补充。
