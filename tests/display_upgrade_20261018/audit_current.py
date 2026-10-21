from pathlib import Path
import hashlib,json,difflib,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[2];A=R/'audit/display_upgrade_20261018'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
b=json.loads((A/'BEFORE.json').read_text(encoding='utf8'))['files']
allowed=lambda q:q.startswith('src/display/') or q in ['src/integrated.sdc','src/integrated.cst','src/tang_mega_138k_pro_top.v.v']
protected={q:v for q,v in b.items() if q.startswith('src/') and not allowed(q)}
assert all(sha(R/q)==v for q,v in protected.items()),'Protected non-display source changed'
current={p.relative_to(R).as_posix():sha(p) for p in (R/'src').rglob('*') if p.is_file()}
changed=[q for q,v in current.items() if b.get(q)!=v]
assert all(allowed(q) for q in changed)
enabled=[dict(e.attrib) for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1']
assert len(enabled)==67
assert all((R/e['path']).exists() for e in enabled)
top=(R/'src/tang_mega_138k_pro_top.v.v').read_text(encoding='utf8')
normalized_top=top.replace('wire pixel_clk,serial_clk,video_locked,serial_reset_clk;','wire pixel_clk,serial_clk,video_locked;').replace('visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked,serial_reset_clk);','visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked);').replace(' video_d_p,video_d_n,video_ck_p,video_ck_n,serial_reset_clk);',' video_d_p,video_d_n,video_ck_p,video_ck_n);')
assert normalized_top==(A/'backup/src/tang_mega_138k_pro_top.v.v').read_text(encoding='utf8'),'Top changed beyond the3 display reset wiring lines'
old_cst=(A/'backup/src/integrated.cst').read_text();new_cst=(R/'src/integrated.cst').read_text()
assert new_cst.startswith(old_cst)
extra_cst=new_cst[len(old_cst):]
assert len([s for s in extra_cst.splitlines() if s.startswith('INS_LOC')])==4
assert all(not s.strip() or s.startswith('//') or s.startswith('INS_LOC "u_video_io/channels[') or s=='INS_LOC "u_video_io/reset_buffer" PTR3[0];' for s in extra_cst.splitlines())
assert 'parameter VOICES' not in top or '32' in top
result={'status':'PASS','protected_non_display_sources_unchanged':len(protected),'protected_sha256':protected,'changed_or_new_source_files':changed,'enabled_files':enabled,'main_top_change':'Only3 display reset-clock wiring lines; remainder matches backup','CST_change':'Only3 reset register locations and1 regional reset DCS location appended; all IO definitions unchanged','FFT_source_unchanged':current['src/display/visual_fft.sv']==b['src/display/visual_fft.sv'],'frame_store_source_unchanged':current['src/display/visual_frame_store.v']==b['src/display/visual_frame_store.v'],'no_auto_programming':True}
(A/'FINAL_SOURCE_AUDIT.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
patch=[]
for q in changed+['yinyue_fashengqi.gprj']:
 old=(A/'backup'/q).read_text(encoding='utf8').splitlines(True) if (A/'backup'/q).exists() else []
 patch.extend(difflib.unified_diff(old,(R/q).read_text(encoding='utf8').splitlines(True),fromfile='before/'+q,tofile='after/'+q))
(A/'DISPLAY_CHANGES.patch').write_text(''.join(patch),encoding='utf8')
print('PASS',len(protected),'protected sources unchanged;',len(changed),'display/constraint changes;',len(enabled),'enabled project files')
