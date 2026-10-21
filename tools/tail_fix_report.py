"""Result gates for the production natural-tail fix; no automatic programming."""
from pathlib import Path
import csv,json,sys,wave,shutil,re
import numpy as np
from tail_fix_run import R,A,O,FS,NOTES,sha,now,dump
from tail_fix_analyze import table,read,wav

def tail_fx(n,actual,old,cutoff):
    from tail_fix_run import VV,run
    import fx_model
    gain=(actual*32767)>>15;before_gain=(old*32767)>>15
    inp=O/f'held_{n}_fx_input.txt';out=O/f'held_{n}_fx_rtl.txt'
    np.savetxt(inp,gain,fmt='%d')
    run(f'held_fx_{n}',[VV,O/'fx.vvp',f'+input={inp}',f'+output={out}',f'+samples={len(gain)}'])
    after=np.loadtxt(out,dtype=np.int64);expected=fx_model.Fx().process(gain)
    before=fx_model.Fx().process(before_gain)
    assert np.array_equal(after,expected) and np.array_equal(after[:cutoff],before[:cutoff])
    assert np.any(after[cutoff:]!=before[cutoff:])
    wav(O/f'held_{n}_after_fx_rtl.wav',after)
    wav(O/f'held_{n}_before_fx_model.wav',before)
    region=actual[cutoff:288000]
    return {'fx_samples_bit_exact':len(after),'fx_tail_changed_samples':int(np.count_nonzero(after[cutoff:]!=before[cutoff:])),'tail_max_abs_voice':int(abs(region).max()),'tail_mean_voice_lsb':float(region.mean()),'voice_rail_samples':int(np.count_nonzero(abs(actual)>=8388607)),'fx_rail_samples':int(np.count_nonzero(abs(after)>=8388607))}

def analyze():
    import tail_fix_analyze as m
    assert json.loads((A/'SUITE.json').read_text())['status']=='PASS'
    m.analyze()
    # Independently audit all 44 real synth_top stage streams with the current model.
    import range44_report as chain
    from tail_fix_run import run
    chain.A=A;chain.O=O;chain.run=run;chain.chain()
    chain.audition([dict(r,midi=int(r['midi'])) for r in read('NOTE_METRICS_44.csv')],json.loads((O/'RANGE_COMPARISON.json').read_text()))
    before_root=R/'tests/range44_20261018';rows=[]
    for n in [87,88,89]:
        path=O/f'held_natural_{n}.txt';base=before_root/f'held_natural_{n}.txt'
        def stream(p):
            a=np.zeros(288020,dtype=np.int64);load=None;last_tick=0
            for line in p.read_text().splitlines():
                x=line.split()
                if x[0]=='L':load=int(x[1])
                elif x[0]=='S':
                    i,val,rel,fade=map(int,x[1:]);assert not rel and not fade
                    a[i]=val;last_tick=i
            return a,load,last_tick
        actual,load,end=stream(path);old,old_load,old_end=stream(base);assert load==old_load
        cutoff=int(np.flatnonzero(old)[-1])+1
        assert np.array_equal(actual[:cutoff],old[:cutoff]) and np.any(actual[cutoff:])
        assert end<288000 and actual[-1000:].max()==0 and actual[-1000:].min()==0
        for name,arr in [('before',old),('after',actual)]:
            wav(O/f'held_{n}_{name}_raw.wav',arr)
            tail=arr[132000:288000]*256;assert abs(tail).max()<8388607
            wav(O/f'held_{n}_{name}_tail_only_plus48dB.wav',tail)
        effects=tail_fx(n,actual,old,cutoff)
        assert effects['voice_rail_samples']==effects['fx_rail_samples']==0
        rows.append({'midi':n,'before_zero_s_from_load':(cutoff-load-1)/FS,'after_zero_s_from_load':(int(np.flatnonzero(actual)[-1])-load)/FS,'recovered_nonzero_samples':int(np.count_nonzero(actual[cutoff:])),'prefix_before_old_cutoff_identical':True,'natural_stop_before_6s':True,'before_sha256':sha(base),'after_sha256':sha(path),**effects})
    table('NATURAL_TAIL_FIX_BEFORE_AFTER.csv',rows)
    # The 2s-held/1s-release performance must not be retuned as part of this fix.
    unchanged=[]
    for n in NOTES:
        d=O/'notes'/f'midi_{n:03d}';old=before_root/'notes'/f'midi_{n:03d}'
        for key in ['voice','gain','fx']:
            assert np.array_equal(np.load(d/(key+'.npy')),np.load(old/(key+'.npy'))),(n,key)
        unchanged.append(n)
    dump(A/'FIX_VALIDATION.json',{'status':'PASS','time':now(),'directed_before_failure_after_pass':True,'held_6s_rtl_before_after':rows,'all44_primary_voice_gain_fx_arrays_identical':unchanged,'no_parameter_or_gain_retuning':True,'finite_natural_decay':True,'hardware_acceptance':'PENDING','loudness_balance':'UNCHANGED; NOT_ACCEPTED','no_auto_programming':True})

