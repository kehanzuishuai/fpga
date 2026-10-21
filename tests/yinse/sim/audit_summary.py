"""Aggregate evidence without turning skipped or failed checks into PASS."""
from pathlib import Path
import json,re,hashlib,collections,math
BASE=Path(__file__).resolve().parents[2];OUT=BASE/'yinse/sim/audit'
def read(path):
    p=Path(path);return p.read_text(encoding='utf-8',errors='replace') if p.exists() else ''
def load(path):
    text=read(path);return json.loads(text) if text else {}
def test_log(name):
    text=read(OUT/(name+'.log'))
    if 'FATAL:' in text or '%Error:' in text:return 'FAIL'
    return 'PASS' if 'PASS' in text else 'INCOMPLETE'
inventory=load(OUT/'resource_inventory.json')
parts=['piano32','visual','aux16','keyboard_reader','keyboard_bridge','controls','mux']
bits=sum(inventory[k]['memory_bits'] for k in parts)
runtime=sum(inventory[k]['runtime_multipliers'] for k in parts)
tile=lambda m:min(math.ceil(m['a']/27)*math.ceil(m['b']/36),math.ceil(m['a']/36)*math.ceil(m['b']/27))
proxy=sum(tile(m) for k in parts for m in inventory[k]['multipliers'] if not m['constant'])
warnings=collections.Counter(re.findall(r'^%Warning-([A-Z0-9_]+):',read(OUT/'current_piano_lint.log'),re.M))
original=load(OUT/'original_hashes.json')
changed=[name for name,h in original.items() if not(BASE/name).exists() or hashlib.sha256((BASE/name).read_bytes()).hexdigest()!=h]
board=load(OUT/'original/boards/tang_mega_138k_pro/sim_out_visual/regression_summary.json')
aux=load(BASE/'yinse/sim/out/report.json')
legacy='PASS' if 'REGRESSION PASS' in read(OUT/'legacy_root.log') else 'FAIL_OR_INCOMPLETE'
checks={'yinse':aux.get('status','INCOMPLETE'),'legacy_rtl':legacy,'board_package':board.get('status','INCOMPLETE'),
        'current_piano_native_two_state':load(OUT/'current_native_result.json').get('status','INCOMPLETE'),
        'current_piano_four_state_long': 'STOPPED_DUPLICATE_AFTER_NATIVE_COMPLETED' if 'STOPPED_DUPLICATE' in read(OUT/'current_piano.log') else test_log('current_piano'),
        'current_velocity_zero_four_state':test_log('current_piano_zero'),
        'current_strict_lint':test_log('current_piano_lint'),'original_files':'FAIL' if changed else 'PASS',
        'gowin_implementation':'SKIPPED_USER_CONFIRMED_NOT_INSTALLED','integrated_full_system':'NOT_YET_CONNECTED','hardware':'NOT_RUN'}
result={'status':'OPEN_ISSUES','checks':checks,'original_tracked_files':len(original),'changed_original_files':changed,
        'device':'GW5AST-LV138FPG676AC1/I0','estimate_only':True,'memory_bits_components':bits,'device_bsram_bits':6120*1024,
        'logical_storage_vs_bsram_capacity_percent':100*bits/(6120*1024),'runtime_multipliers':runtime,
        'unshared_27x36_tiles_proxy':proxy,'actual_lut_dsp_bsram_utilization':None,'timing_pass':None,'current_lint_warning_types':dict(warnings)}
