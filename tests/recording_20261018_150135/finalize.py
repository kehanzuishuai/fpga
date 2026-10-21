"""Audit completed outputs and publish a truthful post-synthesis fix report."""
from pathlib import Path
from collections import Counter
from html.parser import HTMLParser
from datetime import datetime,timezone,timedelta
import sys,re,json,hashlib,shutil,csv,wave,zipfile
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;A=R/'audit/recording_20261018_150135'
sys.path.insert(0,str(R/'tools'))
from project_rebuild_20261018 import design_inputs,entries,enabled
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,z):p.write_text(json.dumps(z,ensure_ascii=False,indent=2),encoding='utf8')
def now():return datetime.now(timezone(timedelta(hours=8))).isoformat()
def load(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))

def build():
    base=load(R/'audit/calibration_20261018/BUILD.json')['input_sha256'];current=design_inputs()
    changed=[p for p,h in base.items() if current.get(p)!=h]
    assert changed==['src/piano_note_loader.v'],changed
    assert set(current)==set(base)
    assert all(e['enable']=='1' for e in enabled()) and len(enabled())==64
    assert next(e for e in entries() if e['path']=='src/piano_note_loader.v')['enable']=='1'
    log=(O/'gowin.log').read_text(errors='replace');text=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace')
    assert 'GowinSynthesis finish' in log and 'Generate file' in log and 'ERROR ' not in log
    names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
    slacks={k:float(re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',text,re.M|re.S)[1]) for k,v in names.items()}
    endpoints={k:int(re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',text)[1]) for k in ['Setup','Hold']}
    assert min(slacks.values())>=0 and endpoints=={'Setup':0,'Hold':0}
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
    def rows(p):
        h=Pins();h.feed(p.read_text(errors='replace').split('<h1><a name="Pin_Details">',1)[1]);return h.rows
    old=rows(A/'backup/impl/pnr/yinyue_fashengqi.pin.html');new=rows(R/'impl/pnr/yinyue_fashengqi.pin.html');assert old==new
    net=(R/'impl/gwsynthesis/yinyue_fashengqi.vg').read_text()
    indices=sorted(set(map(int,re.findall(r'G_PARTIAL[.]G_VOICE\[(\d+)\]',net))));assert indices==list(range(32))
    assert not re.search(r'Compiling module .tb_',log)
    assert not re.search(r'MULTALU27X18 (mp_lo|mp_hi|mr)_',net)
    resource=(R/'impl/pnr/yinyue_fashengqi.rpt.txt').read_text()
    usage={m[1]:{'used':float(m[2]),'available':float(m[3])} for m in re.finditer(r'^\s*(Logic|Register|BSRAM|DSP|PLL)\s*\|\s*([\d.]+)/([\d.]+)',resource,re.M)}
    def warns(s):
        return Counter(re.sub(r'":\d+(?::\d+)?','":LINE',re.sub(r'\(\d+(?:,\s*\d+)?\)','(LINE)',line.strip())) for line in s.splitlines() if re.search(r'\bWARN(?:ING)?\b',line,re.I))
    oldw=warns((R/'tests/calibration_20261018/gowin.log').read_text(errors='replace'));neww=warns(log)
    warning={'before':sum(oldw.values()),'after':sum(neww.values()),'new_or_more':list((neww-oldw).elements()),'removed':list((oldw-neww).elements())}
    output_paths=['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html','impl/gwsynthesis/yinyue_fashengqi.vg','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']
    # The saved delivered netlist and FS predate the run; every current output
    # is a fresh file from this execution, after the production edit.
    stamp=(R/'src/piano_note_loader.v').stat().st_mtime
    assert all((R/p).stat().st_mtime>stamp for p in output_paths)
    output={p:{'sha256':sha(R/p),'bytes':(R/p).stat().st_size} for p in output_paths}
    rec={'status':'PASS','time':now(),'gowin_returncode':0,'input_sha256':current,'changed_from_14h40_build':changed,'outputs':output,'sha256':sha(R/'impl/pnr/ao_0.fs'),
        'worst_slack_ns':slacks,'violated_endpoints':endpoints,'actual_voice_indices':indices,'testbench_compiled':False,'all_pin_table_rows_unchanged':len(new),
        'resource_usage':usage,'warnings':warning,'gprj_changed':False,'loader_already_enabled_in_gprj':True,
        'removed_faulty_pitch_dsp_preadders':3,'no_auto_programming':True,'hardware_retest':'PENDING','audio_quality_32_notes':'NOT_ACCEPTED_PENDING_RETEST',
        'scope':'Fresh full production synthesis, place/route and reported STA under unchanged constraints; post-synthesis arithmetic verified separately.'}
    dump(A/'BUILD.json',rec)
    final=O/'final_build';final.mkdir(exist_ok=True)
    for p in output_paths:
        dst=final/Path(p).name
        if not dst.exists():shutil.copy2(R/p,dst)
        assert sha(dst)==output[p]['sha256']
    print('BUILD',slacks,rec['sha256'],flush=True)
    return rec

def report():
    b=build()
    before=load(O/'before/RESULT.json');after=load(O/'after/RESULT.json');generic=load(O/'generic/RESULT.json');audio=load(O/'AUDIO_DIAGNOSIS.json')
    for p in ['RTL_SUITE','VOICE_REGRESSION','DIRECT_CHAIN']:assert load(O/(p+'.json'))['status']=='PASS',p
    assert before['mismatches']==3690 and after['mismatches']==0 and generic['mismatches']==0
    assert after['netlist_sha256']==sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')
    assert before['netlist_sha256']==sha(A/'backup/impl/gwsynthesis/yinyue_fashengqi.vg')
    assert all(sha(R/p)==h for p,h in load(O/'generic/INPUTS.json').items())
    assert all(sha(R/p)==h for p,h in load(O/'RTL_INPUTS.json').items())
    assert sha(A/'backup/impl/pnr/ao_0.fs')=='9689bf3b0085a3830a0cea5592a8c21831679e4a345711bb31d4fb3d2853aecd'
    stats=list(csv.DictReader((O/'SYNTHESIS_AUDIO_COMPARISON_16.csv').open()))
    zeros=[int(r['midi']) for r in stats if r['variant']=='before' and r['entire_dry_zero']=='True']
    text=f'''# 逐键录音：后综合插值故障定位及修复

更新时间：{now()}。工程：`D:\\gaoyun\\piano_v2_audio_fix`。**实际根因已确认、生产RTL已修复、新综合/布局布线/时序通过；没有自动烧录。修复后实物演奏验收仍待进行。**

用户已确认：录音使用上一份SHA256为9689bf3b…的FS，从实体左到右独立逐键按下。录音原件已按原始字节保存于`tests/recording_20261018_150135/original.m4a`，只在工程内解码、测量；原微信文件未改。

## 根因与录音证据

**piano_note_loader中的音高插值在Gowin 1.9.12综合后发生错误。** RTL正确地对无符号ROM字先补0、再相减，随后乘音高位置ap；综合器把减法和乘法折叠到DSP预加器时，将D端高位错误地接成VCC。

- level差值应补0，实际高位补1，相当于多出4096；乘ap并右移2后，衰减码每一个ap多1024，即约24.08dB。
- partial ratio差值实际多出2^20，右移2后每一个ap多2^18；除Q15比例，相当于每个partial多出8×基准音高。
- ap=0（MIDI60/64/68/72）不受此错误影响；ap=1发出强烈高频音，ap=2/3衰减进一步增大并可能完全门控为0。这解释了交替出现的钢琴声、铃声、无声。

在实际旧完整综合网表中原样提取的DSP实例上，用高云GW5A原语仿真复现：ratio差−16、ap=1，应得到−4，实际262140；level差−100应得到−25，实际999。不是凭录音主观猜测，也不是只在Python中造一个故障模型。

|录音时间s|对应音符的证据|正确第一partial Hz|旧网表第一partial Hz|录音测得Hz|
|---|---|---:|---:|---:|
'''
    for r in audio['wrong_note_first_partial_examples']:
        text+=f"|{r['window_start_s']:.2f}～{r['window_end_s']:.2f}|MIDI{r['midi_hypothesis']}频谱匹配|{r['correct_first_partial_hz']:.3f}|{r['old_netlist_first_partial_hz']:.3f}|{r['recorded_line_hz']:.3f}|\n"
    text+=f'''
上述8次清晰发声的窄带谱线，与旧综合网表预测最大相差仅{audio['max_line_error_hz']:.3f}Hz。MIDI61/65/69/73应有的低频第一partial在录音中比错误高频线弱约43～62dB。不能把2495Hz直接当作“误映射到了某个高MIDI音符”：旧网表把整个partial组的频率关系算错了。

旧综合网表参数送入已逐样本核对的整数Voice模型后，MIDI{','.join(map(str,zeros))}全段精确静音，其余若干音明显衰弱。该重建是模型，不冒充板上采样。录音中的静音段本身无法证明某次按键的原始bit编号或精准按下时刻，最后四键和实体位序仍应在新FS板上逐键确认。约34秒还有一次E4类发声，未把它强行解释成连续音阶中的指定末键。

这也给之前VOICE/PEAK为0提供了可复现的解释：这些错误参数即使已收到NoteOn并装载成功，仍会使PCM全零。SILENT_VOICE_EXIT_MODEL.json逐采样重放确认上述4音都在装载后的385个采样（8.021ms）退出；这是实际旧后综合参数驱动整数Voice模型的结果，不冒充板上计数采集。因此界面看到0不能单独证明按键事件没有进入音源。新FS是否每个实体键都收到事件，仍需板上逐键核对。

## 实际修改与验证

唯一生产改动：`src/piano_note_loader.v`。使用ap=0/1/2/3/4的明确移位/加法替代三处乘法，避开错误的DSP预加器合并；保留原插值数值、ROM、音阶参数、包络和时序状态机。没有用调大音量或改成铃声音色掩盖问题。该文件原本就在`yinyue_fashengqi.gprj`中enable=1，本轮实际重新编译了它；不需要重复新增工程条目。启用文件仍64项。

- 旧**实际完整工程**后综合网表Loader+ROM，16音6400字，与原正确模型比较3690字错误，网格音保持正确。
- 新**实际完整工程**同样提取Loader+ROM并使用GW5A原语，16音6400字，0字错误。此夹具绕过键盘/分配器，只强制已捕获的请求音符/基准增量并提供真实含义的Ready/状态译码，没有强制插值结果；具体边界见verify_loader.py。不是全芯片后仿真。
- 独立小工程保留全部pitch/velocity输入位，真实Gowin综合后不作force，MIDI48～91×力度1/40/80/100/127，共88000字，0错误。这是独立Loader综合，不冒充当前只可由键盘触发60～75的优化顶层覆盖全部44音。
- 新RTL的原21项短Voice回归全部通过：力度、边界音、释放、加载期NoteOff、重触发/偷音、逐样本整数模型一致，每采样最多210clk/256，无overrun。**没有把上一轮68项结果冒充本轮重新跑过68项。**
- 当前真实32 Voice synth_top直接注入全部44音，各512持键+512释放采样；原始Voice、补偿后Mixer、主增益、FX逐样本核对，PCM5102数字帧检查通过。此项是RTL仿真，不是整机综合网表音频后仿真。

之前68项RTL测试和直接MIDI WAV是正确的RTL行为，却漏掉了编译器把算术错误映射到DSP的差异；综合和时序PASS也不证明算术等价。现已将后综合Loader逐字等价加入此次交付证据。之前的32音优质验收没有完成，不能据旧数字PASS接受这段实物音频。

## 构建与时序

最新FS：`impl/pnr/ao_0.fs`。

SHA256：`{b['sha256']}`。

|检查|最差Slack ns|
|---|---:|
'''
    text+=''.join(f'|{k}|{v:.3f}|\n' for k,v in b['worst_slack_ns'].items())
    text+=f'''
Setup/Hold违反端点均0，所有{b['all_pin_table_rows_unchanged']}行Pin Details字段与构建前相同。32个Voice索引0～31、FFT、HDMI、PT8211和PCM5102A、GAO保留。CST/SDC、电压、PLL与启用源码集合未变。

Logic {b['resource_usage']['Logic']['used']:g}/138240、Register {b['resource_usage']['Register']['used']:g}/139140、BSRAM258/340、DSP127.5/298（比原来减少3个DSP）。警告旧{b['warnings']['before']}条、新{b['warnings']['after']}条，新增/增多{len(b['warnings']['new_or_more'])}条；继承的TA1132与PR1014仍在。时序结论只针对当前约束下所报告检查。

新增两条EX3791来自统一25bit函数返回值赋给原17bit level乘积。输入为两个12bit无符号ROM字之差，范围−4095～4095；ap最大4，结果范围−16380～16380，完全装得进17bit signed。截去的高位仅为符号扩展；已用实际后综合参数等价检查核对。未把这两条警告隐藏或算作旧警告。

## 试听与后续验收

`tests/recording_20261018_150135/LISTENING.html`提供原录音、旧错误参数重建和修复后参数重建。后两者均为**实际后综合Loader参数+整数Voice/增益/FX模型**，并非DAC实录，也不是整芯片门级音频仿真；统一增益，不逐音归一化。修复后参数重新等于此前正确RTL，因此此前44音WAV/测量仍是目标音源的参照，不能当成已完成新FS板上试听。

当前“铃铛/断档”的算术根因已经复现并修复；**新FS仍须人工烧录后检查16键是否连续半音、无铃声/异常无声，再评价钢琴音色和未来32键音域**。音源原有高音偏薄、极弱力度门控、A/B音域的音色差异仍按上一份44音报告保留，不宣布32音音质优秀。

证据：`tests/recording_20261018_150135`和`audit/recording_20261018_150135`。旧FS、旧完整综合网表和报告完整保存在该audit下backup目录。历史calibration/range44记录和WAV没有覆盖；新FS另存final_build。
'''
    doc=R/'docs/RECORDING_SYNTHESIS_FIX_20261018.md';doc.write_text(text,encoding='utf8')
    html='''<!doctype html><meta charset="utf-8"><title>录音故障与修复对照</title><style>body{max-width:900px;margin:36px auto;font:16px/1.65 system-ui;background:#10151e;color:#e8edf5}audio{width:100%}a{color:#92c8ff}section{padding:20px;background:#1b2635;margin:20px 0;border-radius:10px}</style><h1>录音故障与修复对照</h1><p>已证实高云后综合音高/幅度插值错误。这里的两个重建序列使用实际网表Loader参数，加已核对整数Voice/增益/FX模型；不是板上实录或整机门级音频。每音2秒持键+1秒释放、0.25秒间隔，MIDI60～75，统一增益。</p>'''
    for title,src in [('用户原始录音（已解码）','recording.wav'),('旧综合网表错误参数重建','wav/sequence16_before_post_synth_params_model.wav'),('修复后综合网表参数重建','wav/sequence16_after_post_synth_params_model.wav')]:html+=f'<section><h2>{title}</h2><audio controls preload="none" src="{src}"></audio></section>'
    html+='<p>44音正确RTL参照：<a href="../calibration_20261018/LISTENING_ROOM.html">打开44音试听页</a>。新FS仍需人工上板复测，音质验收尚未完成。</p><img src="recording_vs_netlist.png" width="900" alt="录音与旧错误网表频率匹配">'
    (O/'LISTENING.html').write_text(html,encoding='utf8')
    status=f'''# PROJECT_STATUS

更新：{now()}。唯一工程：`D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`。没有自动烧录。

用户最新逐键录音证实上一份FS（9689bf3b…）存在钢琴/铃声/无声断档。现已确认：Gowin1.9.12把Loader音高插值错误合并到DSP预加器；不是正常的钢琴音色差异。已实际修改生产`src/piano_note_loader.v`的乘法写法，保留正确原插值。

当前新FS：`impl/pnr/ao_0.fs`；SHA256 `{b['sha256']}`。新完整工程综合/PNR/所报告STA通过。实际顶层后综合16音6400字0错误，独立Loader后综合44音五档力度88000字0错误；21项Voice短回归及44音真实32Voice synth_top直接通路通过。原32 Voice、FFT、HDMI、双DAC、GAO均保留。

新FS尚待人工烧录逐键复测；实体位序/最后四键、32音主观音质和未来双16键/同时32音实物验收未完成。历史68项RTL PASS不是旧FS的音质验收。详见[最新录音根因和修复](RECORDING_SYNTHESIS_FIX_20261018.md)、`audit/recording_20261018_150135/BUILD.json`及`tests/recording_20261018_150135/LISTENING.html`。
'''
    (R/'docs/PROJECT_STATUS.md').write_text(status,encoding='utf8');(R/'README.md').write_text(status.replace('(RECORDING_SYNTHESIS_FIX_20261018.md)','(docs/RECORDING_SYNTHESIS_FIX_20261018.md)'),encoding='utf8')
    for p in (O/'wav').glob('*.wav'):
        with wave.open(str(p)) as f:assert (f.getnchannels(),f.getsampwidth(),f.getframerate())==(1,3,48000)
    for src in re.findall(r'src="([^"]+)"',html):assert (O/src).is_file()
    result={'status':'PASS','time':now(),'root_cause':'Gowin1.9.12 DSP pre-adder incorrect extension in pitch interpolation','production_files_changed':['src/piano_note_loader.v'],
       'hardware_recording_old_fs':'FAIL_CONFIRMED','new_fs_hardware_acceptance':'PENDING','audio_quality_32_notes':'NOT_ACCEPTED_PENDING_RETEST',
       'no_auto_programming':True,'fs_sha256':b['sha256'],'production_post_synth_words':6400,'generic_post_synth_words':88000,
       'original_voice_short_tests':21,'direct_midi_notes':44,'audio_match_error_max_hz':audio['max_line_error_hz']}
    dump(A/'FINAL.json',result)
    paths=[doc,R/'docs/PROJECT_STATUS.md',R/'README.md',*[p for p in O.rglob('*') if p.is_file() and 'mpl_cache' not in p.parts],*[p for p in A.rglob('*') if p.is_file() and p.name!='OUTPUT_HASHES.json']]
    dump(A/'OUTPUT_HASHES.json',{'time':now(),'files':{p.relative_to(R).as_posix():{'sha256':sha(p),'bytes':p.stat().st_size} for p in paths}})
    print('DELIVERY COMPLETE',json.dumps(result,ensure_ascii=False),flush=True)

if __name__=='__main__':globals()[sys.argv[1]]()
