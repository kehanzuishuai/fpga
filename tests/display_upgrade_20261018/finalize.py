"""Accept only a fresh source-matched full implementation and passing tests."""
from pathlib import Path
from html.parser import HTMLParser
import json,re,shutil,sys
R=Path(__file__).resolve().parents[2];A=R/'audit/display_upgrade_20261018';O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools'))
from project_rebuild_20261018 import design_inputs,sha,now
preflight=len(sys.argv)>1 and sys.argv[1]=='--preflight'
TAG=sys.argv[1] if len(sys.argv)>1 and not preflight else 'reset74_final'
def passed(p):
 v=json.loads(p.read_text(encoding='utf8'));assert v['status']=='PASS',p;return v
b=json.loads((A/f'BUILD_{TAG}.json').read_text());assert b['input_sha256']==design_inputs()
if not preflight:
 assert b['status']=='PASS' and len(b['outputs'])==6 and b['all_timing_checks_pass']
 assert all(sha(R/q)==v['sha256'] and (v['fresh'] or v.get('authenticated_synthesis_reuse',False)) for q,v in b['outputs'].items())
 if b.get('synthesis_parent'):
  parent=passed(A/b['synthesis_parent'])
  assert all(h==design_inputs()[q] for q,h in parent['input_sha256'].items() if q!='src/integrated.sdc')
  assert all(v['sha256']==parent['outputs'][q]['sha256'] for q,v in b['outputs'].items() if q.startswith('impl/gwsynthesis/'))
checks={q:passed(O/q) for q in ['sim_out_visual/verification.json','HUD16.json','HUD_PIPELINE.json','LABEL_EQUIVALENCE.json','TIMING_EQUIVALENCE.json','post_reset74/RESULT.json','PAIRED.json','BOUNDARY.json','BOARD_FINAL.json','PLL_WAVEFORM.json']}
assert set(checks['BOUNDARY.json']['source_sha256'])=={'src/display/visual_dvi_io.v','src/display/visual_video_clock.v','src/display/gowin_pll/visual_pll_mod.v'}
assert checks['BOUNDARY.json']['checker_sha256']==sha(O/'boundary_checks.py')
for q in ['sim_out_visual/verification.json','BOUNDARY.json','BOARD_FINAL.json','PLL_WAVEFORM.json']:
 assert all(sha(R/p)==h for p,h in checks[q]['source_sha256'].items())
assert all(sha(R/p)==h for p,h in checks['PAIRED.json']['input_sha256'].items())
assert all(sha(R/p)==h for p,h in checks['PAIRED.json']['test_fixture_sha256'].items())
assert checks['post_reset74/RESULT.json']['netlist_sha256']==sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')
hilbert=passed(R/'tests/lissajous_video_20261018/HILBERT_VALIDATION.json')
assert hilbert['source_sha256']==sha(R/'src/display/visual_xy_source.sv')
post_hilbert=passed(R/'tests/lissajous_video_20261018/POST_SYNTHESIS.json')
assert post_hilbert['netlist_sha256']==sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')
source_audit=passed(A/'FINAL_SOURCE_AUDIT.json')
assert all(sha(R/q)==h for q,h in source_audit['protected_sha256'].items())
if preflight:
 print('PASS all functional test inputs/current source hashes, exact production boundary, netlist proof, audio preservation; build status:',b['status']);sys.exit(0)
class Pins(HTMLParser):
 def __init__(self):super().__init__();self.rows=[];self.cells=None;self.cell=None
 def handle_starttag(self,tag,attrs):
  if tag=='tr':self.cells=[]
  if tag in ['td','th'] and self.cells is not None:self.cell=[]
 def handle_data(self,data):
  if self.cell is not None:self.cell.append(data)
 def handle_endtag(self,tag):
  if tag in ['td','th'] and self.cell is not None:self.cells.append(' '.join(''.join(self.cell).split()));self.cell=None
  if tag=='tr' and self.cells is not None:self.rows.append(self.cells);self.cells=None
def pins(p):
 z=Pins();z.feed(p.read_text(errors='replace').split('<h1><a name="Pin_Details">',1)[1]);return z.rows
old=pins(A/'backup/impl/pnr/yinyue_fashengqi.pin.html');new=pins(R/'impl/pnr/yinyue_fashengqi.pin.html');assert old==new
netlist=(R/'impl/gwsynthesis/yinyue_fashengqi.vg').read_text(errors='replace')
voices=sorted(set(map(int,re.findall(r'G_PARTIAL[.]G_VOICE\[(\d+)\]',netlist))));assert voices==list(range(32))
assert not re.findall(r'Compiling module .tb_[A-Za-z_0-9]*',(O/f'gowin_{TAG}.log').read_text(errors='replace'))
tr=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace')
clocks={m[1]:float(m[2]) for m in re.finditer(r'^\s*\d+\s+(\S+)\s+(?:Generated|Base)\s+[\d.]+\s+([\d.]+)MHz',tr,re.M)}
expected_clocks={'clk_50m':50,'audio_clk':12.288,'video_ref':27,'video_pixel_pll':74.25,'video_pixel':74.25,'video_serial':371.25,'video_serial_global':371.25,'video_serial_reset':74.25,'video_serial_reset_regional':74.25,'tck_pad_i':20}
assert clocks.keys()==expected_clocks.keys(),'Unexpected default clocks; clock propagation not fully constrained'
for name,target in expected_clocks.items():assert abs(clocks[name]-target)<0.001,(name,clocks)
rpt=(R/'impl/pnr/yinyue_fashengqi.rpt.txt').read_text(errors='replace')
resources={m[1]:{'used':float(m[2]),'available':float(m[3])} for m in re.finditer(r'^\s*(Logic|Register|BSRAM|DSP|PLL)\s*\|\s*([\d.]+)/([\d.]+)',rpt,re.M)}
assert set(resources)=={'Logic','Register','BSRAM','DSP','PLL'}
rollback=R/'tests/recording_20261018_150135/final_build/ao_0.fs'
assert sha(rollback)=='eaf783cae4f4b608e96c03ba66b8cf10bba9b556e5643f29651b3a456ccd20d9'
dest=O/'final_build';dest.mkdir(exist_ok=True)
for q in b['outputs']:
 p=dest/Path(q).name
 if p.exists():assert sha(p)==sha(R/q),'Refusing to overwrite a different accepted artifact'
 else:shutil.copy2(R/q,p)
