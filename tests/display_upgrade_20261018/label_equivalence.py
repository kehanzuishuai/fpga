"""Every logical pixel against the supplied font, with the two new stages."""
from pathlib import Path
import subprocess,json
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VV=IV.with_name('vvp.exe')
s=(R/'ref/display_upgrade_20261018/src/visual_labels.sv').read_text(encoding='utf8').replace('module visual_labels','module original_labels')
(O/'original_labels.sv').write_text(s,encoding='utf8')
(O/'tb_labels.sv').write_text('''`timescale 1ns/1ps
module tb_labels;
reg clk=0,rst=0;always#5 clk=~clk;
reg[9:0]x=0,y=0;reg[15:0]hz=0;reg valid=0,direct=0,signal_valid=0,mixed=0;
wire a,b;reg[1:0]expected=0;integer xx,yy,mode,checks=0;
visual_labels n(x,y,valid,hz,direct,signal_valid,mixed,6'sd0,a,clk,rst);
original_labels o(x,y,valid,hz,direct,signal_valid,mixed,6'sd0,b);
always@(posedge clk)expected<={expected[0],b};
initial begin
repeat(3)@(negedge clk);rst=1;
for(mode=0;mode<4;mode=mode+1)begin
 valid=mode!=0;hz=mode==1?16'd7:mode==2?16'd24000:16'd441;
 signal_valid=mode!=0;direct=mode==2;mixed=mode==3;
 repeat(24)@(negedge clk);
 for(yy=0;yy<360;yy=yy+1)for(xx=0;xx<640;xx=xx+1)begin
  @(negedge clk);x=10'(xx);y=10'(yy);
  @(posedge clk);#1;if(a!==expected[1])$fatal(1,"font mismatch mode%0d at%0d,%0d",mode,xx,yy);checks=checks+1;
 end
end
$display("PASS %0d label pixels exactly equal supplied font with2cycle latency",checks);$finish;
end endmodule
''')
for name,args in [('compile',[IV,'-g2012','-s','tb_labels','-o',O/'labels.vvp',O/'tb_labels.sv',O/'original_labels.sv',R/'src/display/visual_labels.sv']),('run',[VV,O/'labels.vvp'])]:
    z=subprocess.run(list(map(str,args)),cwd=R,capture_output=True);(O/('labels_'+name+'.log')).write_bytes(z.stdout+z.stderr);print(name,z.returncode,flush=True);assert z.returncode==0,z.stdout+z.stderr
(O/'LABEL_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','pixels':921600,'modes':4,'font_reference':'Supplied display upgrade','added_latency_cycles':2},indent=2))
(O/'tb_hud_pipeline.sv').write_text('''`timescale 1ns/1ps
module tb_hud_pipeline;
reg clk=0,rst=0;always#5 clk=~clk;
reg[9:0]x=0,y=0;reg[57:0]s=0;wire a,b,aa,ab,oa,ob;
reg[5:0]expected=0;integer xx,yy,k,checks=0;
piano_status_overlay #(.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) o(x,y,s,b,ab,ob);
piano_status_overlay_pipeline #(.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) n(x,y,s,clk,rst,a,aa,oa);
always@(posedge clk)expected<={expected[2:0],b,ab,ob};
initial begin
repeat(3)@(negedge clk);rst=1;
for(k=0;k<16;k=k+1)begin
 @(negedge clk);s={16'(1<<k),6'(2*k+1),24'habcd12,7'(60+k),1'b1,4'(k)};
 repeat(4)@(negedge clk);
 for(yy=164;yy<208;yy=yy+1)for(xx=0;xx<640;xx=xx+1)begin
  @(negedge clk);x=10'(xx);y=10'(yy);
  @(posedge clk);#1;if({a,aa,oa}!==expected[5:3])$fatal(1,"HUD pipeline mismatch key%0d at%0d,%0d",k,xx,yy);checks=checks+1;
 end
end
$display("PASS %0d HUD pixels16notes/onehotkeys inclB;2cycle latency",checks);$finish;
end endmodule
''')
for name,args in [('compile',[IV,'-g2012','-s','tb_hud_pipeline','-o',O/'hud_pipeline.vvp',O/'tb_hud_pipeline.sv',R/'src/display/piano_status_overlay.sv',R/'src/display/yinse_display_info.sv']),('run',[VV,O/'hud_pipeline.vvp'])]:
    z=subprocess.run(list(map(str,args)),cwd=R,capture_output=True);(O/('hud_pipeline_'+name+'.log')).write_bytes(z.stdout+z.stderr);print('hud',name,z.returncode,flush=True);assert z.returncode==0,z.stdout+z.stderr
(O/'HUD_PIPELINE.json').write_text(json.dumps({'status':'PASS','pixels':450560,'notes':16,'onehot_keys':16,'added_latency_cycles':2},indent=2))
