"""Strict result gates and reviewable range recommendation; never changes RTL."""
from pathlib import Path
import csv, json, sys, wave, zipfile
import numpy as np
from range44_run import R,A,O,PY,NOTES,FS,sha,now,dump,protected,run
from range44_analyze import label,table

def read(name):return list(csv.DictReader((O/name).open(encoding='utf-8-sig')))
def link(p,title=None):return f'[{title or p.name}]({p.as_posix()})'

def chain():
    import fx_model
    assert json.loads((O/'direct.json').read_text())['status']=='PASS'
    direct=read('DIRECT_MIDI.csv');stages=read('DIRECT_STAGES.csv');traces=read('PARTIAL_FIXED_TRACE.csv')
    assert [int(r['midi']) for r in direct]==NOTES
    for row in direct:
        for key in ['write_on','write_off','allocations','loader_done','held_voice_count','read_on','read_off']:assert int(row[key])==1
        assert int(row['first_pcm_value'])!=0 and int(row['pcm_frames'])>1000
    for row in traces:
        x={k:int(v) for k,v in row.items()};raw=(x['exp_q18']<<6)>>(x['level_q22']>>22);off=raw-1049
        assert x['amp_raw']==raw and x['amp_off']==off and x['amp_gated']==(0 if off<=1153 else off)
        assert x['product_s45']==x['amp_gated']*x['wave_q17']
    results=[]
    for n in NOTES:
        run(f'direct_equivalence_{n}',[PY,'-X','utf8','-B','tools/compare_pcm.py',O/f'direct_voice_{n}.txt','--hammer','1'])
        z=[r for r in stages if int(r['midi'])==n]
        g=np.array([int(r['gain']) for r in z]);s=np.array([int(r['mixer']) for r in z]);v=np.array([int(r['voice']) for r in z]);post=np.array([int(r['post_fx']) for r in z]);expected=fx_model.Fx().process(g)
        assert np.array_equal(v,s) and np.array_equal(g,(s*32767)>>15) and np.array_equal(post[1:],expected[:-1])
        results.append({'midi':n,'samples':len(z),'voice_model_exact':True,'mixer_exact':True,'gain_exact':True,'fx_exact_one_sample_capture_latency':True})
    dump(A/'DIRECT_CHAIN.json',{'status':'PASS','time':now(),'actual_voices_in_elaboration':32,'notes':44,'partial_formula_records_checked':len(traces),'pcm5102_frames_checked':sum(int(r['pcm_frames']) for r in direct),'per_note':results,'scope':'Real synth_top, direct FIFO events, 512 held +512 release sample ticks each; full-duration per-note Voice/FX RTL is separate. PT8211 retained; fresh direct checker here checks PCM5102 digital frames.'})

