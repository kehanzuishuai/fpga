from pathlib import Path
r=Path(__file__).resolve().parents[1]
p=r/'src/display/piano_status_overlay.sv';s=p.read_text(encoding='utf-8')
s=s.replace('parameter MAPPING_CONFIRMED=1','parameter REMOTE_STATUS=0,parameter MAPPING_CONFIRMED=1')
s=s.replace('piano_status_decode #(.MAPPING_CONFIRMED','piano_status_decode #(.REMOTE_STATUS(REMOTE_STATUS),.MAPPING_CONFIRMED')
s=s.replace('// This build selects only the original piano: ID0 is real, fixed state.','// In the integrated build the existing status mailbox carries actual timbre and switching.')
s=s.replace("yinse_display_info instrument(3'd0,1'b0,", "yinse_display_info instrument(REMOTE_STATUS?status[2:0]:3'd0,REMOTE_STATUS?status[3]:1'b0,")
s=s.replace('24:ch=8\'d83;\n    25:ch=8\'d84;\n    26:ch=8\'d65;\n    27:ch=8\'d71;\n    28:ch=8\'d69;', '''24:ch=REMOTE_STATUS?"S":8'd83;
    25:ch=REMOTE_STATUS?"W":8'd84;
    26:ch=REMOTE_STATUS?"I":8'd65;
    27:ch=REMOTE_STATUS?"T":8'd71;
    28:ch=REMOTE_STATUS?"C":8'd69;''')
s=s.replace('30:ch=hexchar(stage);','30:ch=REMOTE_STATUS?(switching?"1":"0"):hexchar(stage);')
p.write_text(s,encoding='utf-8')
p=r/'src/display/audio_visualizer.sv';s=p.read_text(encoding='utf-8')
s=s.replace('parameter STATUS_ENABLE=0','parameter REMOTE_STATUS=0,parameter STATUS_ENABLE=0')
s=s.replace('piano_status_overlay_pipeline #(.MAPPING_CONFIRMED','piano_status_overlay_pipeline #(.REMOTE_STATUS(REMOTE_STATUS),.MAPPING_CONFIRMED')
p.write_text(s,encoding='utf-8')
p=r/'src/tang_mega_138k_pro_top.v.v';s=p.read_text(encoding='utf-8')
s=s.replace('status_note,status_note_valid,4\'(BUILD_STAGE)', 'status_note,status_note_valid,switching,actual_instrument')
s=s.replace('.STATUS_ENABLE(1),','.STATUS_ENABLE(1),.REMOTE_STATUS(1),')
p.write_text(s,encoding='utf-8')
