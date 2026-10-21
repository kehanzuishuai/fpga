"""Integrate the read-only supplied display upgrade into the real piano project."""
from pathlib import Path
from datetime import datetime,timezone,timedelta
import json,hashlib,shutil,sys,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];S=R/'ref/display_upgrade_20261018';A=R/'audit/display_upgrade_20261018';O=R/'tests/display_upgrade_20261018'
assert R==Path(r'D:\gaoyun\piano_v2_audio_fix')
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,z):p.write_text(json.dumps(z,ensure_ascii=False,indent=2),encoding='utf8')
def integrate():
    A.mkdir(exist_ok=True);O.mkdir(exist_ok=True)
    assert not (A/'BEFORE.json').exists(),'Refusing to overwrite baseline'
    files=[p for p in (R/'src').rglob('*') if p.is_file()]+[R/p for p in ['yinyue_fashengqi.gprj','README.md','docs/PROJECT_STATUS.md','impl/yinyue_fashengqi_process_config.json','impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html','impl/gwsynthesis/yinyue_fashengqi.vg']]
    hashes={p.relative_to(R).as_posix():sha(p) for p in files}
    for p in files:
        q=A/'backup'/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
    dump(A/'BEFORE.json',{'time':datetime.now(timezone(timedelta(hours=8))).isoformat(),'files':hashes,'source_directory':'E:/xianshi(shengjiban)','source_copy_sha256':{p.relative_to(S).as_posix():sha(p) for p in S.rglob('*') if p.is_file()},'no_auto_programming':True})
    selected=['visual_raster.v','visual_renderer.sv','visual_labels.sv','visual_xy_source.sv','visual_xy_plot.sv','visual_video_clock.v','visual_tmds.sv','gowin_pll/visual_pll_mod.v','gowin_pll/visual_ref_pll_mod.v']
    for name in selected:shutil.copy2(S/'src'/name,R/'src/display'/name)
    # Preserve the validated local serializer reset routing and existing PLL_INIT.
    for name in ['gowin_pll/visual_pll_mod.v','gowin_pll/visual_ref_pll_mod.v']:
        p=R/'src/display'/name;s=p.read_text();s=s.replace('// Video-only PLL: 1080p30: VCO=50/5*2*74.25=1485MHz; OUT0=371.25, OUT1=74.25MHz.','// Video-only legal two-stage clock tree: 50 ->27 ->371.25/74.25MHz.')
        p.write_text(s,encoding='utf8')
    # Existing combinational HUD remains backwards-compatible for unit tests.
    p=R/'src/display/piano_status_overlay.sv';s=p.read_text().replace('parameter MAPPING_CONFIRMED=1','parameter MAPPING_CONFIRMED=1,parameter INFO_Y=168,DETAIL_Y=184,KEY_X=400,KEY_Y=168,KEY_PITCH=12,KEY_WIDTH=10,KEY_HEIGHT=12')
    s=s.replace('y>=168 && y<175','y>=INFO_Y && y<INFO_Y+7').replace("32'(y)-168","32'(y)-INFO_Y")
    s=s.replace('y>=184 && y<191','y>=DETAIL_Y && y<DETAIL_Y+7').replace("32'(y)-184","32'(y)-DETAIL_Y")
    s=s.replace("key_x=x-10'd400","key_x=x-10'(KEY_X)")
    s=s.replace('x>=400 && x<592 && y>=168 && y<180 && (key_x%12)<10','x>=KEY_X && x<KEY_X+16*KEY_PITCH && y>=KEY_Y && y<KEY_Y+KEY_HEIGHT && (key_x%KEY_PITCH)<KEY_WIDTH')
    s=s.replace("keys[4'(key_x/12)]","keys[4'(key_x/KEY_PITCH)]")
    p.write_text(s,encoding='utf8')
    p=R/'src/display/audio_visualizer.sv';s=(S/'src/audio_visualizer.sv').read_text()
    s=s.replace('parameter SAMPLE_RATE=48000','parameter SAMPLE_RATE=48000,parameter STATUS_ENABLE=0,parameter MAPPING_CONFIRMED=1')
    s=s.replace('output wire [31:0] fft_dropped,wave_dropped,spectrum_dropped\n','output wire [31:0] fft_dropped,wave_dropped,spectrum_dropped,\n input wire [57:0] status_audio\n')
    s=s.replace('wire [7:0] r,g,b;wire de_d,hs_d,vs_d;','wire [7:0] r,g,b;wire render_de,render_hs,render_vs;')
    s=s.replace('r,g,b,de_d,hs_d,vs_d);','r,g,b,render_de,render_hs,render_vs);')
    k=s.index(' visual_tmds enc_b')
    s=s[:k]+''' wire [57:0] status_pixel;
 generate if(STATUS_ENABLE!=0)begin:G_STATUS
 piano_status_cdc mailbox(audio_clk,analysis_rst_n,pcm_valid,status_audio,
                         pixel_clk,display_rst_n,blank_start,status_pixel);
 end else begin:G_NO_STATUS
 assign status_pixel=58'd0;
 end endgenerate
 // Same logical grid as the renderer, including its two pipeline stages.
 reg [9:0] sx1,sy1,sx2,sy2;
 always @(posedge pixel_clk or negedge display_rst_n)
 if(!display_rst_n)begin sx1<=0;sy1<=0;sx2<=0;sy2<=0;end
 else begin sx1<=10'(x/12'd3);sy1<=10'(y/12'd3);sx2<=sx1;sy2<=sy1;end
 wire status_ink,key_area,key_on;
 piano_status_overlay #(.MAPPING_CONFIRMED(MAPPING_CONFIRMED),.INFO_Y(164),.DETAIL_Y(176),
 .KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) hud(
 sx2,sy2,status_pixel,status_ink,key_area,key_on);
 wire show_text=STATUS_ENABLE!=0 && status_ink;
 wire show_key=STATUS_ENABLE!=0 && key_area;
 // Register RGB/control together before the TMDS encoder at74.25MHz.
 reg [7:0] hr,hg,hb;reg de_d,hs_d,vs_d;
 always @(posedge pixel_clk or negedge display_rst_n)
 if(!display_rst_n)begin hr<=0;hg<=0;hb<=0;de_d<=0;hs_d<=0;vs_d<=0;end
 else begin
  de_d<=render_de;hs_d<=render_hs;vs_d<=render_vs;
  hr<=show_text?8'd240:(show_key?(key_on?8'd40:8'd16):r);
  hg<=show_text?8'd240:(show_key?(key_on?8'd240:8'd32):g);
  hb<=show_text?8'd200:(show_key?(key_on?8'd96:8'd48):b);
 end
 visual_tmds enc_b(pixel_clk,display_rst_n,de_d,{vs_d,hs_d},hb,tmds_blue);
 visual_tmds enc_g(pixel_clk,display_rst_n,de_d,2'b00,hg,tmds_green);
 visual_tmds enc_r(pixel_clk,display_rst_n,de_d,2'b00,hr,tmds_red);
endmodule
`default_nettype wire
'''
    p.write_text(s,encoding='utf8')
    p=R/'src/integrated.sdc';s=p.read_text();lines=s.splitlines()
    lines=[line for line in lines if not line.startswith('create_generated_clock -name video_')]
    insert=next(i for i,line in enumerate(lines) if line.startswith('# All audio'))
    lines[insert:insert]=[
    'create_generated_clock -name video_ref -source [get_ports {clk_50m}] -multiply_by 27 -divide_by 50 [get_pins {u_video_clock/ref_pll/PLL_inst/CLKOUT0}]',
    'create_generated_clock -name video_serial -source [get_pins {u_video_clock/ref_pll/PLL_inst/CLKOUT0}] -multiply_by 55 -divide_by 4 [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT0}]',
    'create_generated_clock -name video_pixel -source [get_pins {u_video_clock/ref_pll/PLL_inst/CLKOUT0}] -multiply_by 11 -divide_by 4 [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT1}]']
    s='\n'.join(lines)+'\n';s=s.replace('{video_pixel video_serial}','{video_ref video_pixel video_serial}');p.write_text(s,encoding='utf8')
    p=R/'yinyue_fashengqi.gprj';s=p.read_text();new=['src/display/visual_xy_source.sv','src/display/visual_xy_plot.sv','src/display/gowin_pll/visual_ref_pll_mod.v']
    assert all(path not in s for path in new)
    s=s.replace('    </FileList>','        <!--1080p30 display upgrade; existing16-key status retained. -->\n'+''.join(f'        <File path="{path}" type="file.verilog" enable="1"/>\n' for path in new)+'    </FileList>')
    p.write_text(s,encoding='utf8')
    active=[e.attrib['path'] for e in ET.parse(p).findall('./FileList/File') if e.attrib.get('enable')=='1'];assert len(active)==67
    protected={path:h for path,h in hashes.items() if path.startswith('src/') and not path.startswith('src/display/') and path!='src/integrated.sdc'}
    assert all(sha(R/path)==h for path,h in protected.items())
    dump(A/'INTEGRATED.json',{'status':'PASS','enabled_files':active,'new_enabled':new,'source_copy':str(S),'preserved_16_key_mapping':True,'keyboard_keys':16,'audio_voices':32,'protected_audio_and_pins_sha256':protected,'no_auto_programming':True})
    (R/'docs/DISPLAY_UPGRADE_16KEY_20261018.md').write_text('# 显示升级：保留16键\n\n已合入1080p30/中文/16bit X-Y升级，保留16键状态。验证与构建进行中，当前FS尚不可作为新版交付。没有自动烧录。\n',encoding='utf8')
    print('Integrated display upgrade.67 enabled inputs; audio/pins/mapping preserved.',flush=True)
if __name__=='__main__':globals()[sys.argv[1]]()