def validate():
    before=json.loads((A/'BEFORE.json').read_text());unchanged=protected()==before['protected'];assert unchanged
    for path in ['AUDIO_RUN.json','MODEL_RUN.json','DIRECT_CHAIN.json','TAIL_PROBE.json','NATURAL_TAIL_RTL.json']:
        assert json.loads((A/path).read_text())['status']=='PASS',path
    metrics=read('NOTE_METRICS_44.csv');assert len(metrics)==88
    assert sorted((int(r['midi']),r['chain']) for r in metrics)==sorted((n,c) for n in NOTES for c in ['fx_off','fx_on'])
    provenance=json.loads((O/'WAV_PROVENANCE.json').read_text());assert len(provenance['files'])==88
    for r in provenance['files']:
        p=R/r['path'];assert sha(p)==r['sha256']
        with wave.open(str(p)) as w:assert (w.getnchannels(),w.getsampwidth(),w.getframerate(),w.getnframes())==(1,3,48000,144000)
    # Verification of the relevant files actually used by each invocation, not unrelated report scripts.
    rel=['src/piano_partial_voice.v','src/piano_note_loader.v','src/note_freq_table.v','sim/models/piano_roms_fast.v','sim/tb/tb_piano_voice.v','tools/fpga_piano_model.py','tools/piano_tables.py','tools/pianolib.py','src/piano_fx.v','tools/fx_model.py','tests/range44_20261018/tb_audio_fx.v']
    for n in NOTES:
        d=O/'notes'/f'midi_{n:03d}';res=json.loads((d/'RESULT.json').read_text())
        assert res['status']=='PASS' and res['fresh_voice_rtl'] and res['fresh_fx_rtl'] and res['fx_bit_exact_samples']==144000
        for name,h in res['sha256'].items():assert sha(d/name)==h
        for prefix in ['voice','equivalence','fx']:
            meta=json.loads((O/f'{prefix}_{n}.json').read_text());assert meta['status']=='PASS'
            assert all(meta['input_sha256'][p]==sha(R/p) for p in rel)
    primary={r['chain']:{int(x['midi']):x for x in metrics if x['chain']==r['chain']} for r in metrics}
    for c,z in primary.items():assert all(float(z[n]['measured_f0_hz'])<float(z[n+1]['measured_f0_hz']) for n in range(48,91))
    cmp=json.loads((O/'RANGE_COMPARISON.json').read_text())
    obj={'time':now(),'scope':'44 individual pitches, A48..79 versus B60..91; hardware input and simultaneous 32-note playing are separate acceptance projects','digital_functional_status':'PASS','quality_acceptance':'PASS_SCREEN_ONLY' if all(x['quality_screen_pass'] for x in cmp['schemes']) else 'NOT_ACCEPTED','human_listening':'PENDING','hardware_acceptance':'PENDING','protected_files_unchanged':unchanged,'production_rtl_edits':[],'preserved':['32 Voice','FFT','HDMI','PT8211','PCM5102A'],'no_auto_programming':True,'new_gowin_build':False,'reason_no_new_build':'Production RTL, constraints, project configuration and existing FS are unchanged relative to this round\'s BEFORE snapshot; this request adds test/measurement artifacts only. Current existing FS is recorded, not newly built or reaccepted.','fs_sha256':sha(R/'impl/pnr/ao_0.fs'),'fresh_full_duration_rtl_notes':44,'fresh_fx_samples':44*144000,'exported_individual_wav_files':88,'all44_measured_pitches_distinct_increasing':True,'all_waveforms_equal_fresh_rtl':True,'relevant_invocation_input_hashes_current':True,'unreliable_f0_measurements':[(int(r['midi']),r['chain']) for r in metrics if r['f0_reliable']!='True'],'clipping_samples':sum(int(r['rail_samples']) for r in metrics),'quality_screen_thresholds':cmp['screen_thresholds']}
    obj['tail_probe_model_notes_with_later_weak_energy']=json.loads((A/'TAIL_PROBE.json').read_text())['notes_with_later_nonzero']
    obj['natural_tail_6s_rtl_notes']=[87,88,89]
    previous=json.loads((R/'audit/scale_decay_20261017/BUILD.json').read_text())
    differences=[str(Path(p).relative_to(R)) for p,h in previous['input_sha256'].items() if sha(Path(p))!=h]
    bitstream={'time':now(),'current_fs_sha256':obj['fs_sha256'],'round_start_fs_sha256':before['protected']['impl/pnr/ao_0.fs'],'previous_recorded_build_fs_sha256':previous['sha256'],'unchanged_this_round':True,'previous_build_input_differences_at_round_start':differences,'prior_source_and_constraint_inputs_match':all(Path(p).name=='yinyue_fashengqi_process_config.json' for p in differences),'current_bitstream_revalidated':False,'note':'Current FS and expanded process configuration already differed from the previous BUILD ledger at this round start. This round did not cause that difference, rebuild or program the device; do not equate old BUILD PASS with acceptance of this current FS.'}
    dump(A/'BITSTREAM_PROVENANCE.json',bitstream)
    obj['current_fs_differs_from_prior_ledger']=obj['fs_sha256']!=previous['sha256']
    obj['current_fs_revalidated_this_round']=False
    dump(A/'VALIDATION.json',obj);return obj

