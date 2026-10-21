`timescale 1ns/1ps
module tb_tail_gap;
reg clk=0,rst_n=0;always #40.69 clk=~clk;
reg[7:0] div=0;reg sample_tick=0;
always @(posedge clk)begin
 if(!rst_n)begin div<=0;sample_tick<=0;end
 else begin div<=div+1'b1;sample_tick<=(div==255);end
end
reg start=0,stop=0,ld_we=0,ld_done=0;
reg[8:0]ld_addr=0;reg[31:0]ld_data=0;
wire ld_ready,active,releasing,strobe,overrun;
wire signed[23:0]sample;
piano_partial_voice dut(.clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),
 .start(start),.stop(stop),.phase_inc_in(32'd39370534),.note_in(7'd69),
 .velocity_in(8'd100),.waveform_in(2'd3),.morph_enable(1'b0),.morph_in(10'd0),
 .ld_ready(ld_ready),.ld_we(ld_we),.ld_addr(ld_addr),.ld_data(ld_data),
 .ld_done(ld_done),.ld_rel_slope(22'd262144),.hammer_enable(1'b0),
 .active(active),.releasing(releasing),.env_level(),.note(),.phase_inc(),
 .sample(sample),.dbg_sample_strobe(strobe),.dbg_rel(),.dbg_fade(),.dbg_overrun(overrun));
integer case_id=0,ns=0,first_sound=0,gap=0,later_sound=0,checks=0;
always @(posedge clk)if(rst_n)begin
 if(overrun)$fatal(1,"sample deadline overrun");
 if(strobe)begin
  if(ns<192 && sample!=0)first_sound=first_sound+1;
  if(ns>=384 && ns<576 && sample==0)gap=gap+1;
  if(ns>=620 && ns<760 && sample!=0)later_sound=later_sound+1;
  ns=ns+1;
 end
end
task pulse_start;begin @(negedge clk);start=1;@(negedge clk);start=0;end endtask
task word(input integer addr,input[31:0]value);begin
 @(negedge clk);ld_addr=addr;ld_data=value;ld_we=1;
 @(negedge clk);ld_we=0;
end endtask
task load_note(input[11:0]future_level,input missing);
 integer s,b;reg[11:0]level;
 begin
  pulse_start;wait(ld_ready);ns=0;first_sound=0;gap=0;later_sound=0;
  for(s=0;s<16;s=s+1)begin
   word(s*32,(s==0 && !missing)?32'd2460658:32'd0);
   word(s*32+1,0);word(s*32+2,32'h03400000);word(s*32+3,0);
   for(b=0;b<21;b=b+1)begin
    level=12'hfff;
    if(s==0 && !missing)begin
     level=12'd3600;
     if(b==0)level=12'd2000;
     if(b==3)level=future_level;
    end
    word(s*32+4+b,{20'd0,level});
   end
  end
`ifndef LEGACY_VOICE
  if(dut.future_audible !== (missing?21'd0:(future_level<=3301?21'd9:21'd1)))
   $fatal(1,"future mask threshold/clear incorrect");
`endif
  @(negedge clk);ld_done=1;@(negedge clk);ld_done=0;
 end
endtask
task ticks(input integer n);begin repeat(n)@(negedge sample_tick);repeat(16)@(negedge clk);end endtask
initial begin
 $dumpfile("tests/tail_fix_20261018/tail_gap.vcd");
 $dumpvars(0,rst_n,sample_tick,active,sample,case_id,dut.seg,dut.vstate);
`ifndef LEGACY_VOICE
 $dumpvars(0,dut.future_audible);
`endif
 repeat(12)@(negedge clk);rst_n=1;
 case_id=1;load_note(12'd2000,0);ticks(420);
 if(!active || first_sound==0 || gap==0)$fatal(1,"held Voice was retired in a temporary silent gap");
 checks=checks+1;ticks(320);
 if(later_sound==0)$fatal(1,"later breakpoint failed to sound after gap");
 checks=checks+1;ticks(1000);
 if(active)$fatal(1,"held voice must still decay to idle when no future target remains");
 checks=checks+1;
 case_id=2;load_note(12'd2000,0);ticks(420);
 if(!active)$fatal(1,"release case lost held voice before NoteOff");
 @(negedge clk);stop=1;@(negedge clk);stop=0;ticks(4);
 if(active)$fatal(1,"NoteOff in silent gap must not wait for future breakpoints");
 checks=checks+1;
 case_id=3;load_note(12'd2000,0);ticks(420);pulse_start;ticks(4);
 if(!ld_ready)$fatal(1,"voice steal in gap failed to reach loader");
 checks=checks+1;
 load_note(12'hfff,1);ticks(600);
 if(active || first_sound || later_sound)$fatal(1,"silent reload retained stale future mask");
 checks=checks+1;
 case_id=4;load_note(12'd3302,0);ticks(420);
 if(active)$fatal(1,"inaudible future target must not keep voice alive");
 checks=checks+1;
 case_id=5;load_note(12'd3301,0);ticks(420);
 if(!active)$fatal(1,"last audible target code was discarded");
 checks=checks+1;
 rst_n=0;repeat(12)@(negedge clk);rst_n=1;repeat(4)@(negedge clk);
 if(active)$fatal(1,"reset did not clear voice");
`ifndef LEGACY_VOICE
 if(dut.future_audible!==0)$fatal(1,"reset did not clear future mask");
`endif
 checks=checks+1;
 $display("PASS tail-gap regression: %0d checks; held gap/resume/natural end/NoteOff/steal/reload/threshold/reset; no overrun",checks);$finish;
end
initial begin #200000000;$fatal(1,"tail-gap timeout");end
endmodule
