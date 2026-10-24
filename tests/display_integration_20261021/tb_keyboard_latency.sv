`timescale 1ns/1ps
`define BANK dut.u_synth_top.u_synth.u_core.u_bank
module tb_keyboard_latency;
 reg clk50=0,rst=0;always #10 clk50=~clk50;
 reg [15:0] touch0=0,touch1=0;wire scl0,scl1,sdo0,sdo1;
 ttp229_bfm b0(touch0,scl0,sdo0),b1(touch1,scl1,sdo1);
 wire bc,lr,da,pbc,plr,pda;
 tang_mega_138k_pro_top #(.DISPLAY_ENABLE(0)) dut(
 .clk_50m(clk50),.rst_n(rst),.esp_uart_rx(1'b1),.esp_spi_sck(1'b0),.esp_spi_cs_n(1'b1),.esp_spi_mosi(1'b0),
 .ttp229_scl(scl0),.ttp229_sdo(sdo0),.ttp229_2_scl(scl1),.ttp229_2_sdo(sdo1),
 .i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda));
 wire clk=dut.clk_12m288;
 i2s_rx_model rx(pbc,plr,pda);
 reg measuring=0;reg [31:0] wanted=0,seen=0;integer scenario=0,j;
 time started,keys_at,event_at,pcm_at,pt_at,i2s_at,last_voice_at;
 reg [31:0] pt_shift=0;integer pt_bits=0;reg pt_started=0,pt_channel;
 // Decode complete PT8211 16-bit words from pins, independently of TX registers.
 always @(posedge bc)if(dut.synth_rst_n)begin
  if(!pt_started || pt_channel!=lr)begin pt_started=1;pt_channel=lr;pt_bits=0;end
  pt_shift={pt_shift[30:0],da};pt_bits=pt_bits+1;
  if(measuring && pt_bits==16 && pt_shift[15:0]!=0 && pt_at==0)pt_at=$time;
 end
 always @(rx.frame_event)if(measuring && (rx.left_word!=0 || rx.right_word!=0) && i2s_at==0)i2s_at=$time;
 always @(posedge clk)if(dut.synth_rst_n && measuring)begin
  if(keys_at==0 && dut.key_state32==wanted)keys_at=$time;
  if(event_at==0 && dut.event_valid && dut.event_ready && dut.event_note_on)event_at=$time;
  if(pcm_at==0 && dut.visual_pcm_valid && dut.visual_pcm!=0)pcm_at=$time;
  for(j=0;j<32;j=j+1)if(`BANK.voice_active[j] && `BANK.voice_samples[j*24+:24]!=0)begin
   if(wanted[`BANK.notes[j*7+:7]-60] && !seen[`BANK.notes[j*7+:7]-60])begin
    seen[`BANK.notes[j*7+:7]-60]=1;last_voice_at=$time;
   end
  end
 end
 // The optimized serial timing must still satisfy the documented limits.
 time low_at=0,fall_at=0;integer falls=0,bursts=0;
 always @(negedge scl0)if(dut.synth_rst_n)begin
  if(fall_at && $time-fall_at>1000000)begin
   if(falls!=16)$fatal(1,"incomplete serial burst");
   if($time-fall_at<2000000)$fatal(1,"serial timeout gap too short");
   falls=0;bursts=bursts+1;
  end
  fall_at=$time;low_at=$time;falls=falls+1;
 end
 always @(posedge scl0)if(low_at && dut.synth_rst_n && $time-low_at<1000000)
  if($time-low_at<2030 || $time-low_at>2040)$fatal(1,"optimized SCL width");
 task test_case(input [31:0] mask,input integer phase);
 integer n;
 begin
  measuring=0;rst=0;touch0=0;touch1=0;fall_at=0;falls=0;low_at=0;
  repeat(16)@(negedge clk50);rst=1;wait(dut.synth_rst_n);
  // Warm engine reset and obtain two known empty frames using production timing.
  repeat(2)@(posedge dut.key_bank_frame_valid[0]);
  if(phase==0)begin #10000;end
  else begin @(negedge scl0);#1000;end // Just missed the module's frame latch.
  @(negedge clk);wanted=mask;seen=0;started=$time;
  keys_at=0;event_at=0;pcm_at=0;pt_at=0;i2s_at=0;last_voice_at=0;measuring=1;
  touch0=mask[15:0];touch1=mask[31:16];n=0;
  while((seen!=mask || pt_at==0 || i2s_at==0) && n<250000)begin @(negedge clk);n=n+1;end
  if(seen!=mask || !keys_at || !event_at || !pcm_at || !pt_at || !i2s_at)$fatal(1,"missing onset mask=%h seen=%h",mask,seen);
  scenario=scenario+1;
  $display("RESULT,%0d,%h,%0d,%0d,%0d,%0d,%0d,%0d,%0d",scenario,mask,phase,keys_at-started,event_at-started,pcm_at-started,pt_at-started,i2s_at-started,last_voice_at-started);
  // A single key must meet 5ms at BOTH actual digital DAC pin interfaces.
  if((mask & (mask-1))==0 && (pt_at-started>5000000 || i2s_at-started>5000000))$fatal(1,"single-key digital onset exceeds5ms");
  if(dut.key_mapping_error || dut.actual_instrument!=0)$fatal(1,"piano/key-map invariant");
  measuring=0;
 end endtask
 initial begin
  #1;rst=1;#1;rst=0;
  test_case(32'h00000001,0);
  test_case(32'h80000000,1);
  test_case(32'h80000001,1);
  test_case(32'hffffffff,1);
  if(bursts<8)$fatal(1,"serial timing coverage");
  $display("PASS focused keyboard-to-dual-DAC latency; physical TTP sensing and analog DAC delay excluded");$finish;
 end
 initial begin #130000000;$fatal(1,"latency timeout");end
endmodule
