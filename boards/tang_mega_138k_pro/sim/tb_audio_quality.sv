`timescale 1ns/1ps
// Accelerated sample enables, same RTL/sample equations; no DAC clock claim.
module tb_audio_quality;
 reg clk=0,rst_n=0,tick=0,on=0,off=0,test=0,men=0;
 reg [6:0] note=69;reg [7:0] velocity=127;reg [1:0] waveform=0;
 reg [9:0] morph=0;
 always #5 clk=~clk;
 wire signed [23:0] audio;wire [31:0] active;wire [5:0] count;
 synth_core dut(.clk(clk),.rst_n(rst_n),.sample_tick(tick),.note_on(on),.note_off(off),
 .midi_note(note),.velocity(velocity),.waveform(waveform),.morph_enable(men),.morph(morph),
 .test_enable(test),.audio_out(audio),.active_debug(active),.active_voice_count(count));
 integer fp,scenario=0,index=0,k,baseline=0;
 always @(posedge clk)if(rst_n && tick)begin
   #1;
   if((^audio)===1'bx)$fatal(1,"unknown audio sample");
   $fwrite(fp,"%0d %0d %0d %0d %0d %0d %0d %0d\n",scenario,index,count,
      $signed(dut.sum),dut.u_gain.current_gain,dut.u_gain.target_gain,
      $signed(dut.normalized_sum),$signed(audio));
   if(!baseline && (audio==24'sh7fffff || audio==24'sh800000))
      $fatal(1,"core clipped scenario%0d sample%0d",scenario,index);
   index=index+1;
 end
 task samples(input integer n);
 integer j;
 begin for(j=0;j<n;j=j+1)begin
   @(negedge clk);tick=1;@(negedge clk);tick=0;repeat(6)@(negedge clk);
 end end endtask
 task reset_core;
 begin @(negedge clk);rst_n=0;tick=0;on=0;off=0;test=0;men=0;morph=0;
 repeat(3)@(negedge clk);rst_n=1;index=0;#1;
 if(count!==0 || audio!==0)$fatal(1,"audio reset");end endtask
 task event_note(input reg is_on);
 begin @(negedge clk);on=is_on;off=!is_on;
 @(negedge clk);on=0;off=0;repeat(4)@(negedge clk);end endtask
 task release_all(input integer n);
 integer j;
 begin for(j=0;j<n;j=j+1)event_note(0);samples(2304);
 if(count!==0 || audio!==0)$fatal(1,"release did not reach silence");end endtask
 initial begin
 baseline=$test$plusargs("baseline");
 if(baseline)fp=$fopen("sim_out_visual/audio_baseline.txt","w");
 else fp=$fopen("sim_out_visual/audio_quality.txt","w");
 if(!fp)$fatal(1,"audio output open");
 #1;rst_n=1;#1;rst_n=0;reset_core();test=1;samples(512);
 if(count!=32)$fatal(1,"diagnostic count");
 if(baseline)begin $fclose(fp);$display("PASS baseline audio trace captured");$finish;end
 scenario=1;reset_core();waveform=0;velocity=127;note=69;event_note(1);
 samples(8192);release_all(1);
 for(scenario=2;scenario<=5;scenario=scenario+1)begin
   reset_core();waveform=0;velocity=127;note=69;
   for(k=0;k<(1<<scenario);k=k+1)event_note(1);
   if(count!=(1<<scenario))$fatal(1,"simultaneous duplicate note count");
   samples(1024);release_all(1<<scenario);
 end
 for(scenario=6;scenario<=8;scenario=scenario+1)begin
   reset_core();waveform=2'(scenario-5);velocity=127;event_note(1);
   samples(4096);release_all(1);
 end
 scenario=9;reset_core();waveform=1;velocity=0;event_note(1);samples(256);
 if(audio!==0)$fatal(1,"zero velocity not silent");
 scenario=10;reset_core();waveform=0;velocity=1;event_note(1);samples(1024);release_all(1);
 scenario=11;reset_core();velocity=255;men=1;morph=0;event_note(1);
 samples(1024);morph=1023;samples(1024);release_all(1);
 scenario=12;reset_core();men=0;velocity=127;waveform=1;
 for(k=0;k<16;k=k+1)begin event_note(1);samples(4);event_note(0);samples(4);end
 samples(2304);if(count!==0)$fatal(1,"rapid on/off release");
 $fclose(fp);$display("PASS real core gain/startup/1,4,8,16,32 Voice/velocity/morph/retrigger/release/reset");$finish;
 end
 initial begin #10000000;$fatal(1,"audio quality timeout");end
endmodule
