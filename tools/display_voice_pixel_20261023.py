"""Reduce the scene voice indicator metadata to two per-pixel flags early."""
import re

def select_voice_pixel(source):
    if 'logic voice_pixel_shape,voice_pixel_active;' in source:return source
    marker=' } pixel_state;';assert source.count(marker)==1
    source=source.replace(marker,'  logic voice_pixel_shape,voice_pixel_active;\n'+marker)
    # Keep precisely the same rounded rectangles, merely evaluate in stage0.
    hits=re.findall(r'd\.voice_hits\[\d+\]=rounded\([^;]+;',source)
    assert len(hits)==32
    for line in hits:source=source.replace(line,'')
    first=source.index(' begin:STAGE_0 ');end=source.index(' begin:STAGE_1 ',first)
    section=source[first:end]
    marker="  d.sx=32'(x);d.sy=32'(y);d.dx=32'($signed(drift_x));d.dy=32'($signed(drift_y));"
    assert section.count(marker)==1
    section=section.replace(marker,marker+'\nif(MATERIAL_SAMPLE==0)begin\n'+'\n'.join(hits)+'\nend')
    source=source[:first]+section+source[end:]
    first=source.index(' begin:STAGE_1 ');end=source.index(' begin:STAGE_2 ',first)
    section=source[first:end];marker='   d=incoming;';assert section.count(marker)==1
    section=section.replace(marker,marker+'''
 // Both operands describe the same pixel captured at stage0. No change
 // in scene publication time or the independent audio voice bank.
 d.voice_pixel_shape=|incoming.voice_hits;
 d.voice_pixel_active=|(incoming.voice_hits & incoming_status[50+:32]);
 d.voice_hits=32'd0;
 d.status_data={incoming_status[511:82],32'd0,incoming_status[49:0]};''')
    source=source[:first]+section+source[end:]
    old='if(|d.voice_hits)begin';assert source.count(old)==1
    source=source.replace(old,'if(d.voice_pixel_shape)begin')
    old='|(d.voice_hits & incoming_status[50+:32])';assert source.count(old)==1
    return source.replace(old,'d.voice_pixel_active')
