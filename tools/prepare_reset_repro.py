from pathlib import Path
R=Path(__file__).resolve().parents[1]
p=R/'audit/continuation_20261017/backup/tests/audio_diagnosis/tb_audio_note_map.sv'
s=p.read_text().replace('module tb_audio_note_map;','module tb_pcm_reset_repro;')
s=s.replace('current_key<16','current_key<2').replace('on_count!=16 || off_count!=16 || checked!=16','on_count!=2 || off_count!=2 || checked!=2')
s=s.replace('tests/audio_diagnosis/chain_stage_samples.csv','tests/continuation_20261017/repro_stage_samples.csv').replace('tests/audio_diagnosis/partial_products.csv','tests/continuation_20261017/repro_partial_products.csv')
s=s.replace('if(pcm_check.errors ||', '$display("ORIGINAL checker counters data=%0d pad=%0d length=%0d delay=%0d frames=%0d nonzero=%0d",pcm_check.errors,pcm_check.pad_errors,pcm_check.len_errors,pcm_check.delay_errors,pcm_check.frames_ok,pcm_check.nonzero);\n if(pcm_check.errors ||')
s='// Targeted FAIL reproduction: original stimulus/checks, first TWO reset epochs only.\n// This is not a passing or full mapping regression. Original 16-key source preserved in backup.\n'+s
(R/'tests/continuation_20261017/tb_pcm_reset_repro.sv').write_text(s,encoding='utf8')
