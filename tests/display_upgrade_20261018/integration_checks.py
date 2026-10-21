"""16-key HUD and paired audio preservation, using real integrated portable RTL."""
from pathlib import Path
import sys,os,subprocess,json
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools'))
from continue_audio_audit import sources
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VV=IV.with_name('vvp.exe')
def run(label,args):
    with (O/(label+'.log')).open('w') as f:p=subprocess.run(list(map(str,args)),cwd=R,stdout=f,stderr=subprocess.STDOUT)
    assert p.returncode==0,(label,(O/(label+'.log')).read_text(errors='replace')[-2000:]);print(label,'PASS',flush=True)
def paired():
    text=(R/'audit/display_upgrade_20261018/backup/src/tang_mega_138k_pro_top.v.v').read_text().replace('module tang_mega_138k_pro_top','module baseline_board').replace('parameter DISPLAY_ENABLE = 1','parameter DISPLAY_ENABLE = 0')
    # Adapt only the disabled display boundary ports to share the current stub.
    text=text.replace('wire pixel_clk,serial_clk,video_locked;','wire pixel_clk,serial_clk,video_locked,serial_reset_clk;').replace('visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked);','visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked,serial_reset_clk);').replace(' video_d_p,video_d_n,video_ck_p,video_ck_n);',' video_d_p,video_d_n,video_ck_p,video_ck_n,serial_reset_clk);')
    (O/'baseline_board.v').write_text(text,encoding='utf8')
    text=(R/'tests/integration/video_boundary_stub.v').read_text().replace('always #20 pixel_clk','always #6.734 pixel_clk').replace('always #4 serial_clk','always #1.347 serial_clk')
    text=text.replace('output wire locked);','output wire locked,output wire serial_reset_clk);').replace('assign locked=rst_n;','assign locked=rst_n;assign serial_reset_clk=serial_clk;').replace('output ck_p,ck_n);','output ck_p,ck_n,input reset_clk);')
    (O/'video_boundary_stub.v').write_text(text,encoding='utf8')
    # At30Hz the mailbox may require two video frames after the50ms peak
    # window. Preserve the real window and wait for that completed snapshot.
    tb=(R/'tests/integration/tb_integrated_system.sv').read_text().replace('#74800000;','#109800000;').replace('#100000000;','#140000000;')
    (O/'tb_integrated_system_120ms.sv').write_text(tb)
    import hashlib
    inputs={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (R/'src').rglob('*') if p.is_file()}
    files=[*sources(),O/'baseline_board.v',O/'video_boundary_stub.v','sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/display/sim/tmds_stream_checker.sv',O/'tb_integrated_system_120ms.sv']
    run('paired_compile',[IV,'-g2012','-s','tb_integrated_system','-o',O/'paired.vvp',*files]);run('paired',[VV,O/'paired.vvp'])
    assert 'PASS integrated system' in (O/'paired.log').read_text()
    assert inputs=={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (R/'src').rglob('*') if p.is_file()},'Source changed during simulation'
    (O/'PAIRED.json').write_text(json.dumps({'status':'PASS','input_sha256':inputs,'scope':'Same pre-upgrade top with DISPLAY_ENABLE0 vs new top with display;120ms paired actual PCM/bothDAC pins/keyboard comparison, real FFT/TMDS/status; video lock dropped200us. Device boundary uses clock/serializer stubs; not hardware capture.'},indent=2))
def hud():
    tb='''`timescale 1ns/1ps
module tb_hud16;
reg[9:0]x=0,y=0;reg[57:0]s=0;wire ink,area,on;
piano_status_overlay #(.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) hud(x,y,s,ink,area,on);
integer k,j;reg[7:0]letter[0:15];reg[7:0]acc[0:15];
initial begin
letter[0]="C";letter[1]="C";letter[2]="D";letter[3]="D";letter[4]="E";letter[5]="F";letter[6]="F";letter[7]="G";letter[8]="G";letter[9]="A";letter[10]="A";letter[11]="B";letter[12]="C";letter[13]="C";letter[14]="D";letter[15]="D";
for(k=0;k<16;k=k+1)begin
acc[k]=(k==1||k==3||k==6||k==8||k==10||k==13||k==15)?"#":" ";
s={16'(1<<k),6'd32,24'habcdef,7'(60+k),1'b1,4'd3};
for(j=0;j<16;j=j+1)begin x=10'(8+24*j);y=198;#1;if(!area || on!==(j==k))$fatal(1,"key correspondence%0d/%0d",k,j);end
x=392;#1;if(area)$fatal(1,"seventeenth key");
x=23*8;y=164;#1;if(hud.ch!==letter[k] || hud.bits==0)$fatal(1,"note glyph%0d",k);
x=24*8;#1;if(hud.ch!==acc[k])$fatal(1,"sharp%0d",k);
x=25*8;#1;if(hud.ch!==(k<12?8'd52:8'd53))$fatal(1,"octave%0d",k);
end
$display("PASS16key positions onehot/all note names MIDI60..75; Voice32 does not create32keys");$finish;
end endmodule
'''
    (O/'tb_hud16.sv').write_text(tb)
    run('hud16_compile',[IV,'-g2012','-s','tb_hud16','-o',O/'hud16.vvp',O/'tb_hud16.sv','src/display/piano_status_overlay.sv','src/display/yinse_display_info.sv']);run('hud16',[VV,O/'hud16.vvp'])
    run('status_compile',[IV,'-g2012','-s','tb_status_interfaces','-o',O/'status.vvp','tests/integration/tb_status_interfaces.sv','src/display/piano_status_overlay.sv','src/display/piano_status_cdc.v','src/display/yinse_display_info.sv']);run('status',[VV,O/'status.vvp'])
    (O/'HUD16.json').write_text(json.dumps({'status':'PASS','keys':16,'midi':[60,75],'onehot_pixel_cases':256,'voices_display_max':32,'existing_status_cdc_test':'PASS'}))
if __name__=='__main__':globals()[sys.argv[1]]()
