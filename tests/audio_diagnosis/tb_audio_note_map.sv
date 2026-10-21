`timescale 1ns/1ps
`define CORE dut.u_synth_top.u_synth.u_core
`define BANK `CORE.u_bank
module tb_audio_note_map;
reg clk50=0,rst_n=0;always #10 clk50=~clk50;
reg [15:0] touch=0;wire scl,sdo;
ttp229_bfm #(.KEY16(1),.MULTI(1)) keyboard(touch,scl,sdo);
wire bc,lr,da,pbc,plr,pda,pa;wire[2:0]vp,vn;wire cp,cn;
tang_mega_138k_pro_top dut(.clk_50m(clk50),.rst_n(rst_n),.ttp229_scl(scl),.ttp229_sdo(sdo),.i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda),.audio_pa_en(pa),.video_d_p(vp),.video_d_n(vn),.video_ck_p(cp),.video_ck_n(cn));
wire clk=dut.clk_12m288;wire signed[23:0] audio=dut.u_synth_top.audio_out;
pcm5102_frame_check pcm_check(clk,dut.synth_rst_n,dut.u_synth_top.sample_tick,audio,audio,pbc,plr,pda);
integer current_key=0,on_count=0,off_count=0,fd,fp,ticks=0,checked=0,product_slot;
integer ft,fs,fc,scan_frames,map_frames,fifo_on,fifo_off,allocs,loads,plays,active_cycles;
integer pt_words=0,pt_errors=0,pt_bits=99,pr_bits=99,pt_left=0,pt_right=0;
reg[15:0]pt_shift,pr_shift,pt_expected;
integer start_pcm,start_nonzero,start_pt;
integer measured_samples=0;
reg measuring=0;
always @(posedge lr)if(dut.synth_rst_n)begin pt_expected=audio[23:8];pt_bits=0;end
always @(negedge lr)if(dut.synth_rst_n && pt_bits==16)pr_bits=0;
always @(posedge bc)if(dut.synth_rst_n)begin
 if(lr && pt_bits<16)begin
  pt_shift={pt_shift[14:0],da};pt_bits=pt_bits+1;
  if(pt_bits==16)begin pt_left=pt_left+1;pt_words=pt_words+1;if(pt_shift!==pt_expected)pt_errors=pt_errors+1;end
 end
 if(!lr && pr_bits<16)begin
  pr_shift={pr_shift[14:0],da};pr_bits=pr_bits+1;
  if(pr_bits==16)begin pt_right=pt_right+1;pt_words=pt_words+1;if(pr_shift!==pt_expected)pt_errors=pt_errors+1;end
 end
