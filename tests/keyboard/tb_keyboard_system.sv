`timescale 1ns/1ps
`define BANK dut.u_synth_top.u_synth.u_core.u_bank
`define CORE dut.u_synth_top.u_synth.u_core
module tb_keyboard_system;
reg clk50=0,rst_n=0;always #10 clk50=~clk50;
reg[15:0]touch=0;wire scl,sdo;
ttp229_bfm #(.KEY16(1),.MULTI(1)) keyboard(touch,scl,sdo);
wire bc,lr,da,pbc,plr,pda,pa;wire[2:0]vp,vn;wire cp,cn;
tang_mega_138k_pro_top #(.KEYBOARD_PROFILE(1),.KEY_MAPPING_CONFIRMED(0)) dut(
.clk_50m(clk50),.rst_n(rst_n),.ttp229_scl(scl),.ttp229_sdo(sdo),
.i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),
.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda),
.audio_pa_en(pa),.video_d_p(vp),.video_d_n(vn),.video_ck_p(cp),.video_ck_n(cn));
wire clk=dut.clk_12m288;
wire[31:0]active=`BANK.voice_active,releasing=`BANK.voice_releasing;
wire[223:0]notes=`BANK.notes;
wire signed[23:0]audio= dut.u_synth_top.audio_out;
pcm5102_frame_check pcm_check(clk,dut.synth_rst_n,dut.u_synth_top.sample_tick,audio,audio,pbc,plr,pda);
reg[15:0]expected_word,ptshift;integer bits_left=99,pt_words=0,pt_errors=0,frames=0;
always @(posedge lr)if(dut.synth_rst_n)begin expected_word=audio[23:8];bits_left=frames>0?0:99;end
always @(posedge bc)if(bits_left<16)begin
 ptshift={ptshift[14:0],da};bits_left=bits_left+1;
 if(bits_left==16)begin pt_words=pt_words+1;if(ptshift!==expected_word)pt_errors=pt_errors+1;end
end
integer cycles=0,last_tick=-1,nonzero=0,max_active=0,allocated=0,accepted_on=0,accepted_off=0,fd;
reg[31:0]used=0;reg[15:0]accepted_keys=0;integer g,count,n;
always @(posedge clk)if(dut.synth_rst_n)begin
 cycles=cycles+1;
 if(dut.u_synth_top.sample_tick)begin
  if(last_tick>=0 && cycles-last_tick!=256)$fatal(1,"sample cadence changed");
  last_tick=cycles;frames=frames+1;
  if((^audio)===1'bx)$fatal(1,"unknown audio");
  if(audio!=0)nonzero=nonzero+1;
 end
 if(dut.event_valid && dut.event_ready)begin
  if(dut.event_note!==60+dut.event_key_index)$fatal(1,"MIDI map mismatch");
  if(dut.event_note_on)begin
   if(accepted_keys[dut.event_key_index])$fatal(1,"duplicate accepted On");
   accepted_keys[dut.event_key_index]=1;accepted_on=accepted_on+1;
  end else begin
   if(!accepted_keys[dut.event_key_index])$fatal(1,"unmatched accepted Off");
   accepted_keys[dut.event_key_index]=0;accepted_off=accepted_off+1;
  end
  $fdisplay(fd,"%0t,FIFO,%0d,%0d,%0d",$time,dut.event_note_on,dut.event_note,dut.fifo_level);
 end
 if((`CORE.note_on || `CORE.note_off) && !`CORE.event_ready)$fatal(1,"core consumed while loader busy");
 if(`BANK.allocation_valid)begin
  used[`BANK.allocation_index]=1;allocated=allocated+1;
  $fdisplay(fd,"%0t,ALLOC,%0d",$time,`BANK.allocation_index);
 end
 count=0;for(g=0;g<32;g=g+1)count=count+active[g];
 if(count>max_active)max_active=count;
end
genvar v;
generate for(v=0;v<32;v=v+1)begin:CHECK_VOICE
 always @(posedge clk)if(dut.synth_rst_n && `BANK.G_PARTIAL.G_VOICE[v].u_voice.dbg_overrun)
 $fatal(1,"voice overrun %0d",v);
end endgenerate
function[15:0]held_mask();
integer j,nn;reg[15:0]m;
begin m=0;
 for(j=0;j<32;j=j+1)if(active[j]&&!releasing[j])begin
  nn=notes[j*7+:7]-60;
  if(nn<0 || nn>15)$fatal(1,"wrong voice MIDI");
  if(m[nn])$fatal(1,"two held voices for one physical key");
  m[nn]=1;
 end
 held_mask=m;
end endfunction
integer scenarios=0;
task play(input[15:0]wanted);
integer wait_cycles;
begin
 @(negedge clk);touch=wanted;wait_cycles=0;
 while((dut.key_state!==wanted || accepted_keys!==wanted || dut.event_valid ||
        dut.fifo_level!=0 || `BANK.ld_busy || held_mask()!==wanted) && wait_cycles<220000)begin
  @(negedge clk);wait_cycles=wait_cycles+1;
 end
 repeat(300)@(negedge clk);scenarios=scenarios+1;
 if(dut.key_state!==wanted || accepted_keys!==wanted || held_mask()!==wanted)
 $fatal(1,"key->FIFO->loader->voice mismatch want=%h state=%h held=%h",wanted,dut.key_state,held_mask());
 $display("scenario %0d keys=%h -> accepted MIDI/held voices correct; max_active=%0d",scenarios,wanted,max_active);
