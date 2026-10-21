"""Real physical32 keys stay piano under every phone score-timbre selection."""
from run import ROOT,OUT,run,sources,IVER,VVP
s=(ROOT/'tests/remote_music_20261019/tb_control.sv').read_text()
helpers=s[s.index(' function automatic [15:0] crc'):s.index(' integer old_on')]
tb=r'''`timescale 1ns/1ps
module tb_audio_top;
reg clk50=0,rst=0,rx=1;always #10 clk50=~clk50;
reg [15:0] touch=0,touch2=0;wire scl,sdo,scl2,sdo2,tx,bc,lr,da,pbc,plr,pda;
ttp229_bfm #(.KEY16(1),.MULTI(1)) b0(touch,scl,sdo),b1(touch2,scl2,sdo2);
tang_mega_138k_pro_top #(.DISPLAY_ENABLE(0)) dut(.clk_50m(clk50),.rst_n(rst),
 .esp_uart_rx(rx),.esp_uart_tx(tx),.esp_spi_sck(1'b0),.esp_spi_cs_n(1'b1),.esp_spi_mosi(1'b0),
 .ttp229_scl(scl),.ttp229_sdo(sdo),.ttp229_2_scl(scl2),.ttp229_2_sdo(sdo2),
 .i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda));
wire clk=dut.clk_12m288;
wire got,framing;wire [7:0] reply_byte;
wifi_uart_rx receiver(clk,dut.synth_rst_n,tx,reply_byte,got,framing);
reg [7:0] reply[0:15],packet[0:15];integer reply_count=0,sequence_id=1;
always @(posedge clk)begin
 if(framing)$fatal(1,"UART reply framing");
 if(got)begin if(reply_count>=16)$fatal(1,"extra reply");reply[reply_count]=reply_byte;reply_count=reply_count+1;end
 if(dut.engine_clear && dut.synth_gain!=0)$fatal(1,"switch clear audible");
end
pcm5102_frame_check pcm_check(clk,dut.synth_rst_n,dut.remote_tick,dut.u_synth_top.final_left,dut.u_synth_top.final_right,pbc,plr,pda);
''' + helpers + r'''
integer n,frames,vn;reg [31:0] heard_voices;
always @(posedge clk)if(dut.synth_rst_n && !dut.score_playing)begin
 if(dut.actual_instrument!=0 || dut.switching || dut.engine_clear || dut.synth_gain!=65535)
  $fatal(1,"phone timbre selection interrupted physical piano");
 if(|dut.u_synth_top.u_synth.u_core.G_AUX.bank.active_mask)
  $fatal(1,"physical keys activated an auxiliary instrument");
end
initial begin
 #100;rst=1;wait(dut.synth_rst_n);#100000;touch=16'hffff;touch2=16'hffff;
 wait(dut.key_state32==32'hffffffff);wait(dut.active_voice_count==32);
 for(n=0;n<5;n=n+1)begin
  request(8'h11,1,48'(n),0);
  if(dut.u_remote.selected_instrument!=n || dut.actual_instrument!=0)$fatal(1,"score selection/piano routing");
  frames=0;heard_voices=0;
  while(frames<256)begin @(posedge clk);#2;if(dut.remote_tick)begin
   frames=frames+1;
   for(vn=0;vn<32;vn=vn+1)
    if(dut.u_synth_top.u_synth.u_core.samples[vn*24+:24]!=0)heard_voices[vn]=1;
   if(^dut.u_synth_top.final_left===1'bx)$fatal(1,"unknown PCM");
  end end
  if(heard_voices!=32'hffffffff || dut.active_voice_count!=32)$fatal(1,"physical piano32 missing voice %h",heard_voices);
  $display("PASS physical32 piano under phone selection %0d: all 32 piano voices heard, auxiliary masks zero, no fade/reset",n);$fflush();
 end
 request(8'h12,2,0,0);wait(dut.master_volume==0);repeat(300)@(negedge clk);
 if(dut.u_synth_top.final_left!=0 || dut.u_synth_top.final_right!=0)$fatal(1,"master mute");
 if(pcm_check.errors!=0)$fatal(1,"DAC mismatch");
 $display("PASS full board physical32 piano only under all five phone score selections; master mute; %0d exact PCM5102 frames",pcm_check.u_rx.frames);$finish;
end
initial begin #300000000;$fatal(1,"audio top timeout");end
endmodule
'''
OUT.mkdir(exist_ok=True);(OUT/'tb_audio_top.sv').write_text(tb)
files=[*sources(),OUT/'tb_audio_top.sv','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v']
run('audio_top_compile',[IVER,'-g2012','-s','tb_audio_top','-o',OUT/'audio_top.vvp',*files])
run('audio_top',[VVP,OUT/'audio_top.vvp'],2400)