def audition(metrics,cmp):
    # Self-contained offline player; browser requests only relative files supplied with this run.
    rows=[]
    for n in NOTES:
        row={'midi':n,'name':label(n)}
        for c in ['fx_off','fx_on']:
            r=next(x for x in metrics if x['midi']==n and x['chain']==c)
            row[c]={k:r[k] for k in ['measured_f0_hz','attack_rms_dbfs_0_100ms','early_rms_dbfs_100_500ms','peak_dbfs','fundamental_to_overtones_db','natural_held_zero_s_model']}
        rows.append(row)
    template='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>44 音音源验收</title><style>body{font:16px system-ui;margin:30px auto;max-width:1250px;padding:0 18px;background:#f5f6f7;color:#202a36}h1{font-size:26px}p{line-height:1.65}.box{padding:18px;background:white;border:1px solid #ddd;border-radius:10px;margin:15px 0}select,button{font-size:16px;padding:8px;margin:5px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{border-bottom:1px solid #ddd;padding:9px;text-align:right}td:nth-child(2){text-align:left}audio{width:100%}.warn{background:#fff1dd}a{color:#175dad}.scroll{overflow:auto}</style><h1>44 音音源测量与试听</h1><div class="box warn">功能验证通过；32 个优质音色的验收尚未通过。统一力度 100、48 kHz、24 bit，2 秒按住 + 1 秒释放。所有 WAV 均来自本轮新 RTL；没有逐音归一化、补偿或淡出。此页面未记录真人听评，上板验收仍待进行。</div><div class="box"><b>连续音域：</b><select id="scheme"><option value="A_48_79">A：48～79，C3～G5</option><option value="B_60_91">B：60～91，C4～G6</option><option value="all44">全部 44 音：48～91</option><option value="flagged_seam_pairs">重点相邻音反复比较</option></select><select id="chain"><option value="fx_off">FX 前（Q15 主增益后）</option><option value="fx_on">FX 后（共鸣、混响、自然 EQ、软限幅）</option></select><audio id="seq" controls preload="none"></audio><p>连续音每音 3 秒，间隔 0.25 秒。第 k 音从 (k−1)×3.25 秒开始。FX 前后使用相同满刻度；切换时保持电脑音量。重点序列为 63/64、64/65、67/68、79/80、83/84、84/85、87/88 等，各对重复两次。</p></div><div class="box"><b>单音：</b><select id="note"></select><audio id="single" controls preload="none"></audio><p id="detail"></p></div><div class="box"><h2>44 音测量表</h2><p>自然归零时间来自长按整数模型，其余所列值测自新 RTL。RMS、Peak 均为 dBFS；基音/泛音比为带功率比，不能单独代表音质好坏。</p><div class="scroll"><table><thead><tr><th>MIDI</th><th>音名</th><th>基频 Hz</th><th>起音 RMS</th><th>100～500 ms RMS</th><th>Peak</th><th>基音/泛音 dB</th><th>自然归零 s</th><th>试听</th></tr></thead><tbody id="rows"></tbody></table></div></div><script>const DATA=__DATA__;const $=x=>document.getElementById(x);const f=x=>Number(x).toFixed(2);for(const r of DATA){let o=document.createElement('option');o.value=r.midi;o.textContent=r.midi+' '+r.name;$('note').appendChild(o)}function filepath(r,c){return 'wav/'+c+'/midi_'+String(r.midi).padStart(3,'0')+'_'+r.name+'.wav'}function one(){let r=DATA.find(r=>r.midi==$('note').value),c=$('chain').value,x=r[c];$('single').src=filepath(r,c);$('detail').textContent='MIDI '+r.midi+' '+r.name+'：基频 '+f(x.measured_f0_hz)+' Hz；起音 RMS '+f(x.attack_rms_dbfs_0_100ms)+' dBFS；早期 RMS '+f(x.early_rms_dbfs_100_500ms)+' dBFS；Peak '+f(x.peak_dbfs)+' dBFS'}function update(){let c=$('chain').value,s=$('scheme').value;$('seq').src='wav/'+(s==='flagged_seam_pairs'?s:'sequence_'+s)+'_'+c+'.wav';$('rows').innerHTML='';for(let r of DATA){let x=r[c],tr=document.createElement('tr');tr.innerHTML='<td>'+r.midi+'</td><td>'+r.name+'</td>'+['measured_f0_hz','attack_rms_dbfs_0_100ms','early_rms_dbfs_100_500ms','peak_dbfs','fundamental_to_overtones_db','natural_held_zero_s_model'].map(k=>'<td>'+f(x[k])+'</td>').join('')+'<td><button>选择</button></td>';tr.querySelector('button').onclick=()=>{$('note').value=r.midi;one();$('single').play()};$('rows').appendChild(tr)}one()}$('chain').onchange=update;$('scheme').onchange=update;$('note').onchange=one;update();</script></html>'''
    (O/'LISTENING_ROOM.html').write_text(template.replace('__DATA__',json.dumps(rows,ensure_ascii=False)),encoding='utf8')