def build_and_report():
    if (A/'DEFER_BUILD_FOR_CALIBRATION.json').exists():
        dump(A/'TAIL_FIX_VALIDATED_PENDING_CALIBRATION.json',{'status':'PASS','time':now(),'tail_fix_validation_complete':True,'build_deferred_reason':'User explicitly requested all44-note loudness calibration during the current run; build final combined version after calibration validation','no_auto_programming':True})
        print('TAIL FIX VALIDATED. Final build deferred for authorized all44 calibration.',flush=True)
        return
    import project_rebuild_20261018 as b
    b.A=A;b.O=O;b.DOC=R/'docs/NATURAL_TAIL_FIX_20261018.md'
    base_warnings=b.warnings
    b.warnings=lambda text:base_warnings(re.sub(r'":\d+(?::\d+)?','":LINE',text))
    try:b.build()
    finally:
        if (A/'BUILD.json').exists():
            record=json.loads((A/'BUILD.json').read_text())
            record.update(production_rtl_changed=True,production_rtl_files=['src/piano_partial_voice.v'],reference_model_files=['tools/fpga_piano_model.py'],fix='Do not retire a held voice while an audible future breakpoint remains')
            dump(A/'BUILD.json',record)
    b.recheck()
    w=json.loads((A/'WARNING_COMPARISON.json').read_text());w['normalization']='Source line numbers normalized; complete warning text retained'
    dump(A/'WARNING_COMPARISON.json',w)
    report()

