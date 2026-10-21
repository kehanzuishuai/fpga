// Targeted FAIL reproduction: original stimulus/checks, first TWO reset epochs only.
// This is not a passing or full mapping regression. Original 16-key source preserved in backup.
`timescale 1ns/1ps
`define CORE dut.u_synth_top.u_synth.u_core
`define BANK `CORE.u_bank
module tb_pcm_reset_repro;
reg clk50=0,rst_n=0;always #10 clk50=~clk50;
reg [15:0] touch=0;wire scl,sdo;
ttp229_bfm #(.KEY16(1),.MULTI(1)) keyboard(touch,scl,sdo);
wire bc,lr,da,pbc,plr,pda,pa;wire[2:0]vp,vn;wire cp,cn;
tang_mega_138k_pro_top dut(.clk_50m(clk50),.rst_n(rst_n),.ttp229_scl(scl),.ttp229_sdo(sdo),.i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda),.audio_pa_en(pa),.video_d_p(vp),.video_d_n(vn),.video_ck_p(cp),.video_ck_n(cn));
wire clk=dut.clk_12m288;wire signed[23:0] audio=dut.u_synth_top.audio_out;
pcm5102_frame_check pcm_check(clk,dut.synth_rst_n,dut.u_synth_top.sample_tick,audio,audio,pbc,plr,pda);
integer current_key=0,on_count=0,off_count=0,fd,fp,ticks=0,checked=0,product_slot;
reg accepted_on=0,accepted_off=0;
always @(posedge clk)if(dut.synth_rst_n)begin
 if(dut.event_valid&&dut.event_ready)begin
  if(dut.event_note!==60+current_key)$fatal(1,"MAP FAIL raw bit %0d: actual MIDI %0d expected %0d",current_key,dut.event_note,60+current_key);
  if(dut.event_note_on)begin on_count=on_count+1;accepted_on=1;end else begin off_count=off_count+1;accepted_off=1;end
 end
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
end
initial begin
 fd=$fopen("tests/continuation_20261017/repro_stage_samples.csv","w");fp=$fopen("tests/continuation_20261017/repro_partial_products.csv","w");
 for(current_key=0;current_key<2;current_key=current_key+1)begin
  rst_n=0;touch=0;accepted_on=0;accepted_off=0;#1000;rst_n=1;wait(dut.synth_rst_n);repeat(3000)@(negedge clk);
  touch=16'b1<<current_key;wait(accepted_on);wait(!`BANK.ld_busy);repeat(300)@(negedge clk);
  repeat(2048)@(posedge dut.u_synth_top.sample_tick);
  touch=0;wait(accepted_off);repeat(3000)@(negedge clk);checked=checked+1;
  $display("PASS raw bit %0d -> MIDI %0d accepted On/Off, loader and Voice correct",current_key,60+current_key);
 end
 if(on_count!=2 || off_count!=2 || checked!=2)$fatal(1,"event counts");
 $display("ORIGINAL checker counters data=%0d pad=%0d length=%0d delay=%0d frames=%0d nonzero=%0d",pcm_check.errors,pcm_check.pad_errors,pcm_check.len_errors,pcm_check.delay_errors,pcm_check.frames_ok,pcm_check.nonzero);
 if(pcm_check.errors || pcm_check.pad_errors || pcm_check.len_errors || pcm_check.delay_errors)$fatal(1,"PCM output");
 $fclose(fd);$fclose(fp);$display("PASS default map/chain 16 bits, 32Voice build, DISPLAY_ENABLE=1");$finish;end
initial begin #2000000000;$fatal(1,"timeout");end
endmodule
