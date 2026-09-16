`timescale 1ns/1ps
module tb_fifo_e2e;
  logic clk=0,rst_n=0,tick=0,ev=0,on=1,ready,test=0,bclk,lr,sdata;
  logic [6:0] note=60; logic [7:0] vel=127; logic [1:0] wave=0; logic [9:0] morph=0;
  logic signed [23:0] audio; logic [31:0] active;
  logic signed [23:0] captured;
  logic expected;
  integer i,bit_pos;
  always #5 clk=~clk;
  synth_event_frontend #(.FIFO_DEPTH(8)) front(.clk,.rst_n,.sample_tick(tick),.event_valid(ev),.event_note_on(on),
    .event_note(note),.event_velocity(vel),.event_waveform(wave),.event_morph(morph),.event_ready(ready),
    .test_enable(test),.audio_out(audio),.active_debug(active));
  i2s_tx #(.CLK_HZ(12800),.SAMPLE_RATE(100),.SAMPLE_W(24),.SLOT_W(32)) i2s(
    .clk,.rst_n,.left_sample(audio),.right_sample(audio),.bclk,.lrclk(lr),.sdata);
  task send_event(input logic is_on,input [6:0] value);
    begin
      while(!ready)@(posedge clk);
      @(negedge clk);on=is_on;note=value;ev=1;
      @(negedge clk);ev=0;
    end
  endtask
  task sample_pulse;
    begin @(negedge clk);tick=1;@(negedge clk);tick=0;end
  endtask
  initial begin
    repeat(4)@(posedge clk);rst_n=1;
    for(i=0;i<32;i=i+1)send_event(1'b1,7'd36+i[6:0]);
    repeat(5)@(posedge clk); #1;
    if(active!==32'hffff_ffff)$fatal(1,"E2E did not allocate 32 independent Voices");
    for(i=0;i<80;i=i+1)sample_pulse();
    if(audio===24'shx || audio==0)$fatal(1,"E2E mixer produced invalid/silent audio");

    // Freeze the sample domain, then prove the actual mixer output is the
    // exact 24-bit word serialized by the downstream I2S block.
    begin: FIND_LEFT_START
      forever begin
        @(negedge bclk); #1;
        if(lr==0 && i2s.bit_in_slot==1) begin
          captured=audio;
          if(sdata!==0)$fatal(1,"E2E I2S delay bit invalid");
          disable FIND_LEFT_START;
        end
      end
    end
    for(bit_pos=1;bit_pos<32;bit_pos=bit_pos+1) begin
      @(negedge bclk); #1;
      expected=(bit_pos<=24)?captured[24-bit_pos]:1'b0;
      if(sdata!==expected)$fatal(1,"E2E serialized PCM mismatch at bit %0d",bit_pos);
    end

    send_event(1'b1,7'd100);repeat(3)@(posedge clk);#1;
    if(active!==32'hffff_ffff || front.core.u_bank.notes[6:0]!==7'd100)
      $fatal(1,"E2E full-load oldest Voice steal failed");
    send_event(1'b0,7'd100);repeat(2)@(posedge clk);#1;
    if(front.core.u_bank.G_VOICE[0].u_voice.u_env.stage!==2'd0)
      $fatal(1,"E2E note_off did not reach stolen Voice envelope");
    $display("TB_FIFO_E2E PASS: events -> FIFO -> allocator -> 32 Voices -> mixer -> exact I2S word");
    $finish;
  end
endmodule