def report():
    b=json.loads((A/'BUILD.json').read_text());v=json.loads((A/'FIX_VALIDATION.json').read_text());assert b['status']==v['status']=='PASS'
    from project_rebuild_20261018 import design_inputs
    assert b['input_sha256']==design_inputs()
    before=json.loads((A/'BEFORE.json').read_text());changed=[p for p,h in before['protected'].items() if (R/p).exists() and sha(R/p)!=h and p.startswith('src/')]
    assert changed==['src/piano_partial_voice.v'],changed
    lines=['# 实际RTL修复：临时静音不再提前结束整音','',f'完成时间：{now()}。工程`{R}`。禁止自动烧录。','', '**已修改生产RTL并完成真实验证和Gowin构建。修复后续包络被过早丢弃，不把该补丁称作响度校准或实体最后四键修复。**','', '## 实际改动','', '- src/piano_partial_voice.v：加载21个断点时统计各段未来可发声目标；每个段完成后清对应位。持键时所有partial暂时门控为0，只有未来没有可发声目标才允许IDLE；NoteOff和偷音依旧可立即结束静音Voice。每Voice增加21bit状态，无新RAM读或采样周期。','- tools/fpga_piano_model.py：同步镜像退出条件。未修改ROM数值、AMY参数、频率、增益、DAC、Reader、键位、FFT/HDMI或32Voice结构。','- `.gprj`已登记本轮验证文件，生产piano_partial_voice.v原本就是启用文件，其本轮补丁直接参与综合。','', '## 核心证据','', '- 相同定向用例在修改前RTL重现临时静音提前退出，在新RTL通过9项检查：后续恢复、自然结束、NoteOff、偷音、重新加载、门限边界、复位及采样期限。','- exp ROM全部4096个Q4.8代码验证：3301仍可发声、3302起门控为0；不是凭估计选择未来断点门限。','- 44音均新跑3秒Voice及FX RTL，逐样本与模型一致；全部44音2秒持键+1秒松键的Voice/Gain/FX数组与修改前相同，证明补丁没有暗中改动音高、起音、响度或释放。','- 原68项完整回归、16键映射、键盘、VOICE/PEAK、FFT/HDMI、32Voice联合压力、双DAC和真实Gowin原语展开通过，实际命令与日志在同名JSON/log中。','', '|MIDI|修改前自然归零s|修改后自然归零s|恢复非零采样数|','|---:|---:|---:|---:|']
    for r in v['held_6s_rtl_before_after']:lines.append(f'|{r["midi"]}|{r["before_zero_s_from_load"]:.6f}|{r["after_zero_s_from_load"]:.6f}|{r["recovered_nonzero_samples"]}|')
    lines+=['','三个音均额外新跑6秒、6秒才NoteOff的真实RTL；修改前后直到原退出点逐样本相同。之后恢复真实ROM规定的极弱尾音，仍自然结束。另对三份完整新6秒数据运行真实FX RTL，逐样本匹配模型、无削波，并确认恢复能量通过FX；修改前FX对照为未变FX算法的模型输出，文件名明确标明model。held_*_raw.wav是原幅度对照；tail_only_plus48dB.wav仅截取2.75～6s尾段并放大256倍便于听辨，不是实际DAC音量，也不用于宣称音质优秀。最后1000个Voice采样均为0，尾段均值及峰值在对照CSV中记录，不把有限正弦片段的非零均值误称永久直流。','', '## 构建与时序','', '|检查|最差Slack(ns)|','|---|---:|']
    lines.extend(f'|{k}|{s:.3f}|' for k,s in b['worst_slack_ns'].items())
    lines += ['',f'Setup/Hold违例端点：{b["violated_endpoints"]}。新FS `{b["fs"]}`；SHA256 `{b["sha256"]}`。完整构建、资源和引脚记录见`{A/"BUILD.json"}`，日志`{O/"gowin.log"}`。','', '## 仍未修复的事项','', 'MIDI64和84的响度低谷在本轮保持原样；这不是已证明的位宽/算术错误，原要求禁止无依据主观大幅调音，因此没有盲目拉平各音。32个优质音色的验收仍NOT_ACCEPTED，推荐A仅是相对选择。实体最后四键零VOICE/PEAK仍需GAO真实事件链证据。两块16键和同时32Voice仍独立验收。','',f'备份：`{A/"backup"}`，含修复前RTL、工程和FS。回退至少同时恢复 backup/src/piano_partial_voice.v 和 backup/tools/fpga_piano_model.py，后者由旧快照按修复前哈希精确恢复，见MODEL_BACKUP_RECOVERY.json；工程/FS还原也从本备份取，不能混用新旧模型。全部数据/WAV/波形：`{O}`。']
    doc=R/'docs/NATURAL_TAIL_FIX_20261018.md';doc.write_text('\n'.join(lines)+'\n',encoding='utf8')
    status=f'# PROJECT_STATUS\n\n实际音源RTL补丁已完成：持键期间临时静音不再丢弃后续包络。详见docs/NATURAL_TAIL_FIX_20261018.md。\n\n44音新RTL/FX、原68项和相关联合验证PASS；本轮综合/P&R/所报告时序PASS。FS `{b["fs"]}`，SHA256 `{b["sha256"]}`。未自动烧录，上板PENDING。\n\n响度低谷未做主观校准，32音音质尚未验收。实体最后四键零VOICE/PEAK根因仍待GAO。32Voice、FFT、HDMI和双DAC保留。\n'
    (R/'docs/PROJECT_STATUS.md').write_text(status,encoding='utf8');(R/'README.md').write_text(status,encoding='utf8')
    dump(A/'FINAL.json',{'status':'PASS','time':now(),'production_rtl_changed':changed,'fix':'preserve future envelope targets across temporary held-note silence','new_fs_sha256':b['sha256'],'not_fixed':['source loudness valleys','physical last-four-key event chain'],'hardware_acceptance':'PENDING','no_auto_programming':True})
    files=[p for d in [A,O] for p in d.rglob('*') if p.is_file() and 'backup' not in p.parts and 'mplconfig' not in p.parts and p.name!='OUTPUT_HASHES.json']+[doc,R/'docs/PROJECT_STATUS.md',R/'README.md',R/'yinyue_fashengqi.gprj',R/'src/piano_partial_voice.v',R/'tools/fpga_piano_model.py',*[R/p for p in b['outputs']]]
    dump(A/'OUTPUT_HASHES.json',{'files':{p.relative_to(R).as_posix():{'sha256':sha(p),'bytes':p.stat().st_size} for p in files}})
    print('ACTUAL RTL FIX VERIFIED; fresh implementation PASS; no programming',flush=True)

if __name__=='__main__':globals()[sys.argv[1]]()
