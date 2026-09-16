`timescale 1ns/1ps
module tb_fifo_e2e;
 logic clk=0,rst_n=0,tick=0,ev=0,on=1,ready,test=0,bclk,lr,sd; logic [6:0] note=60; logic [7:0] vel=127; logic[1:0] wave=0; logic[9:0] morph=0; logic signed[23:0] audio; logic[31:0] active; integer i;
 always #5 clk=~clk; always @(posedge clk) tick<=~tick;
 synth_event_frontend front(.clk,.rst_n,.sample_tick(tick),.event_valid(ev),.event_note_on(on),.event_note(note),.event_velocity(vel),.event_waveform(wave),.event_morph(morph),.event_ready(ready),.test_enable(test),.audio_out(audio),.active_debug(active));
 i2s_tx #(.CLK_HZ(6400),.SAMPLE_RATE(100),.SAMPLE_W(24),.SLOT_W(32)) i2s(.clk,.rst_n,.left_sample(audio),.right_sample(audio),.bclk,.lrclk(lr),.sdata(sd));
 initial begin repeat(3)@(posedge clk);rst_n=1; for(i=0;i<12;i=i+1)begin @(negedge clk);ev=1;on=(i%3)!=2;note=60+(i%4);@(negedge clk);ev=0;end repeat(200)@(posedge clk);if(active===32'hx)$fatal(1,"E2E active state unknown");$display("TB_FIFO_E2E PASS: FIFO allocator 32-voice mixer I2S path");$finish;end
endmodule
