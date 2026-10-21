`timescale 1ns/1ps
`define BANK dut.u_synth_top.u_synth.u_core.u_bank
`define CORE dut.u_synth_top.u_synth.u_core
module tb_system32;
 reg clk50=0,rst=0;always #10 clk50=~clk50;
 reg[15:0]touch0=0,touch1=0;wire scl0,scl1,sdo0,sdo1,m0,m1;
 reg fault1=0;assign sdo0=m0;assign sdo1=fault1?1'b0:m1;
 ttp229_bfm #(.KEY16(1),.MULTI(1)) b0(touch0,scl0,m0),b1(touch1,scl1,m1);
 wire bc,lr,da,pbc,plr,pda,pa;wire[2:0]vp,vn;wire cp,cn;
 tang_mega_138k_pro_top dut(.clk_50m(clk50),.rst_n(rst),
 .ttp229_scl(scl0),.ttp229_sdo(sdo0),.ttp229_2_scl(scl1),.ttp229_2_sdo(sdo1),
 .i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),
 .pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda),.audio_pa_en(pa),
 .video_d_p(vp),.video_d_n(vn),.video_ck_p(cp),.video_ck_n(cn));
 wire clk=dut.clk_12m288;wire[31:0]active=`BANK.voice_active,releasing=`BANK.voice_releasing;
 wire[223:0]notes=`BANK.notes;wire signed[23:0]audio=dut.u_synth_top.audio_out;
 pcm5102_frame_check pcm_check(clk,dut.synth_rst_n,dut.u_synth_top.sample_tick,audio,audio,pbc,plr,pda);
 reg[15:0]expected_word,ptshift;integer bits_left=99,pt_words=0,pt_errors=0,frames=0;
 always @(posedge lr)if(dut.synth_rst_n)begin expected_word=audio[23:8];bits_left=frames>0?0:99;end
 always @(posedge bc)if(bits_left<16)begin
  ptshift={ptshift[14:0],da};bits_left++;
  if(bits_left==16)begin pt_words++;if(ptshift!==expected_word)pt_errors++;end
 end
 reg[31:0]accepted_keys=0,used=0,nonzero_voices=0;integer ons=0,offs=0,allocs=0;
 integer cycles=0,last_tick=-1,nonzero=0,peak_count=0,max_active=0,clip_frames=0,scenarios=0,fd,g,n,count;
 function automatic[31:0] held_mask();
  integer j,nn;reg[31:0]m;
  begin m=0;
   for(j=0;j<32;j++)if(active[j]&&!releasing[j])begin
    nn=notes[j*7+:7]-60;
    if(nn<0 || nn>31)$fatal(1,"voice MIDI out of range");
    if(m[nn])$fatal(1,"two held voices alias one key");m[nn]=1;
   end
   held_mask=m;
  end
 endfunction
 always @(posedge clk)if(dut.synth_rst_n)begin
  cycles++;
  if(dut.event_valid&&dut.event_ready)begin
   if(dut.event_note!==60+dut.event_key_index)$fatal(1,"global key index truncated");
   if(accepted_keys[dut.event_key_index]===dut.event_note_on)$fatal(1,"duplicate on/unmatched off");
   accepted_keys[dut.event_key_index]=dut.event_note_on;
   if(dut.event_note_on)ons++;else offs++;
   $fdisplay(fd,"%0t,EVENT,%0d,%0d,%0d",$time,dut.event_note_on,dut.event_note,dut.event_key_index);
   $fflush(fd);
  end
  if((`CORE.note_on || `CORE.note_off)&&!`CORE.event_ready)$fatal(1,"loader busy handshake violation");
  if(`BANK.allocation_valid)begin used[`BANK.allocation_index]=1;allocs++;end
  count=0;for(g=0;g<32;g++)count+=active[g];if(count>max_active)max_active=count;
  if(dut.u_synth_top.sample_tick)begin
   if(last_tick>=0 && cycles-last_tick!=256)$fatal(1,"audio sample cadence");last_tick=cycles;frames++;
   if((^audio)===1'bx)$fatal(1,"unknown PCM");if(audio!=0)nonzero++;
   if(dut.dbg_clip)clip_frames++;
   for(g=0;g<32;g++)if(active[g] && `BANK.voice_samples[g*24+:24]!=0)nonzero_voices[g]=1;
  end
  if(dut.key_mapping_error)$fatal(1,"default note/raw mapping invalid");
  // Keep the existing screen's sixteen positions tied to bank0 only.
  if(dut.status_audio[57:42]!==dut.key_state32[15:0])$fatal(1,"screen combined/aliased two banks");
 end
 genvar v;generate for(v=0;v<32;v++)begin:CHECK_VOICE
 always @(posedge clk)if(dut.synth_rst_n && `BANK.G_PARTIAL.G_VOICE[v].u_voice.dbg_overrun)
  $fatal(1,"voice overrun%0d",v);
 end endgenerate
 task play(input[31:0]want);integer t;begin
  @(negedge clk);touch0=want[15:0];touch1=want[31:16];t=0;
  while((dut.key_state32!==want || accepted_keys!==want || dut.event_valid || dut.fifo_level ||
        `BANK.ld_busy || held_mask()!==want) && t<260000)begin @(negedge clk);t++;end
  repeat(300)@(negedge clk);scenarios++;
  if(dut.key_state32!==want || accepted_keys!==want || held_mask()!==want)
   $fatal(1,"physical32 convergence want%h state%h accepted%h voices%h",want,dut.key_state32,accepted_keys,held_mask());
  $display("scenario%0d keys%h held%h latency_clocks%0d",scenarios,want,held_mask(),t);
  $fflush();
 end endtask
 wire rxde;wire[7:0]rr,rg,rb;integer pixels,blankpixels,tmdserrors;
 tmds_stream_checker video(dut.pixel_clk,dut.G_DISPLAY.u_visual.display_rst_n,
 dut.G_DISPLAY.u_visual.de_d,dut.G_DISPLAY.u_visual.hs_d,dut.G_DISPLAY.u_visual.vs_d,
 dut.G_DISPLAY.u_visual.hr,dut.G_DISPLAY.u_visual.hg,dut.G_DISPLAY.u_visual.hb,
 dut.video_red,dut.video_green,dut.video_blue,rxde,rr,rg,rb,pixels,blankpixels,tmdserrors);
 integer fftframes=0;
 always @(posedge clk)if(dut.G_DISPLAY.u_visual.bin_valid && &dut.G_DISPLAY.u_visual.unused_bin_index)fftframes++;
 initial begin
  fd=$fopen("tests/keyboard32_20261019/system_events.csv","w");
  $fdisplay(fd,"time,stage,on,midi,key_index");
  #1;rst=1;#1;rst=0;#1000;rst=1;wait(dut.synth_rst_n);
  // Actual production reader timing, default parameters and all32 cold start.
  play(32'hffffffff);repeat(1024*256)@(negedge clk);
  if(held_mask()!==32'hffffffff || active!==32'hffffffff || used!==32'hffffffff ||
     max_active!=32 || nonzero_voices!==32'hffffffff || ons!=32)
   $fatal(1,"all32 live independent voices missing active%h used%h nonzero%h ons%0d",active,used,nonzero_voices,ons);
  // Release across the module boundary without disturbing the other29 notes.
  play(32'h7ffe7fff);play(32'h00010001);play(0);
  play(32'h80018001);play(32'h00008000);play(0);
  // Idle faulty bank1 cannot block normal first-module press/release.
  fault1=1;repeat(90000)@(negedge clk);play(32'h00000009);play(0);
  if(!dut.key_bank_rejected[63:32])$fatal(1,"bank1 fault not rejected");
  fault1=0;play(32'h80000000);play(0);
  // Let the real FFT and the30Hz screen finish publication after these changes.
  play(32'h80018001);#80000000;
  if(nonzero<1500 || fftframes<2 || tmdserrors || !dut.G_DISPLAY.u_visual.render.peak_valid)
   $fatal(1,"PCM/FFT/TMDS coverage incomplete");
  if(pcm_check.frames_ok<1500 || pcm_check.errors || pcm_check.pad_errors || pcm_check.len_errors ||
     pcm_check.delay_errors || pt_words<1500 || pt_errors)$fatal(1,"dual DAC mismatch");
  if(dut.G_DISPLAY.u_visual.status_pixel[57:42]!==16'h8001)$fatal(1,"16-key display correspondence");
  $display("PASS physical32 system: %0d scenarios, %0d On/%0d Off, %0d allocations, max_active%0d, nonzero_voice_mask%h; PCM5102 %0d frames/PT8211 %0d words exact; FFT%0d, TMDS%0d pixels, limiter-flag frames%0d",
   scenarios,ons,offs,allocs,max_active,nonzero_voices,pcm_check.frames_ok,pt_words,fftframes,pixels,clip_frames);
  $fclose(fd);$finish;
 end
 initial begin #350000000;$fatal(1,"system timeout");end
 // Progress observation only; no stimulus, clocks or assertions are changed.
 initial forever begin #5000000;
  $display("progress time_ns%0t scenarios%0d events%0d/%0d active%h FFT%0d",$time,scenarios,ons,offs,active,fftframes);$fflush();
 end
endmodule
