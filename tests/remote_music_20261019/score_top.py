"""Phone score timbre is isolated from physical piano, including stop/rearm."""
from run import ROOT,OUT,run,sources,IVER,VVP
s=(ROOT/'tests/remote_music_20261019/tb_control.sv').read_text()
helpers=s[s.index(' function automatic [15:0] crc'):s.index(' integer old_on')]
tb=r'''`timescale 1ns/1ps
module tb_score_top;
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
 if(dut.synth_rst_n && dut.bridge_reset_n &&
    (dut.actual_instrument!=0 || |dut.u_synth_top.u_synth.u_core.G_AUX.bank.active_mask))
  $fatal(1,"physical keys enabled before auxiliary notes were cleared and piano restored");
end
pcm5102_frame_check pcm_check(clk,dut.synth_rst_n,dut.remote_tick,dut.u_synth_top.final_left,dut.u_synth_top.final_right,pbc,plr,pda);
''' + helpers + r'''
integer frames,heard,vn;reg [31:0] heard_voices;
initial begin
 #100;rst=1;wait(dut.synth_rst_n);#100000;
 request(8'h11,1,2,0);
 if(dut.actual_instrument!=0 || dut.u_remote.selected_instrument!=2)$fatal(1,"phone preference changed physical instrument");
 request(8'h30,1,1,0);request(8'h31,5,{8'd0,16'd500,8'd100,8'd64,8'd0},0);request(8'h32,0,0,0);
 request(8'h15,1,1,0);wait(dut.score_playing && !dut.switching && dut.actual_instrument==2);
 wait(dut.active_voice_count==1);frames=0;heard=0;
 while(frames<256)begin @(posedge clk);#2;if(dut.remote_tick)begin
  frames=frames+1;if(dut.u_synth_top.final_left!=0)heard=heard+1;
  if(|dut.u_synth_top.u_synth.u_core.piano_active)$fatal(1,"score flute layered with piano");
 end end
 if(heard<200)$fatal(1,"phone score flute silent");
 touch=16'hffff;touch2=16'hffff;wait(dut.key_state32==32'hffffffff);
 if(dut.active_voice_count!=1 || dut.bridge_reset_n)$fatal(1,"physical keys interrupted score ownership");
 request(8'h15,1,0,0);wait(!dut.score_playing && !dut.switching);
 wait(dut.active_voice_count==32);frames=0;heard_voices=0;
 while(frames<256)begin @(posedge clk);#2;if(dut.remote_tick)begin
  frames=frames+1;
  if(dut.actual_instrument!=0 || |dut.u_synth_top.u_synth.u_core.aux_active)$fatal(1,"auxiliary timbre leaked into physical piano");
  for(vn=0;vn<32;vn=vn+1)if(dut.u_synth_top.u_synth.u_core.samples[vn*24+:24]!=0)heard_voices[vn]=1;
 end end
 if(heard_voices!=32'hffffffff || pcm_check.errors!=0)$fatal(1,"restored piano32/DAC failure");
 $display("PASS phone-only flute score, exclusive ownership, graceful final NoteOff, clear auxiliary bank, then all 32 held physical keys rearmed as piano; %0d exact PCM5102 frames",pcm_check.u_rx.frames);$finish;
end
initial begin #150000000;$fatal(1,"score top timeout");end
endmodule
'''
(OUT/'tb_score_top.sv').write_text(tb)
run('score_top_compile',[IVER,'-g2012','-s','tb_score_top','-o',OUT/'score_top.vvp',*sources(),OUT/'tb_score_top.sv','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v'])
run('score_top',[VVP,OUT/'score_top.vvp'],1800)
