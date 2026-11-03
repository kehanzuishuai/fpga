`timescale 1ns/1ps
module tb_expression_audio;
 GSR GSR(.GSRI(1'b1));
 reg clk50=0,rst_n=0;always #10 clk50=~clk50;
 reg tone_button=1,source_button=1,tl_rx=1;reg [31:0] touch=0;
 wire bc,lr,da,pbc,plr,pda;
 tang_mega_138k_pro_top #(.DISPLAY_ENABLE(0),.BUTTON_DEBOUNCE_CYCLES(8)) dut(
  .clk_50m(clk50),.rst_n(rst_n),.timbre_button_n(tone_button),.source_button_n(source_button),.theremin_uart_rx(tl_rx),
  .esp_uart_rx(1'b1),.esp_uart_tx(),.esp_spi_cs_n(1'b1),.esp_spi_mosi(1'b0),.esp_spi_miso(),
  .ttp229_scl(),.ttp229_sdo(1'b1),.ttp229_2_scl(),.ttp229_2_sdo(1'b1),
  .i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda));
 wire clk=dut.clk_12m288;
 i2s_rx_model rx(pbc,plr,pda);
 reg pkt=0;reg [7:0] seq=0,cmd=0,len=0;reg [47:0] payload=0;reg [31:0] reply;
 integer tone,audio_file;reg [1023:0] audio_path;initial begin if(!$value$plusargs("PCM=%s",audio_path))$fatal(1,"PCM path missing");audio_file=$fopen(audio_path,"w");end
 integer i,j,frames_written=0,pt_index=-1,pt_bits=0,pt_words=0,pcm_frames=0;
 reg signed [23:0] expected[0:32767];reg [15:0] pt_shift=0;reg pt_started=0,pt_channel=0;
 integer heard=0,ons=0,clears=0,tl_clears=0,prior,old_tl_clears;
 reg measuring=0;reg [31:0] seen=0;reg [2:0] measured_timbre=0;
 reg tl_send=1;reg [7:0] tl_flags=8'h0b;integer tl_seq=0;
 always @(posedge clk)if(dut.synth_rst_n)begin
  if(dut.visual_pcm_valid)begin $fdisplay(audio_file,"%h %h",dut.display_left,dut.display_right);expected[frames_written]=dut.display_left;frames_written=frames_written+1;end
  if(dut.key_event_accepted && dut.event_note_on)ons=ons+1;
  if(dut.engine_clear)clears=clears+1;
  if(dut.theremin_clear)tl_clears=tl_clears+1;
  if(dut.switch_fault)$fatal(1,"real engine clear did not acknowledge");
  if(measuring)begin
   if(dut.visual_pcm_valid && dut.display_left!=0)heard=heard+1;
   for(j=0;j<32;j=j+1)begin
    if(measured_timbre==0)begin
     if(dut.u_synth_top.u_synth.u_core.u_bank.voice_samples[j*24+:24]!=0)seen[j]=1;
    end else if(dut.u_synth_top.u_synth.u_core.G_AUX.bank.samples[j*24+:24]!=0)seen[j]=1;
   end
  end
 end
 always @(rx.frame_event)begin
  if(rx.frames>2)begin
   if(rx.left_word!=={expected[rx.frames-1],8'd0} || rx.right_word!=={expected[rx.frames-1],8'd0})
    $fatal(1,"PCM5102 frame mismatch frame=%0d got=%h/%h expected=%h writes=%0d",rx.frames,rx.left_word,rx.right_word,expected[rx.frames-1],frames_written);
   pcm_frames=pcm_frames+1;
  end
 end
 // Independent PT8211 16-bit word decoder: high WS=left, low WS=right.
 always @(posedge bc)if(dut.synth_rst_n)begin
  if(!pt_started || lr!=pt_channel)begin
   pt_started=1;pt_channel=lr;pt_bits=0;if(lr)pt_index=pt_index+1;
  end
  pt_shift={pt_shift[14:0],da};pt_bits=pt_bits+1;
  // PT8211 starts with a reset-zero left/right frame before its first capture.
  if(pt_bits==16 && pt_index>1)begin
   if(pt_shift!==expected[pt_index-1][23:8])$fatal(1,"PT8211 word mismatch frame=%0d WS=%b got=%h expected=%h",pt_index,lr,pt_shift,expected[pt_index-1][23:8]);
   pt_words=pt_words+1;
  end
 end
 task automatic clocks(input integer n);repeat(n)@(negedge clk);endtask
 task automatic frames(input integer n);integer f;begin for(f=0;f<n;f=f+1)begin @(posedge clk);while(!dut.remote_tick)@(posedge clk);end @(negedge clk);end endtask
 task automatic packet(input [7:0] command,bytes,input [47:0] data);
 begin
  @(negedge clk);while(!dut.u_remote.core.pkt_ready)@(negedge clk);seq=seq+1'b1;cmd=command;len=bytes;payload=data;pkt=1;
  @(negedge clk);pkt=0;while(!dut.u_remote.core.rsp_valid)@(negedge clk);
  if(dut.u_remote.core.rsp_payload[15:8]!==0)$fatal(1,"phone command rejected cmd=%h response=%h",command,dut.u_remote.core.rsp_payload);
  reply=dut.u_remote.core.rsp_payload[47:16];@(negedge clk);
 end endtask
 task automatic settled(input integer source,input integer tone);
 integer n;begin
  clocks(5);n=0;while((dut.switching || dut.source_mode!=source || dut.actual_instrument!=tone) && n<180000)begin clocks(1);n=n+1;end
  if(n==180000)$fatal(1,"settling timeout mode=%0d tone=%0d state=%0d ready=%b",dut.source_mode,dut.actual_instrument,dut.u_remote.switch_state,dut.engine_clear_done);
 end endtask
 task automatic send_byte(input [7:0] value);integer b;begin
  tl_rx=0;clocks(107);for(b=0;b<8;b=b+1)begin tl_rx=value[b];clocks(107);end tl_rx=1;clocks(107);
 end endtask
 task automatic theremin_packet(input integer number,input [7:0] flags);
 reg [7:0] bytes[0:15];reg [15:0] crc;integer a,b;
 begin
  bytes[0]=8'ha5;bytes[1]=8'h5a;bytes[2]=1;bytes[3]=8'(number);bytes[4]=flags;
  bytes[5]=8'hc0;bytes[6]=8'hb6;bytes[7]=6;bytes[8]=0;
  bytes[9]=0;bytes[10]=128;bytes[11]=0;bytes[12]=8'(number);bytes[13]=0;
  crc=16'hffff;for(a=2;a<14;a=a+1)begin crc=crc^{bytes[a],8'b0};for(b=0;b<8;b=b+1)crc=crc[15]?(crc<<1)^16'h1021:crc<<1;end
  bytes[14]=crc[7:0];bytes[15]=crc[15:8];for(a=0;a<16;a=a+1)send_byte(bytes[a]);
 end endtask
 integer stream_ons=0,stream_offs=0,max_active=0;
 always @(posedge clk)if(dut.synth_rst_n)begin
  if(dut.remote_valid && dut.event_ready)begin if(dut.remote_on)stream_ons=stream_ons+1;else stream_offs=stream_offs+1;end
  if($countones(dut.active_debug)>max_active)max_active=$countones(dut.active_debug);
  if(dut.visual_pcm_valid && (^dut.display_left===1'bx))$fatal(1,"unknown PCM");
 end
 initial begin
  force dut.key_state32=touch;force dut.display_banks_seen=2'b11;
  force dut.u_remote.core.pkt_valid=pkt;force dut.u_remote.core.seq=seq;force dut.u_remote.core.cmd=cmd;
  force dut.u_remote.core.len=len;force dut.u_remote.core.payload=payload;force dut.u_remote.core.rsp_ready=1'b1;
  #2000;rst_n=1;wait(dut.synth_rst_n);frames(32);
  packet(8'h19,1,48'd35);packet(8'h1a,1,48'd80);
  for(tone=0;tone<5;tone=tone+1)begin
  packet(8'h11,1,48'(tone));settled(0,tone);frames(8);
  packet(8'h40,0,0);
  packet(8'h41,6,{32'd0,8'd100,8'd60});packet(8'h41,6,{32'd0,8'd90,8'd64});packet(8'h41,6,{32'd0,8'd80,8'd67});
  packet(8'h41,6,{32'd20,8'd0,8'd64});packet(8'h41,6,{32'd40,8'd0,8'd60});packet(8'h41,6,{32'd60,8'd0,8'd67});packet(8'h43,0,0);
  measured_timbre=3'(tone);measuring=1;packet(8'h15,1,1);wait(dut.score_playing);wait(!dut.score_playing && !dut.switching);frames(32);measuring=0;
  $display("audio timbre %0d done",tone);$fflush();end
  if(stream_ons!=15 || stream_offs!=15 || max_active<3 || heard<20)$fatal(1,"real synth stream lost chord: on%0d off%0d max%0d pcm%0d",stream_ons,stream_offs,max_active,heard);
  if(rx.bit_errors || rx.bad_edge || pcm_frames<2500 || pt_words<5000)$fatal(1,"DAC error/coverage");
  $fclose(audio_file);$display("PASS expression audio five timbres: stream chord 3 On/3 independent Off, max_active=%0d nonzero_PCM=%0d PCM5102_frames=%0d PT8211_words=%0d; real banks/FX/master/DAC, display disabled and ROM/PLL simulation models",max_active,heard,pcm_frames,pt_words);$finish;
 end
 initial begin #1000000000;$fatal(1,"stream system timeout");end
endmodule