def report():
    obj=validate();metrics=read('NOTE_METRICS_44.csv');cmp=json.loads((O/'RANGE_COMPARISON.json').read_text());q=read('QUANTIZATION.csv');fx={int(r['midi']):r for r in read('FX_AMPLITUDE_COMPARISON.csv')}
    def num(r,k):return float(r[k])
    def metric(n,c='fx_off'):return next(r for r in metrics if int(r['midi'])==n and r['chain']==c)
    summaries=cmp['schemes'];Aoff=next(r for r in summaries if r['scheme']=='A' and r['chain']=='fx_off');Boff=next(r for r in summaries if r['scheme']=='B' and r['chain']=='fx_off')
    preferred='A' if Aoff['early_rms_std_db']<Boff['early_rms_std_db'] else 'B'
    lines=['# 44 音音源验收与 32 键候选音域比较','',f'完成时间：{now()}。工程：`{R}`。本轮新增测试与分析，不修改任何生产 RTL、约束、项目配置和 FS。','',f'**功能验证 PASS；32 个优质音高的音质验收：{obj["quality_acceptance"]}；真人听评与上板验收 PENDING。相对优先推荐方案 {preferred}，仍需处理响度低谷并进行听评，不能称为已经具备 32 个优质音色。**','',f'方案 A（48～79）的早期 RMS 跨度为 {Aoff["early_rms_span_db"]:.2f} dB；方案 B（60～91）为 {Boff["early_rms_span_db"]:.2f} dB。方案 B 新增 80～91 后出现明显偏弱的高音区，MIDI84/C6 是重要检查点。','',f'试听入口：{link(O/"LISTENING_ROOM.html")}。完整表：{link(O/"NOTE_METRICS_44.csv")}；FX 比较：{link(O/"FX_AMPLITUDE_COMPARISON.csv")}；相邻音：{link(O/"ADJACENT_COMPARISON.csv")}；四半音变化和局部低谷：{link(O/"FOUR_SEMITONE_COMPARISON.csv")}、{link(O/"LOCAL_LOUDNESS_VALLEYS.csv")}。','', '## 验证条件与证据边界','', '- 主验收力度 100，hammer 开启，48kHz/24bit；每音 2 秒 Note On 后释放，记录总计 3 秒。各音均独立复位，避免残留混响；Q15 主增益 32767，FX 参数与当前 Stage3 相同。FX 前指主增益后、FX 模块前。','- 44 音全部重新运行真实 Voice+Loader RTL，逐计算样本与整数模型比较；44 音 FX 各 144000 样本重新跑 RTL 并逐样本一致。可试听单音 WAV 的每个值都来自这些流，没有逐音归一化、均衡补偿或试听淡出。','- 另外，44 音均通过实际 32 Voice synth_top 的直接 FIFO 注入，检查 On/Off、分配、Loader、Voice、混音、增益、FX、释放及 PCM5102 数字帧。每音仅 512 held+512 release ticks，用于通路验证；长音质分析来自独立 3 秒流。','- 长按无 NoteOff 的自然衰减最多 30 秒、直到 Voice 自然退出，使用当前整数模型；时间从 Loader 完成算起。不是 44 次长时 RTL 或板上测量。模型另筛查力度40/80/100/120的起音和响度，见 VELOCITY_SCREEN_MODEL.csv。','- 44 个不同音高单独验证，不代表两块16键输入已接入，也不代表同时32音的硬件/复音验收完成。生产工程仍保留32 Voice、FFT、HDMI和双DAC；原实体最后四键零VOICE/PEAK根因仍待GAO。','- 未执行真人听评，不能把客观指标等同于“好听”。这里给出有证据的相对风险、推荐顺序和可复核 WAV。','', '## A/B 定量比较','', '|音域/链路|起音RMS跨度 dB|早期RMS跨度 dB|早期RMS标准差 dB|最大相邻早期RMS差 dB|最大调音误差 cent|自然归零范围 s（模型）|音质筛查|','|---|---:|---:|---:|---:|---:|---|---|']
    for s in summaries:lines.append(f'|{s["scheme"]} {s["low"]}～{s["high"]} / {s["chain"]}|{s["attack_rms_span_db"]:.2f}|{s["early_rms_span_db"]:.2f}|{s["early_rms_std_db"]:.2f}|{s["largest_adjacent_early_rms_db"]:.2f}|{s["max_abs_tuning_cents"]:.2f}|{s["natural_held_zero_range_s_model"][0]:.3f}～{s["natural_held_zero_range_s_model"][1]:.3f}|{"PASS_SCREEN_ONLY" if s["quality_screen_pass"] else "不通过"}|')
    lines+=['','本轮使用的工程筛查阈值见分析脚本：相邻 RMS >6dB、四半音内早期 RMS >9dB、中心音相对±4半音平均值偏差>6dB、32音早期 RMS 跨度>12dB；基音/泛音比相邻差>10dB、归一化频谱重心比>1.5、自然衰减时长相邻比>2、调音偏差>15cent。这些是本轮排查建议，用户尚未指定产品音质合格线，不冒充通用听觉标准。任何单项通过都不意味着音色优秀；本轮未通过筛查及尚无听评，不能据此宣布产品音质验收完成。','', '## 关键问题与解释','']
    for n in [60,64,68,79,80,84,88,91]:
        d=metric(n);p=metric(n,'fx_on');lines.append(f'- MIDI{n}/{label(n)}：基频 {num(d,"measured_f0_hz"):.3f}Hz，起音RMS {num(d,"attack_rms_dbfs_0_100ms"):.2f}dBFS，早期RMS {num(d,"early_rms_dbfs_100_500ms"):.2f}dBFS，FX后 {num(p,"early_rms_dbfs_100_500ms"):.2f}dBFS，基音/泛音 {num(d,"fundamental_to_overtones_db"):.2f}dB，自然归零 {num(d,"natural_held_zero_s_model"):.3f}s（模型）。')
    lines+=['',f'MIDI64→68 早期 RMS 相差 {num(metric(68),"early_rms_dbfs_100_500ms")-num(metric(64),"early_rms_dbfs_100_500ms"):.2f}dB；MIDI68→84 相差 {num(metric(68),"early_rms_dbfs_100_500ms")-num(metric(84),"early_rms_dbfs_100_500ms"):.2f}dB。这些差异在 FX 前已存在，不能归结为双 DAC 或 FX 的单独故障。FX 的增加/减小也已逐音列出，不能用统一加大总增益修复相对差异。','',f'基频测量没有把最大谱峰当成基音：按 Loader 实际 partial1 DDS 在频谱中定位，以多个谐波/实际 partial 和自相关交叉检查。未可靠测定的项：{obj["unreliable_f0_measurements"]}。当前44音测得频率严格递增，分别为44个不同音高；保留AMY原始partial频率的小偏差，表中同时列十二平均律目标、DDS与实测值。','']
    for s in summaries:
        lines.append(f'**{s["scheme"]} / {s["chain"]}**：无声音 {s["silent_notes"]}；未可靠验证基频 {s["unverified_f0"]}；单键标志 {s["per_note_flags"]}；全音域标志 {s["range_flags"]}。')
        seams=s['flagged_seams'];lines.append('相邻音色/响度筛查：'+('; '.join(f'{r["from_midi"]}→{r["to_midi"]}: {r["flags"]}' for r in seams) if seams else '没有超过单相邻键阈值的突变；较宽的响度低谷仍存在，不能据此判为均匀。'))
    lines+=['','音色方面，两方案未触发相邻基音/泛音比或归一化频谱重心的突变阈值，但跨音区谱形差别很大：低音48/56的基音弱于所测泛音带总能量约16dB；方案B的84～91基音/泛音比约21～31dB、频谱重心/f0接近1，主要由基音主导，存在高音偏薄/偏纯的听感风险。这些指标不能代替真人音色评价，也不意味着基音强就是好听。该比例只统计实际partial频带，测量窗100～500ms，不包含全部非谐波噪声。','', '响度跨度是原幅度PCM能量指标，不是感知响度单位；没有用频率加权或逐音归一化掩盖差异。这里据其筛查明显不平衡风险，最终是否可接受仍须保持统一播放音量的实物/真人A/B听评。']
    lines+=['','## 衰减和定点归零','',f'44音自然归零范围 {min(float(x["natural_held_zero_s_model"]) for x in q):.3f}～{max(float(x["natural_held_zero_s_model"]) for x in q):.3f}s（模型）。没有不能起音或2秒内整音突然归零的证据，但高音包络/门限的退出行为仍需区分正常衰减与尾段被舍弃。T20/T40为10ms RMS相对峰值最后越过阈值的时刻，QUANTIZATION.csv给出；NOTE_METRICS_44.csv同时给出从RMS峰值算起的衰减时长，不冒称室内声学混响时间。','', '实际算术为 unsigned18 exp → shift/offset1049 → gate≤1153 → unsigned24 amplitude × signed18 wave → signed45 product → signed48累加 >>>18 → 24bit饱和；Q15主增益32767 >>>15；FX保留其定点状态和限幅。所有44音新的Voice RTL与模型一致。选取48/64/79/84/91的实际内部操作数逐记录核对exp、门限、符号乘法；长按模型记录所有44音的亚LSB乘积、正小和归零、负小和算术右移到−1、最大乘积/累加值及门限样本。','', 'QUANTIZATION.csv 的 sub-LSB 计数不是音符丢失数。单个零交叉、小于1LSB和自然包络结束都可能给零；未发现溢出或错误位宽造成整音立即消失。长期归零主要由现有partial门限和Voice退出条件决定。PT8211丢低8位与PCM5102保留24位的差别也单列；这种量化不解释C6在FX前已出现的20多dB响度落差。','']
    tail=read('TAIL_REVIVAL_COUNTERFACTUAL.csv');actual=read('NATURAL_TAIL_RTL.csv')
    lines+=['**尾段风险（87～89）**：额外各6秒、NoteOff在6秒才到来的实际Voice RTL，确认这三个音在长按期间自然退出，并与未修改模型逐样本一致。另做诊断模型，只关闭“所有partial暂时门控为0即退出”的动作，其他算术保持相同；直到原退出点的全部输出完全一致，随后出现极弱的后续包络能量：','', '|MIDI|实际RTL自然归零s|诊断模型首次恢复s|恢复段最大10ms RMS dBFS|','|---:|---:|---:|---:|']
    for n in [87,88,89]:
        t=next(r for r in tail if int(r['midi'])==n);r=next(r for r in actual if int(r['midi'])==n)
        lines.append(f'|{n}|{float(r["natural_zero_s_from_loader_complete_rtl"]):.6f}|{float(t["counterfactual_first_after_stop_s"]):.6f}|{float(t["counterfactual_max_10ms_rms_dbfs_after_stop"]):.2f}|')
    lines+=['','这是当前门限/退出策略舍弃后续极弱尾音的证据，不是溢出，也不是实际RTL重新发出了这些尾音。诊断模型不是修复版本，不能用其假想输出替代当前WAV；该风险增加方案B的尾段一致性疑问。恢复能量约−78～−85dBFS，是否听得到需实物/放大对照听评，不能仅凭模型认定明显可闻缺陷。生产RTL未改，见TAIL_REVIVAL_COUNTERFACTUAL.csv、NATURAL_TAIL_RTL.csv。','', '## 推荐与未完成的验收目标','', f'在两个候选中优先选择 **方案{preferred}** 作为下一轮音源调整与实物试听的候选。方案A覆盖较低音区，避免方案B的80～91高音弱区及87～89尾段门限退出风险，当前统一力度响度离散较小。但所有48～91内部的连续32音窗口都包含MIDI64，因此简单平移音域不能绕过其响度低谷；ALL_32_NOTE_WINDOWS.csv也比较了全部13个窗口。','', '本轮对“当前音源已能生成32个优质不同音高”的结论是**尚未达到验收条件**，不是通过。下一步应针对声源层的跨音区响度/谱包络校准，并复核ROM端点及插值所得音色，保留当前原始WAV作对照，再进行A/B真人听评。此次没有盲目改ROM、按音自动归一化、总增益或包络来掩盖测量结果。硬件接入和同时32Voice触发仍是独立项目。','', '## 44 音逐音主表','', '起音为0～100ms、早期为100～500ms；FX后列同一早期窗口；自然归零为模型长按结果。完整88行、两链路的所有字段在CSV。','', '|MIDI|音名|基频Hz|调音cent|起音RMS dBFS|早期RMS dBFS|Peak dBFS|基音/泛音dB|FX后早期dBFS|自然归零s|','|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for n in NOTES:
        r=metric(n);p=metric(n,'fx_on');lines.append(f'|{n}|{label(n)}|{num(r,"measured_f0_hz"):.3f}|{num(r,"tuning_cents"):.2f}|{num(r,"attack_rms_dbfs_0_100ms"):.2f}|{num(r,"early_rms_dbfs_100_500ms"):.2f}|{num(r,"peak_dbfs"):.2f}|{num(r,"fundamental_to_overtones_db"):.2f}|{num(p,"early_rms_dbfs_100_500ms"):.2f}|{num(r,"natural_held_zero_s_model"):.3f}|')
    lines+=['','## 文件与可复现性','',f'- 当前验证：{link(A/"VALIDATION.json")}；备份：{link(A/"BEFORE.json")}；44音运行结果：{link(A/"AUDIO_RUN.json")}；实际32Voice直接通路：{link(A/"DIRECT_CHAIN.json")}。',f'- 图表：{link(O/"range44_quality.png")}、{link(O/"range44_decay.png")}。',f'- 全部输出：{link(O)}；便携试听包：{link(O/"range44_listening_pack.zip")}，解压后打开LISTENING_ROOM.html。88个单音WAV，加A/B/全44音以及重点相邻音序列，全部24bit、48kHz、相同满刻度。',f'- 源码、FFT/HDMI、两路DAC及约束均未改；本轮未重新执行Gowin、原68项回归，不伪称新通过。当前FS哈希 `{obj["fs_sha256"]}` 与本轮开始快照一致，但开始前就已不同于上一轮BUILD账本。当前process_config也已扩展，生产RTL/约束仍匹配上一轮；不可把上一轮BUILD的PASS转移到现有FS。详见BITSTREAM_PROVENANCE.json；本轮未重验FS或自动烧录。','- 首次沙箱Icarus编译0xC0000005失败及首次FX错误使用SystemVerilog模式的失败日志已保留；沙箱外执行、FX恢复现有Verilog2005模式后通过，无生产RTL修补。','- 复现：`python -X utf8 -B tools/range44_run.py audio`；独立执行`direct`；`range44_analyze.py model`后执行`range44_tail_probe.py`、`range44_tail_rtl.py`；再`range44_analyze.py analyze`，最后`range44_report.py chain`、`report`。历史run目录只用于记录，此次所有44音主WAV均新跑RTL。']
    (R/'docs/SOUND_SOURCE_44_NOTE_RESULTS.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
    audition([dict(x,midi=int(x['midi'])) for x in metrics],cmp)
    acceptance=['# 32 键音源验收目标','',f'更新时间：{now()}。本轮44音功能验证PASS，音质验收{obj["quality_acceptance"]}。','', '1. 当前范围：直接MIDI48～91，共44个不同音高；主候选A48～79、B60～91。检查基频、起音RMS、Peak、衰减、基音/泛音、FX幅值、定点归零。','2. “ROM有参数”或“产生非零PCM”只算通路条件；音域应再通过固定力度响度/音色均匀性、无异常截断和盲听/实物试听验收。当前两个候选均有响度低谷风险，不能宣布32音优质通过。',f'3. 当前相对推荐{preferred}用于后续调整与试听，详见 SOUND_SOURCE_44_NOTE_RESULTS.md。未修改当前16键MIDI映射或音源参数。','4. 两块16键的硬件协议、物理键位、并发输入、同时32Voice触发、最坏混音余量和模拟输出音质，分别后续验收，不由本轮44个单音的结果代替。','5. 必须保留32 Voice、FFT、HDMI、PT8211和PCM5102A。禁止自动烧录。','',link(R/'docs/SOUND_SOURCE_44_NOTE_RESULTS.md','完整测量与推荐报告'),link(O/'LISTENING_ROOM.html','离线试听页面')]
    (R/'docs/SOUND_SOURCE_32KEY_ACCEPTANCE.md').write_text('\n\n'.join(acceptance)+'\n',encoding='utf8')
    status=f'''# PROJECT_STATUS

工程：`{R}`；入口：`{R/'yinyue_fashengqi.gprj'}`。

更新时间：{now()}。最新44音功能验证 **PASS**；32音音质验收 **{obj['quality_acceptance']}**；真人听评与真实上板 **PENDING**。禁止自动烧录。

最新结果见 docs/SOUND_SOURCE_44_NOTE_RESULTS.md、docs/SOUND_SOURCE_32KEY_ACCEPTANCE.md 和 `{A/'VALIDATION.json'}`。44音均新跑Voice/FX RTL、逐样本一致，已提供88个原幅度单音WAV及连续试听。方案{preferred}相对优先，但两个候选尚不能认定具备32个优质音色。

本轮生产RTL/工程/约束/FS零改动，32 Voice、FFT、HDMI和双DAC保留；未来两块16键接入及同时32Voice独立验收。现有顶层仍为16键、逻辑MIDI60～75；真实位序和实体最后四键零VOICE/PEAK根因仍待GAO。原音阶修复和实现证据见 audit/scale_decay_20261017/VALIDATION.json。

当前FS `{R/'impl/pnr/ao_0.fs'}`，SHA256 `{obj['fs_sha256']}`；本轮未重新构建、重验或烧录。该FS及扩展process_config在本轮开始前已不同于上一轮BUILD账本，详情见audit/range44_20261018/BITSTREAM_PROVENANCE.json；不沿用旧FS的PASS作为现有FS的验收结论。
'''
    (R/'docs/PROJECT_STATUS.md').write_text(status,encoding='utf8')
    (R/'README.md').write_text(status.replace('# PROJECT_STATUS','# 当前电子钢琴音源验收工程',1)+'\n离线试听：'+link(O/'LISTENING_ROOM.html')+'\n',encoding='utf8')
    # Portable pack: player and relative wav/ paths work after ordinary extraction.
    pack=O/'range44_listening_pack.zip'
    with zipfile.ZipFile(pack,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for p in [O/'LISTENING_ROOM.html',*(O/'wav').rglob('*.wav'),*O.glob('*.csv'),*O.glob('*.png'),O/'RANGE_COMPARISON.json',O/'WAV_PROVENANCE.json',O/'SEQUENCE_PROVENANCE.json']:
            z.write(p,p.relative_to(O).as_posix())
        z.write(R/'docs/SOUND_SOURCE_44_NOTE_RESULTS.md','SOUND_SOURCE_44_NOTE_RESULTS.md')
        z.writestr('README.txt','解压后用浏览器打开 LISTENING_ROOM.html。所有音使用相同24bit满刻度，无逐音归一化。88个单音WAV均为本轮新RTL；2秒按住+1秒释放，48kHz。连续序列每音3秒后间隔0.25秒。自然长按衰减值为整数模型证据，87/88/89另有6秒RTL实测。功能PASS，音质尚未验收通过。')
    files=[p for folder in [O,A] for p in folder.rglob('*') if p.is_file() and p.name!='OUTPUT_HASHES.json' and 'backup' not in p.parts and 'mplconfig' not in p.parts]
    files += [R/'docs/SOUND_SOURCE_44_NOTE_RESULTS.md',R/'docs/SOUND_SOURCE_32KEY_ACCEPTANCE.md',R/'docs/PROJECT_STATUS.md',R/'README.md',*(R/'tools').glob('range44*.py')]
    dump(A/'OUTPUT_HASHES.json',{'time':now(),'files':{p.relative_to(R).as_posix():{'sha256':sha(p),'bytes':p.stat().st_size} for p in files}})
    print(json.dumps(obj,ensure_ascii=False,indent=2));print('REPORT COMPLETE, recommended relative candidate',preferred)

if __name__=='__main__':globals()[sys.argv[1]]()