end
reg accepted_on=0,accepted_off=0;
always @(posedge clk)if(dut.synth_rst_n)begin
 if(dut.key_reader_frame_valid)begin
  scan_frames=scan_frames+1;
  $fdisplay(ft,"%0d,%0t,SCAN,%h,%h",current_key,$time,dut.key_raw_frame,dut.key_reader_state);
 end
 if(dut.key_frame_valid)begin map_frames=map_frames+1;$fdisplay(ft,"%0d,%0t,MAP,%h,%h",current_key,$time,dut.key_accepted_raw,dut.key_state);end
 if(dut.event_valid&&dut.event_ready)begin
  if(dut.event_note!==60+current_key)$fatal(1,"MAP FAIL raw bit %0d: actual MIDI %0d expected %0d",current_key,dut.event_note,60+current_key);
  if(dut.event_note_on)begin on_count=on_count+1;accepted_on=1;end else begin off_count=off_count+1;accepted_off=1;end
  $fdisplay(ft,"%0d,%0t,WRITE,%0d,%0d",current_key,$time,dut.event_note_on,dut.event_note);
 end
 if(dut.u_synth_top.u_synth.out_valid && dut.u_synth_top.u_synth.core_ready)begin
  if(dut.u_synth_top.u_synth.out_note_on)fifo_on=fifo_on+1;else fifo_off=fifo_off+1;
  if(dut.u_synth_top.u_synth.out_note!==60+current_key)$fatal(1,"FIFO read MIDI");
 end
 if(`BANK.allocation_valid)begin allocs=allocs+1;$fdisplay(ft,"%0d,%0t,ALLOC,%0d,%0d",current_key,$time,`BANK.allocation_index,`BANK.midi_note);end
 if(|`BANK.G_PARTIAL.ld_done)begin loads=loads+1;if(|(`BANK.G_PARTIAL.ld_done & `BANK.G_PARTIAL.voice_ld_ready))plays=plays+1;end
 if(`BANK.voice_active[0])active_cycles=active_cycles+1;
 if(`BANK.allocation_valid && `BANK.midi_note!==60+current_key)$fatal(1,"bank MIDI");
 if(dut.u_synth_top.sample_tick)begin
  ticks=ticks+1;$fdisplay(fd,"%0d,INPUT,%0d,%0d,%0d",current_key,ticks,$signed(`CORE.sum),$signed(`CORE.normalized_sum));
  if(`BANK.voice_active[0] && `BANK.notes[0+:7]!==60+current_key)$fatal(1,"voice MIDI");
 end
 if(`BANK.G_PARTIAL.G_VOICE[0].u_voice.add_pending)begin
  product_slot=(`BANK.G_PARTIAL.G_VOICE[0].u_voice.eng==3)?15:((`BANK.G_PARTIAL.G_VOICE[0].u_voice.slot+15)%16);
  $fdisplay(fp,"%0d,%0d,%0d,%0d",current_key,ticks,product_slot,$signed(`BANK.G_PARTIAL.G_VOICE[0].u_voice.mul_p));
 end
 if(`CORE.G_FX.fx_valid)$fdisplay(fd,"%0d,FX,%0d,%0d,%0d",current_key,ticks,$signed(audio),$signed(audio)>>>8);
 if(measuring && dut.u_synth_top.visual_pcm_valid)begin
  measured_samples=measured_samples+1;
  if((^audio)===1'bx || (^`CORE.normalized_sum)===1'bx)$fatal(1,"unknown PCM");
  $fdisplay(fs,"%0d,%0d,%0d,%0d",current_key,ticks,$signed(`CORE.normalized_sum),$signed(audio));
 end
end
initial begin
 fd=$fopen("tests/continuation_20261017/mapping_final/chain_stage_samples.csv","w");fp=$fopen("tests/continuation_20261017/mapping_final/partial_products.csv","w");
 ft=$fopen("tests/continuation_20261017/mapping_final/key_trace.csv","w");fs=$fopen("tests/continuation_20261017/mapping_final/key_pcm.csv","w");fc=$fopen("tests/continuation_20261017/mapping_final/key_chain.csv","w");
 $fdisplay(fc,"raw_bit,midi,scan_frames,mapper_frames,fifo_on,fifo_off,allocations,loader_done,play_edges,active_cycles,pcm_frames,pcm_nonzero,pt_words,hdmi_voices,hdmi_peak,diag_alloc,diag_load,diag_play");
 for(current_key=0;current_key<16;current_key=current_key+1)begin
  // The receiver has no reset pin: discard its interrupted half frame explicitly.
  // Counters remain cumulative, so a previous real serial error still fails.
  pcm_check.restart;
  rst_n=0;touch=0;accepted_on=0;accepted_off=0;measuring=0;pt_bits=99;pr_bits=99;
  scan_frames=0;map_frames=0;fifo_on=0;fifo_off=0;allocs=0;loads=0;plays=0;active_cycles=0;measured_samples=0;
  start_pcm=pcm_check.frames_ok;start_nonzero=pcm_check.nonzero;start_pt=pt_words;
  #1000;rst_n=1;wait(dut.synth_rst_n);repeat(3000)@(negedge clk);
  touch=16'b1<<current_key;wait(accepted_on);wait(!`BANK.ld_busy);repeat(300)@(negedge clk);
  measuring=1;repeat(4096)@(posedge dut.u_synth_top.sample_tick);
  // sample_tick schedules synthesis; the DAC takes its sample seven clocks later.
  // Keep the observation window open through that last capture, before next tick.
  repeat(16)@(negedge clk);measuring=0;
  if(measured_samples!=4096)$fatal(1,"PCM export window expected 4096 actual %0d",measured_samples);
  if(dut.G_DISPLAY.u_visual.status_pixel[41:36]!=1 || dut.G_DISPLAY.u_visual.status_pixel[35:12]==0 ||
     dut.G_DISPLAY.u_visual.status_pixel[11:5]!==60+current_key || dut.G_DISPLAY.u_visual.status_pixel[57:42]!==(16'b1<<current_key))$fatal(1,"per-key HDMI status missing");
  if(pcm_check.frames_ok-start_pcm<4096 || pcm_check.nonzero-start_nonzero<1000 || pt_words-start_pt<8192)$fatal(1,"PCM coverage missing");
  $fwrite(fc,"%0d,%0d,%0d,%0d,",current_key,60+current_key,scan_frames,map_frames);
  touch=0;wait(accepted_off);repeat(3000)@(negedge clk);checked=checked+1;
  if(fifo_on!=1 || fifo_off!=1 || allocs!=1 || loads!=1 || plays!=1 || active_cycles<4096*256)$fatal(1,"chain counts");
  if(dut.diagnostic_chain[47:0]!==48'h000100010001 || dut.diagnostic_chain[127:96]!==32'h00010001 || dut.diagnostic_chain[95:48]==0)$fatal(1,"hardware diagnostic counters");
  $fdisplay(fc,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",fifo_on,fifo_off,allocs,loads,plays,active_cycles,pcm_check.frames_ok-start_pcm,pcm_check.nonzero-start_nonzero,pt_words-start_pt,dut.G_DISPLAY.u_visual.status_pixel[41:36],dut.G_DISPLAY.u_visual.status_pixel[35:12],dut.diagnostic_chain[15:0],dut.diagnostic_chain[31:16],dut.diagnostic_chain[47:32]);
  $display("PASS raw bit %0d -> MIDI %0d accepted On/Off, loader and Voice correct",current_key,60+current_key);
 end
 if(on_count!=16 || off_count!=16 || checked!=16)$fatal(1,"event counts");
 $display("PCM check data=%0d pad=%0d length=%0d delay=%0d frames=%0d PT errors=%0d L=%0d R=%0d",pcm_check.errors,pcm_check.pad_errors,pcm_check.len_errors,pcm_check.delay_errors,pcm_check.frames_ok,pt_errors,pt_left,pt_right);
 if(pcm_check.errors || pcm_check.pad_errors || pcm_check.len_errors || pcm_check.delay_errors || pt_errors)$fatal(1,"PCM output");
 $fclose(fd);$fclose(fp);$fclose(ft);$fclose(fs);$fclose(fc);$display("PASS default map/chain 16 bits, 32Voice build, DISPLAY_ENABLE=1");$finish;end
initial begin #2000000000;$fatal(1,"timeout");end
endmodule