ledger={**b,'archived_at':now(),'voice_count':32,'pin_rows_compared':len(new),'pin_fields_unchanged':True,'clock_MHz':clocks,'resources':resources,'fs_sha256':sha(dest/'ao_0.fs'),'tests':list(checks),'post_synthesis_hilbert':post_hilbert,'hardware_monitor_acceptance':'PENDING; no automatic programming','audio_quality_reassessment':'No new44-note timbre quality claim from display measurements'}
(A/'FINAL_ACCEPTANCE.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2),encoding='utf8')
slacks='\n'.join(f'|{k}|{v:.3f}|' for k,v in b['worst_slack_ns'].items())
clock_rows='\n'.join(f'|{k}|{v:.3f}|' for k,v in clocks.items())
resource_rows='\n'.join(f"|{k}|{v['used']:g}/{v['available']:g}|" for k,v in resources.items())
details=f'''# 显示升级与李萨如修复：保留16键（2026-10-18）

已依据 `E:\\xianshi(shengjiban)` 合入主工程并修复视频暴露的低频正交幅值错误。最终完整综合、布局布线、五类静态时序和集成仿真通过。未自动烧录，实际显示器兼容性和复位恢复仍待板上验收。

## 打开与输出

- 打开 `D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`，沿用原顶层。
- 最新FS：`impl/pnr/ao_0.fs`；同哈希归档：`tests/display_upgrade_20261018/final_build/ao_0.fs`。
- SHA256：`{ledger['fs_sha256']}`。
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

最终完整综合、布局布线和时序日志：`tests/display_upgrade_20261018/gowin_{TAG}.log`；记录：`audit/display_upgrade_20261018/FINAL_ACCEPTANCE.json`。此前失败尝试不作为交付。实际Hilbert综合网表逐采样比较完成后，最后一次时钟实现中的整个Hilbert模块与全部被测试子模块逐字相同，完整文本哈希核对后复用该结果；这不是整个FPGA的门级仿真。Setup/Hold违反端点均为0。

|检查|最差裕量ns|
|---|---:|
{slacks}

复位Recovery/Removal裕量较小，仍需上板进行多次复位、HDMI重连和温度变化验收。未忽略OSER10复位时序来取得通过结果。

|时钟|MHz|
|---|---:|
{clock_rows}

|资源|用量/总量|
|---|---:|
{resource_rows}

实际Pin Details的{len(new)}行全部单元格与修改前一致。手动使用最新FS后检查1080p30兼容性、16个指示/音名、低音轨迹比例、松键/持续演奏及多次复位/HDMI重连。32键实体接入和32复音仍是独立验收项目，本轮不重新宣称44音音质合格。
'''
(R/'docs/DISPLAY_UPGRADE_16KEY_20261018.md').write_text(details,encoding='utf8')
p=R/'docs/LISSAJOUS_VIDEO_FIX_20261018.md';s=p.read_text(encoding='utf8')
s=s.replace('最终主工程构建、时序和完整音频保持性结果待最终构建记录填写。',f"最终综合、布局布线、五类时序、120ms声音保持性及实际综合网表Hilbert比较均通过。FS SHA256：`{ledger['fs_sha256']}`。完整结果见 `docs/DISPLAY_UPGRADE_16KEY_20261018.md`。")
p.write_text(s,encoding='utf8')
short=f'''# 当前工程

打开 `D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`。

已合入1080p30显示升级，修复李萨如低频Y轴衰减，保留16键对应、MIDI60～75音名、32 Voice、FFT、HDMI、双DAC及原音源修复。完整综合、布局布线、五类时序和集成仿真通过。未自动烧录，显示器兼容性与复位仍待板上验收。

- 当前FS：`impl/pnr/ao_0.fs`；同哈希归档：`tests/display_upgrade_20261018/final_build/ao_0.fs`。
- SHA256：`{ledger['fs_sha256']}`。
- [最终修改和验证](docs/DISPLAY_UPGRADE_16KEY_20261018.md)
- [李萨如问题与修复](docs/LISSAJOUS_VIDEO_FIX_20261018.md)
- [原音源修复](docs/RECORDING_SYNTHESIS_FIX_20261018.md)
- 修改前备份：`audit/display_upgrade_20261018/backup`。
- 上轮声音FS保留在 `tests/recording_20261018_150135/final_build/ao_0.fs`，原哈希 `eaf783cae4f4b608e96c03ba66b8cf10bba9b556e5643f29651b3a456ccd20d9`。
'''
(R/'README.md').write_text(short,encoding='utf8');(R/'docs/PROJECT_STATUS.md').write_text(short.replace('(docs/','('),encoding='utf8')
print(json.dumps({'status':'PASS','fs_sha256':ledger['fs_sha256'],'voices':len(voices),'pin_rows':len(new),'slacks':b['worst_slack_ns']},indent=2),flush=True)
