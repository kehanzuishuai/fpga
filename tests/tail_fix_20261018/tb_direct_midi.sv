`timescale 1ns/1ps
`define CORE dut.u_synth.u_core
`define BANK dut.u_synth.u_core.u_bank
`define V dut.u_synth.u_core.u_bank.G_PARTIAL.G_VOICE[0].u_voice
// Real 32-voice synth, keyboard bypassed. One fresh note per reset.
module tb_direct_midi;
reg clk=0,rst_n=0;always #40.69 clk=~clk;
reg ev=0,on=0;reg[6:0]note=60;wire ready;
wire bc,lr,da,pbc,plr,pda;wire[31:0]active;wire[5:0]voices;wire[23:0]peak;
wire signed[23:0]audio;wire[127:0]diag;
synth_top dut(.clk(clk),.rst_n(rst_n),.event_valid(ev),.event_note_on(on),
 .event_note(note),.event_velocity(8'd100),.event_waveform(2'd3),.event_ready(ready),
 .morph_enable(1'b0),.morph_control(10'd0),.test_enable(1'b0),.hammer_enable(1'b1),.fx_ctrl(5'b10011),
 .i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda),
 .active_debug(active),.active_voice_count(voices),.audio_peak(peak),.visual_pcm(audio),.diagnostic_chain(diag));
pcm5102_frame_check pcm(clk,rst_n,dut.sample_tick,audio,audio,pbc,plr,pda);
integer midi,cycles=0,tick=-1,accepted_on=0,accepted_off=0,loads=0,allocs=0;
integer fd,fl,fs,fp,first_cycle,first_value,first_tick,peak_seen,start_frame;
integer captured_slot;reg [25:0]captured_level;reg[17:0]captured_exp;
reg[23:0]captured_raw,captured_amp;reg signed[24:0]captured_off;
reg signed[17:0]captured_wave;reg signed[44:0]expected_product;
always @(posedge clk)if(rst_n)begin
 cycles=cycles+1;
 if(dut.sample_tick)tick=tick+1;
 if(ev && ready)begin if(on)accepted_on=accepted_on+1;else accepted_off=accepted_off+1;end
 if(`BANK.allocation_valid)begin
  allocs=allocs+1;if(`BANK.allocation_index!=0)$fatal(1,"fresh note allocated outside voice0");
 end
 if(|`BANK.G_PARTIAL.ld_done)begin loads=loads+1;$fdisplay(fl,"L %0d %0d 100",tick,note);end
 if(`V.dbg_sample_strobe)$fdisplay(fl,"S %0d %0d %0d %0d",tick,$signed(`V.sample),`V.dbg_rel,`V.dbg_fade);
 if(active[31:1]!=0 || voices>1)$fatal(1,"other voices interfere with single-note test");
 if(dut.visual_pcm_valid)begin
  if((^audio)===1'bx)$fatal(1,"unknown PCM");
  if(audio!=0 && first_cycle<0)begin first_cycle=cycles;first_tick=tick;first_value=audio;end
  if($signed(audio)<0)begin if(-$signed(audio)>peak_seen)peak_seen=-$signed(audio);end
  else if(audio>peak_seen)peak_seen=audio;
  $fdisplay(fs,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",note,tick,$signed(`V.sample),$signed(`CORE.sum),$signed(`CORE.normalized_sum),$signed(audio),voices,peak,`V.releasing);
 end
 // Capture actual operands before the multiply and the actual pipelined product.
 if((note==48 || note==64 || note==79 || note==84 || note==91) && `V.eng==2 && `V.step==6)begin
  captured_slot=`V.slot;captured_level=`V.lvl_r;captured_exp=`V.exp_q;
  captured_raw=`V.amp_raw;captured_off=`V.amp_off;captured_amp=`V.amp_r;captured_wave=`V.wave_w;
  expected_product=$signed({3'b000,`V.amp_r})*$signed(`V.wave_w);
 end
 if((note==48 || note==64 || note==79 || note==84 || note==91) && `V.add_pending)begin
  if(`V.mul_p!==expected_product)$fatal(1,"signed Partial product mismatch");
  $fdisplay(fp,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",note,tick,captured_slot,captured_level,captured_exp,captured_raw,captured_off,captured_amp,captured_wave,$signed(`V.mul_p));
 end
end
task send(input pressed);
 begin
 @(negedge clk);on=pressed;ev=1;
 @(posedge clk);while(!ready)@(posedge clk);
 @(negedge clk);ev=0;
 end
endtask
initial begin
 fd=$fopen("tests/tail_fix_20261018/DIRECT_MIDI.csv","w");
 fs=$fopen("tests/tail_fix_20261018/DIRECT_STAGES.csv","w");
 fp=$fopen("tests/tail_fix_20261018/PARTIAL_FIXED_TRACE.csv","w");
 $fdisplay(fd,"midi,write_on,write_off,allocations,loader_done,first_pcm_cycle,first_pcm_tick,first_pcm_value,peak_first_1024_samples,held_voice_count,read_on,read_off,pcm_frames");
 $fdisplay(fs,"midi,tick,voice,mixer,gain,post_fx,voice_count,peak_50ms,releasing");
 $fdisplay(fp,"midi,tick,slot,level_q22,exp_q18,amp_raw,amp_off,amp_gated,wave_q17,product_s45");
 $dumpfile("tests/tail_fix_20261018/direct_midi.vcd");
 $dumpvars(0,rst_n,note,ev,on,ready,active,voices,audio,dut.sample_tick,diag);
 for(midi=48;midi<=91;midi=midi+1)begin
  pcm.restart;rst_n=0;ev=0;cycles=0;tick=-1;accepted_on=0;accepted_off=0;loads=0;allocs=0;
  first_cycle=-1;first_tick=-1;first_value=0;peak_seen=0;start_frame=pcm.frames_ok;
  fl=$fopen($sformatf("tests/tail_fix_20261018/direct_voice_%0d.txt",midi),"w");
  note=midi;repeat(12)@(negedge clk);rst_n=1;
  // Existing FX RAM clear lasts 4096 clocks; match production reset settling.
  repeat(5000)@(negedge clk);send(1);wait(loads==1);
  repeat(512)@(posedge dut.sample_tick);repeat(16)@(negedge clk);
  if(voices!=1 || first_cycle<0 || peak_seen==0)$fatal(1,"direct MIDI did not produce active Voice and nonzero PCM");
  send(0);repeat(512)@(posedge dut.sample_tick);repeat(16)@(negedge clk);
  if(accepted_on!=1 || accepted_off!=1 || allocs!=1 || loads!=1 || diag[127:96]!==32'h00010001 || !`V.releasing)
    $fatal(1,"FIFO/allocate/load/release chain failed");
  $fdisplay(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,1,%0d,%0d,%0d",midi,accepted_on,accepted_off,allocs,loads,first_cycle,first_tick,first_value,peak_seen,diag[111:96],diag[127:112],pcm.frames_ok-start_frame);
  $fclose(fl);$display("PASS direct MIDI%0d: real FIFO/voice0/load/active/PCM/release; first=%0d at tick%0d",midi,first_value,first_tick);
 end
 if(pcm.errors || pcm.pad_errors || pcm.len_errors || pcm.delay_errors)$fatal(1,"PCM5102 digital mismatch");
 $fclose(fd);$fclose(fs);$fclose(fp);
 $display("PASS direct MIDI48..91 real 32Voice synth, 512 held+512 release ticks each; PCM frames=%0d errors=0",pcm.frames_ok);$finish;
end
initial begin #6000000000;$fatal(1,"direct injection timeout");end
endmodule
