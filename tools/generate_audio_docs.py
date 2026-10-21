from pathlib import Path
import json,csv,hashlib,datetime
R=Path(__file__).resolve().parents[1];B=Path(r'D:\gaoyun\piano_v2_keyboard_v2');O=R/'tests/audio_diagnosis';D=R/'docs';A=R/'audit/audio_diagnosis'
def read(p):return json.loads(p.read_text(encoding='utf8')) if p.exists() else {'status':'PENDING'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def doc(name,text):
 head=f'# {name[:-3]}\n\n工作工程：{R}\n\n工程入口：{R}/yinyue_fashengqi.gprj\n\n只读基线：{B}/yinyue_fashengqi.gprj\n\n更新：{datetime.datetime.now().astimezone().isoformat()}\n\n'
 (D/name).write_text(head+text,encoding='utf8')
metrics=list(csv.DictReader((O/'NOTE_METRICS.csv').open(encoding='utf8')));off=[x for x in metrics if x['chain']=='fx_off'];on=[x for x in metrics if x['chain']=='fx_on']
summary=read(O/'ANALYSIS_SUMMARY.json');baseline=read(O/'BASELINE_RUN.json');interp=read(O/'INTERPOLATION_AUDIT.json');build=read(A/'BUILD_INPUT_HASHES.json');stress=read(O/'audio_stress_results.json');chain=read(O/'CHAIN_AUDIT.json');regress=read(O/'REGRESSION_RESULTS.json');final=read(A/'FINAL_VALIDATION.json')
old=[60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75]
maptable='|raw bit|旧MIDI|新MIDI|新目标Hz|实体键位置|\n|---|---|---|---|---|\n'+''.join(f'|{i}|{old[i]}|{60+i}|{440*2**((60+i-69)/12):.3f}|未实测|\n' for i in range(16))
freqtable='|MIDI|目标Hz|数字基频Hz|cent|FX前RMS dBFS|FX后RMS dBFS|\n|---|---|---|---|---|---|\n'+''.join(f'|{x["note"]}|{float(x["target_hz"]):.3f}|{float(x["estimated_f0_hz"]):.3f}|{float(x["cent_from_equal_temperament"]):+.2f}|{float(x["rms_dbfs_0p1_0p5"]):.2f}|{float(y["rms_dbfs_0p1_0p5"]):.2f}|\n' for x,y in zip(off,on))
diagram='''```mermaid
flowchart LR
 K["实体键顺序未测"] --> R["ttp229_reader 16bit"]
 R --> M["keyboard_state_mapper 有效帧与排列"]
 M --> E["ttp229_event_bridge On/Off与MIDI"]
 E --> F["synth_event_frontend / Note FIFO"]
 F --> C["synth_core / voice_bank"]
 C --> AL["voice_allocator 32Voice"]
 AL --> L["共享 piano_note_loader / ROM"]
 L --> V["32 × piano_partial_voice：15泛音与Hammer"]
 V --> MX["29bit tree_mixer"]
 MX --> G["polyphony_gain 固定Q15增益"]
 G --> FX["音板→混响→自然EQ→软限幅"]
 FX --> PCM["最终24bit PCM"]
 PCM --> PT["i2s_tx PT8211 16bit"]
 PCM --> PC["pcm5102_i2s_tx 24bit I2S"]
 PCM --> FFT["真实FFT/波形/状态CDC→HDMI"]
 CLK["50MHz→audio_PLL约12.288MHz"] -.-> C
 VCLK["视频PLL 25/125MHz"] -.-> FFT
```
'''
doc('AUDIO_DIAGNOSIS.md',f'''## 结论及证据
已证实旧键盘排列仍在默认构建生效：bit1发MIDI64，连续测试期待61。修复前实际顶层失败日志：{O}/mapping_before_run.log。用户确认录音使用新16键键盘、keyboard_v2目录的FS、板载输出；具体16键物理bit序未提供。

最小修复仅删除顶层旧排列，默认raw bit0..15连续对应MIDI60..75；KEY_MAPPING_CONFIRMED仍为0。KEYBOARD_PROFILE=0现在只控制Reader镜像保护，已与MIDI表解耦。Reader、时序、电平、管脚保持原样。

未发现独立13键模块文件，旧表直接写在顶层参数中。TTP229 Reader、Event Bridge仍是新16键当前依赖，不能盲删。旧排列已从新工程活动RTL清除，原工程和回退快照保留，没有声称删除不存在的13键文件。

## 音色、响度与录音
16个连续MIDI各输出3秒，相同力度100、2秒处松键。完整21音符基线状态：{baseline['status']}；插值独立核对：{interp['status']}。810组参数、324000个加载写入字与实际ROM独立整数推导一致。

MIDI64的0.1..0.5秒FX前RMS约-36.37dBFS，MIDI68约-23.19dBFS，相差13.18dB。差异在原ROM/Voice已存在；不能仅凭参考一致就把所有起伏认定为主观理想。本轮无证据支持改写AMY音色表或用统一高音增益掩盖。

MIDI72..75具有正常非零数字PCM，未复现全部高音消失。PT8211量化对这些音的RMS变化小于0.00003dB；数字仿真仍不能排除板载DAC、耳放、插座、负载和录音AGC的问题。

录音已解码，33.2373秒；较清晰的三个窗口候选基频262.291/331.579/417.237Hz，与旧表MIDI60/64/68一致。详见{O}/RECORDING_ANALYSIS.json。缺少键号标签，不能建立完整实体映射；后段信号过弱不能可靠判基频。没有把手机声学幅度直接当作数字PCM响度，也没有把数值分析冒充现场试听。

## 第五键附近
若实体顺序恰好是raw bit0..15，旧表前四音60/64/68/72，第五音回到61，下降11个半音，会造成音区/音色跳转。此为代码条件推论，实际第五键bit尚未测量，不能宣布唯一根因。新表清除了逻辑bit顺序的这一跳变。

数字交付验收：{final['status']}；实物全部声音已修复：尚未证明。
''')
doc('MIDI_MAPPING_AUDIT.md',f'''## 活动配置
原工程BUILD_STAGE=3、DISPLAY_ENABLE=1、KEYBOARD_PROFILE=0、KEY_RAW_MAP_ENABLE=0、KEY_MAPPING_CONFIRMED=0；Bridge USE_NOTE_TABLE=1，所以旧表真实生效。

新工程仍Stage3/显示开/profile0；音符表独立于profile，活动RTL无旧排列分支。原Reader镜像保护不变。新16键物理bit序未确认，屏幕仍RAWS/MAP0。

{maptable}

实际顶层On/Off→FIFO→共享Loader→32Voice MIDI验证：{O}/mapping_before_run.log、mapping_after_run.log。raw位不是实体键位置。旧12键GAO数据不套用到新键盘；十六位全部保留，不是13键裁剪版。
''')
doc('AUDIO_SIGNAL_CHAIN.md',diagram+f'''
实际实例：顶层u_synth_top→u_synth(synth_event_frontend)→u_core→u_bank；G_PARTIAL.u_loader共享参数加载，G_PARTIAL.G_VOICE[0..31].u_voice算法一致、独立RAM/相位/包络/噪声种子。

note_freq_table：round(f/48000*2^32)；Loader乘Q5.15比例后取[46:19]转28bit增量。每Voice 16槽，最坏210/256时钟；24bit样本混音保留29bit。当前POLY_NORMALIZE=0、MASTER_ATTEN_SHIFT=0、Q15增益32767/32768。

FX_GAIN_SHIFT=1，fx_ctrl=10011：音板开、混响开、EQ自然、软限幅开。双DAC同一最终PCM；PT8211截取[23:8]为16bit LSB对齐、BCLK1.536MHz；PCM5102为24bit I2S/32bit槽、BCLK3.072MHz。名义48kHz，音频PLL未改。

逐级日志：{O}/partial_products.csv、chain_stage_samples.csv、CHAIN_AUDIT.json（{chain['status']}）。Partial乘积和→Voice→Mixer逐样本对齐，Q15增益逐样本核对；FX另做全时长RTL等价验证。短链路逐级幅值统计保留流水延迟和扫描/加载阶段，不与长音固定窗RMS混为一谈。

显示仍取真实最终PCM；音频域约12.288MHz，经稳定握手状态CDC到25MHz像素域，125MHz专用串行域。FFT/显示/视频PLL和复位逻辑均未改变。
''')
doc('PIANO_INTERPOLATION_AUDIT.md',f'''## 实际ROM与计算
生产Loader：{R}/src/piano_note_loader.v；五个ROM为piano_level_rom.v、piano_ratio_rom.v、piano_note_rom.v、piano_sine_rom.v、piano_exp_rom.v。原AMY数据及生成器均未改，保留于tools/amy_data和ref/amy_excerpt。

23168个有效ROM字逐值核对。网格MIDI24+4*j、j0..20；level地址=((j*3+vl)*16+slot)*21+point。四指针相对偏移0/336/1008/1344。j=min((clamp(note,24,104)-24)/4,19)，ap=note_c-24-4*j，104端点j19/ap4不越界。

力度夹40..120，以80分段，av=(delta*205)>>5；力度100得到128，120得到256。小于40每级额外26个Q4.8衰减单位。pitch差13bit/积17bit、velocity差15bit/积25bit，操作数显式signed后>>>。普通level夹0..4094，4095为Missing，沿用最少共同Partial策略。

810组/324000个加载字通过独立整数核对，覆盖MIDI24..104和力度1/39/40/60/79/80/100/119/120/127。原代码有符号转换已经存在，本轮未发现可复现插值溢出/错误右移。MIDI60..75中间音未被错误静音。

C4 grid j9、力度100 base0=9408；E4(MIDI64) j10 base0=10416；G#4 j11 base0=11424；C5 j12 base0=12432。逐点地址和参数见{O}/INTERPOLATED_PARAMETERS.csv、partial_frequencies.csv。E4原表的幅度/频谱差异真实存在，未无证据重写ROM。AMY_SOURCE_AUDIT.json逐项证明原始头文件的20个时刻、3个力度、21个音高、63个泛音数、1760个频率、35200个幅度值均与JSON一致，没有抽取错位。96ms处力度100的基音原始AMY幅度：MIDI60为103.5dB、64为93.0dB、68为108.5dB（这是AMY标尺，不是dBFS）。

## 数值范围及告警
32bit基础相位增量乘Q15后右移19，含32→28bit的4位转换，并非错误多除16。24bit正幅度×18bit波形采用45bit乘积、48bit16槽累加，右移18后饱和24bit；32Voice 29bit混音有足够范围。

原piano_partial_voice.v第283/285行22→21bit告警来自Hammer滤波器状态更新。noise_x范围[-524288,524272]、状态初值0；一阶更新为有界凸组合/地板量化，两个21bit状态足够。没有已证实溢出，不为消告警改声音算法。PLL初始化宽度告警另记。

MIDI24..104最大保留正弦Partial {interp.get('max_retained_partial_hz',0):.3f}Hz，低于24kHz；生成器网格20kHz上限，Loader只保留两端均存在的Partial。范围外如MIDI127的基础DDS仍上升、音色参数却夹边界，不能宣称全0..127无混叠；当前键盘只发60..75，未来全域MIDI需另设反混叠策略。

相对平均律+3..+10cent来自原AMY清洗后的partial1比率，DDS量化误差远小于此。本工程是已有15泛音+Hammer的定点适配，不冒充与上游浮点AMY全算法/听感完全等价。
''')
changed=[]
for p in sorted((R/'src').rglob('*')):
 if p.is_file():
  q=B/p.relative_to(R)
  if not q.exists() or sha(p)!=sha(q):changed.append({'destination':str(p),'source':str(q) if q.exists() else '新增','sha256':sha(p),'change':'移除旧键盘排列，改为连续bit音域；声音算法不变'})
with (A/'FILE_CHANGES.csv').open('w',newline='',encoding='utf8') as f:w=csv.DictWriter(f,fieldnames=['destination','source','sha256','change']);w.writeheader();w.writerows(changed)
doc('AUDIO_FIX_CHANGELOG.md','## 生产RTL实际修改\n'+''.join(f'- {x["destination"]}；来源{x["source"]}；{x["change"]}；SHA256 {x["sha256"]}\n' for x in changed)+f'''
.gprj无需新增生产依赖：改的是已经列入并真正使用的顶层，mapper已在工程。CST/SDC、GAO、32Voice、FIFO、Loader、ROM、FX、FFT、PLL和双DAC发送器按哈希保持与基线一致。

回退：{A}/BASELINE_top.v，旧工程全部保留。没有独立13键模块可删除，移除的是实际生效的旧表分支。

新增工具在{R}/tools：audio_diagnose.py、audio_static_audit.py、audio_source_audit.py、audio_analyze.py、run_audio_mapping.py、audio_chain_audit.py、run_audio_stress.py、run_audio_regressions.py、run_audio_build.py、generate_audio_docs.py、finalize_audio.py。新增测试在tests/audio_diagnosis/，不加入生产综合。解码/绘图库仅安装tools/audio_vendor；原录音不变。

复制的旧Keyboard工具/文档带基线路径，属于历史参考；以本轮八份报告及根README为准。
''')
doc('AUDIO_TEST_RESULTS.md',f'''## 实际状态
数字交付验收：{final['status']}。没有自动烧录，未自动验证模拟硬件或实体键位。

|项目|实际状态/日志|
|---|---|
|21音符各3秒Voice与FX逐样本|{baseline['status']}，{O}/BASELINE_RUN.json|
|810组Loader、324000字、23168 ROM字|{interp['status']}，INTERPOLATION_AUDIT.json|
|16音符两条链声学指标|{summary['status']}，NOTE_METRICS.csv，32/32可靠基频|
|Partial→Voice→Mixer→Gain|{chain['status']}，CHAIN_AUDIT.json|
|原完整钢琴/FX/抢占/重触发/双DAC|{regress['status']}，piano_regression.log|
|键盘/HUD/CDC/FFT/显示|{regress['status']}，REGRESSION_RESULTS.json及独立log|
|实际默认配置32Voice与显示联合|{stress['status']}，audio_stress_results.json|
|实际Gowin原语/ROM语法依赖|{regress['status']}，hardware_syntax.log|
|Gowin综合/P&R/Timing/FS|{build['status']}，gowin_audio.log，audit/audio_diagnosis/BUILD_INPUT_HASHES.json|

## 失败保留
修复前raw bit1失败(actual MIDI64/expected61)，保留mapping_before_run.log、旧测试源和顶层。此失败证明旧默认排列与连续bit音域不符，不证明实体键号。其余本轮失败均保留日志并进入FINAL_VALIDATION.json，不把重测成功覆盖原始失败证据。Icarus constant-select提示不是功能通过依据；上一轮结果不冒充本轮执行。

## 精确范围
每音144000点、48kHz/24bit、力度100、约第4tick NoteOn、96000tick NoteOff、共3秒，含真实Loader延迟及1秒松键段。Voice参考与全部实际计算点比较；停止后补零且模型不得继续出声。FX 144000点逐点核对，独立FX在RAM清零后以32时钟间隔有效输入，生产顶层另以256间隔验证。WAV是数字仿真结果，不是板上录音。

长仿真用同端口/同延迟array-ROM，原回归穷举地址核对；Gowin仍用生产case-ROM。功能PLL和物理串行边界是名义模型；实际原语另做语法/Gowin实现，不等于物理锁定/眼图实测。

## 复现
在{R}运行tools/audio_diagnose.py、audio_static_audit.py、audio_source_audit.py、audio_analyze.py、run_audio_mapping.py after、audio_chain_audit.py、run_audio_stress.py、run_audio_regressions.py、run_audio_build.py。Python建议-X utf8 -B；Icarus默认D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin，Gowin C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe；移机需配置工具路径，.gprj生产依赖均在副本内。
''')
doc('AUDIO_BEFORE_AFTER.md',f'''## 同MIDI音频不变
只修复raw位选择MIDI的排列，没有修改合成/ROM/FX。相同MIDI、力度和初态的PCM逐样本保持，不能声称同MIDI音色被增强。

{freqtable}

cent来自原AMY调律，按名义48kHz估计；固定0.1..0.5秒RMS不是LUFS或全部主观响度。对照图：{O}/note_comparison.png、representative_spectra.png（另有SVG）。

## 试听
{O}/wav/fx_on、wav/fx_off各16段，命名midi_060_C4.wav…midi_075_Ds5.wav。sequence_old_raw_mapping_fx_on.wav是旧表raw顺序，sequence_midi_060_075_fx_on.wav是新连续顺序，另有fx_off，各48秒。来源为RTL或全点等价模型，不是硬件实录。

## 资源与时序
基线Logic43772、Reg16238、BSRAM226、DSP98.5、PLL2、IO23；Fmax 50MHz域279.598MHz、音频33.916MHz、像素33.026MHz；Setup/Hold0。新构建：{json.dumps(final.get('resources_after',{}),ensure_ascii=False)}。完整当前数据见{A}/FINAL_VALIDATION.json和impl/pnr报告；未完成不引用旧报告冒充通过。
''')
doc('BOARD_AUDIO_TEST_GUIDE.md',f'''## 工程和下载
打开{R}/yinyue_fashengqi.gprj，顶层tang_mega_138k_pro_top，Device C、GW5AST-LV138FPG676AC1/I0、SV2017、Stage3、显示开。当前FS：{R}/impl/pnr/ao_0.fs，哈希见{A}/FINAL_VALIDATION.json。仅由用户手动选择下载，本任务没有自动烧录。

## 板载声音验收
保持原供电/管脚/插座，先低音量接已知正常耳机或有源音箱。逐键记录实体位置、RAWS、MIDI/音名、Voice数、幅度和是否有声。当前raw bit i应发60+i，实体顺序仍未确认。旧新ao_0.fs同名，必须核对完整目录与哈希。

先比较本机数字WAV，再听板载输出。若数字音正常但板载弱音仍在，检查事件与GAO最终PCM，再检查PT8211/耳放/插座/负载，不再次盲调高音增益。audio_pa_en应在PLL锁定及音频复位释放后有效；不据此擅改供电或短接。

## GAO
保留4096深度、12.288MHz采样，约333.3us，不足一次覆盖3ms帧间隔或数秒琴音。分次触发扫描开始看SCL/SDO/raw、frame_valid看快照、event_valid&&event_ready看MIDI，最后看Voice数/audio_out。

每次只按一键检查单bit和frame_error；再核对MIDI。确认16位序后才填写RAW_INDEX_TABLE并将KEY_MAPPING_CONFIRMED设1。逐步测2/3/8/16键及快速重复。profile0保留镜像保护，需先见非镜像帧；开机首次就16键全按不保证接纳。新模块协议和多键模式仍需实物证明。

若事件/Voice/最终PCM都正常而耳机极弱，继续板载模拟链诊断。PCM5102A保留J24第11/12/6针(C24/B24/H15)，键盘J26第11/9针(C21/B20)，视频J11；此次录音是板载链，不能据此推断外接PCM模块VIN。

尚需：实际16键raw位序、弱音时GAO最终PCM、同音符板载模拟对照、录音按键顺序。实物未完成的部分不以软件仿真代替。
''')
(R/'README.md').write_text(f'# Audio diagnosis / minimal map fix\n\n当前工程：{R}/yinyue_fashengqi.gprj\n\n只读基线：{B}\n\n生产RTL仅清除旧键盘排列。raw bit0..15默认MIDI60..75，实体位序未确认，保留32Voice、Stage3、FFT/HDMI和双DAC。未自动烧录。\n\n先读docs/AUDIO_DIAGNOSIS.md、AUDIO_TEST_RESULTS.md、BOARD_AUDIO_TEST_GUIDE.md。使用tools/run_audio_build.py构建；旧Keyboard资料为历史参考。最终数字验收：{A}/FINAL_VALIDATION.json。\n',encoding='utf8')
print('Wrote 8 current audio reports and README; validation',final['status'])