end endtask
wire rxde;wire[7:0]rr,rg,rb;integer pixels,blankpixels,tmdserrors;
tmds_stream_checker checker_rx(dut.pixel_clk,dut.G_DISPLAY.u_visual.display_rst_n,
 dut.G_DISPLAY.u_visual.de_d,dut.G_DISPLAY.u_visual.hs_d,dut.G_DISPLAY.u_visual.vs_d,
 dut.G_DISPLAY.u_visual.hr,dut.G_DISPLAY.u_visual.hg,dut.G_DISPLAY.u_visual.hb,
 dut.video_red,dut.video_green,dut.video_blue,rxde,rr,rg,rb,pixels,blankpixels,tmdserrors);
// Compare each displayed bundle with the real audio-domain values at publication,
// not with a later instantaneous counter while voices are naturally decaying.
reg previous_request=0;
reg[57:0] expected_snapshot=0,source_at_edge;
integer status_frames=0;
always @(posedge clk)begin
 source_at_edge=dut.status_audio;
 #0.001;
 if(!dut.G_DISPLAY.u_visual.analysis_rst_n)previous_request=0;
 else if(dut.G_DISPLAY.u_visual.G_STATUS.mailbox.request!==previous_request)begin
  expected_snapshot=source_at_edge;
  previous_request=dut.G_DISPLAY.u_visual.G_STATUS.mailbox.request;
 end
end
reg take_snapshot;reg[57:0]expected_display;
always @(posedge dut.pixel_clk)begin
 take_snapshot=dut.G_DISPLAY.u_visual.blank_start &&
  (dut.G_DISPLAY.u_visual.G_STATUS.mailbox.request_sync!=dut.G_DISPLAY.u_visual.G_STATUS.mailbox.ack);
 expected_display=expected_snapshot;
 #0.001;
 if(dut.G_DISPLAY.u_visual.display_rst_n && take_snapshot)begin
  if(dut.G_DISPLAY.u_visual.status_pixel!==expected_display)$fatal(1,"display snapshot differs from actual audio publication");
  status_frames=status_frames+1;
 end
end
integer fftframes=0;
always @(posedge clk)if(dut.G_DISPLAY.u_visual.bin_valid && &dut.G_DISPLAY.u_visual.unused_bin_index)fftframes=fftframes+1;
initial begin
 fd=$fopen("tests/results/keyboard/keyboard_system_events.csv","w");
 $fdisplay(fd,"time,stage,on_or_voice,midi,fifo_level");
 $dumpfile("tests/results/keyboard/keyboard_system.vcd");
 $dumpvars(0,rst_n,touch,dut.key_raw_frame,dut.key_reader_state,dut.key_state,
 dut.key_frame_valid,dut.event_valid,dut.event_ready,dut.event_note_on,dut.event_note,
 dut.fifo_level,active,releasing,audio,dut.active_voice_count);
 #1;rst_n=1;#1;rst_n=0;#1000;rst_n=1;wait(dut.synth_rst_n);
 // Start with all16, before any asymmetric frame can prove legacy mirror detection.
 play(16'hffff);play(0);play(16'hffff);
 play(16'hfffb);play(0);
 play(16'h0003);play(0);play(16'h0015);play(16'h0011);play(0);
 play(16'h001f);play(0);play(16'h00ff);play(0);
 play(16'h8000);play(0);play(16'h8000);play(0);
 play(16'hffff);
 #100000000;
 if(held_mask()!==16'hffff || dut.G_DISPLAY.u_visual.status_pixel[57:42]!==16'hffff)
 $fatal(1,"real display key state mismatch");
 if(dut.G_DISPLAY.u_visual.status_pixel[11:5]!==60 || !dut.G_DISPLAY.u_visual.status_pixel[4])
 $fatal(1,"display MIDI mismatch");
 if(status_frames<5 || dut.G_DISPLAY.u_visual.status_pixel[41:36]<16 ||
 dut.G_DISPLAY.u_visual.status_pixel[41:36]>32)
 $fatal(1,"display Voice snapshot coverage");
 if(!dut.G_DISPLAY.u_visual.render.peak_valid || fftframes<2 || tmdserrors || nonzero<1000)
 $fatal(1,"missing real audio FFT/video");
 if(max_active!=32 || used!==32'hffffffff)$fatal(1,"32 Voice coverage missing max=%0d used=%h",max_active,used);
 if(pcm_check.frames_ok<1000 || pcm_check.errors || pcm_check.pad_errors || pcm_check.len_errors ||
 pcm_check.delay_errors || pt_words<1000 || pt_errors)$fatal(1,"dual DAC regression");
 $display("PASS keyboard system: %0d scenarios, %0d On/%0d Off accepted, %0d allocations, all32 voices used, max_active=%0d; %0d PCM5102 frames and %0d PT8211 words exact; %0d real FFT frames, %0d TMDS pixels, %0d audio-publication-aligned status snapshots",
 scenarios,accepted_on,accepted_off,allocated,max_active,pcm_check.frames_ok,pt_words,fftframes,pixels,status_frames);
 $fclose(fd);$finish;
end
initial begin #450000000;$fatal(1,"system timeout");end
endmodule