(OUT/'summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
rows='\n'.join(f'| {k} | {inventory[k]["memory_bits"]:,} | {inventory[k]["runtime_multipliers"]} |' for k in parts)
text=f'''# 资源与全量回归审计

结论：已发现并修复 yinse 淡入期间丢新按键的问题；原 src 仍有失败项。不能把这套工程标成“全绿”或“器件资源已经确保”。

## 回归结果

'''+ '\n'.join(f'- {k}: **{v}**' for k,v in checks.items())+f'''

新增音色回归结果共 {len(aux.get('results',[]))} 条，详见 ../out/report.md。其中全音域测试涵盖4音色×61音符=244项，力度按音符循环覆盖1/127/255，验证有声音、初始化/清理、无X/削顶/超时；不是244项精确音高测量。单音及复音频谱另行检查。

原工程 {len(original)} 个跟踪文件 SHA-256 {'保持不变' if not changed else '发生改变，请检查JSON'}。旧 rtl 测试、boards 板级旧音源测试和当前 src 新钢琴测试分开报告，不能互相替代。测试快照及产物都在 yinse 内，快照 runner 仅修改工具路径；RTL 保持原字节。

当前 src 的32声部压力检查使用Verilator编译执行原始源码，共20553帧，覆盖加载背压、256时钟预算、抢占、明确NoteOff/释放及复位。该仿真是二值，不证明X传播；零力度NoteOn的失败复现使用四值Icarus。耗时的同类Icarus长测试在编译仿真完成后停止，**不计为PASS**。独立yinse与板级回归仍使用Icarus四值仿真。native构建保留全部lint诊断，仅允许带诊断构建以检查功能；严格lint单独记FAIL，没有屏蔽警告或把构建成功称为零警告。

## 资源盘点（估算，未完成器件实现）

| 组成 | 逻辑存储 bit | 运行时乘法表达式 |
|---|---:|---:|
{rows}
| 合计 | {bits:,} | {runtime} |

目标型号来自根 .gprj。官方规格为138240 LUT4、340块BSRAM（6120 Kibit）、298 DSP；参考 [Gowin Arora V 官方规格](https://gowinsemi.com/en/product/arora-v-fpga/)。本表把现有钢琴、已有板级显示、辅助16声部及键盘/控制/mux相加，作为后续合并的盘点，尚无一个接好它们的完整顶层。

逻辑存储总量相当于标称BSRAM bit容量的 {100*bits/(6120*1024):.2f}%；该比值**不是实际BSRAM利用率**。同步/异步ROM、读写端口、宽度碎片和共享会改变映射。开源GW5A RAM映射将辅助16声部的KS延迟线映射成32个DPX9B；仍有32个ROM内存表达式，不能把它们也当作已映射块RAM。

运行时乘法按独立27×36块粗拆为 {proxy} 个运算块，仅用于说明宽度与规模，**不是DSP占用**；不含常数乘法的工具选择、自动共享及最终打包。当前开源 synth_gowin 的GW5A流程未提供同等DSP自动推断，不能用其LUT实现替代Gowin结论。PLL、IO、OSER10和布局布线也未验证。

## 仍需处理的问题

1. **当前钢琴 velocity-zero NoteOn 没有转换成NoteOff。** tb_current_piano_zero 已复现：starts非零、stops为零。应在公共事件入口把 `note_on && velocity==0` 转成NoteOff，再验证重复键、松键和声部分配；本轮不越界改src。
2. **当前 src 严格lint失败。** 共 {sum(warnings.values())} 条诊断，分类见summary.json，完整位置见current_piano_lint.log。部分是文件尾换行/未用信号，部分是位宽，需要逐项确认，不能将111条诊断全部称为功能错误。
3. **合并入口尚未完成。** 根 .gprj 仍是新钢琴/PT8211工程；屏幕与PCM5102A在boards工程，多音色在yinse。旧音色清理、FIFO清理、钢琴loader安全接口、效果器尾音、DAC采样对齐及音色显示CDC尚不能通过一个整机回归证明。
4. **loader_busy不能接顶层event_ready的反相。** 顶层ready是FIFO容量；应取voice_bank实际ld_busy或frontend内部core_ready。
5. **不要直接把当前钢琴VOICES改16。** src/voice_bank有固定32位匹配/循环；降低辅助bank到4或8与钢琴参数无关。
6. 辅助满声部抢占目前直接重触发，仍可能有点击声；硬件触摸键模式、接线和实物声音尚未验证。

## 已修复及后续顺序

yinse_switch 在新音色提交且clear/flush结束后允许淡入期间的新NoteOn，避免唯一按下沿被丢弃；淡出、旧键未松和加载未完成时仍阻止新NoteOn。自动边界测试已加入run_tests.py。

建议先以辅助4声部接入并完成ID0钢琴逐样本不变、切换/松键/尾音及双DAC/显示联调，再扩展16声部；保持32钢琴声部。用户确认未安装Gowin，按要求跳过相关验证；安装后对最终顶层跑综合及布局布线，建议LUT/DSP/BSRAM各留至少20%余量，且所有受约束时钟通过，才能确认资源和时序。

复现命令（在D:/fpga26）：

```powershell
D:/anaconda/python.exe -B yinse/sim/run_tests.py
D:/anaconda/python.exe -B yinse/sim/full_audit.py original
D:/anaconda/python.exe -B yinse/sim/full_audit.py current
D:/anaconda/python.exe -B yinse/sim/full_audit.py resource
D:/anaconda/python.exe -B yinse/sim/audit_summary.py
```

保留失败测试，不屏蔽警告，不用过去报告代替本轮结果。每项的完整日志和测试快照均在本目录。
'''
(OUT/'README.md').write_text(text,encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
