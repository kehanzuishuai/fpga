`timescale 1ns/1ps
`define BANK dut.u_synth_top.u_synth.u_core.u_bank
module tb_high_chord;
reg clk50=0,rst_n=0;always #10 clk50=~clk50;
reg[15:0]touch=0;wire scl,sdo;wire bc,lr,da,pbc,plr,pda,pa,cp,cn;wire[2:0]vp,vn;
ttp229_bfm #(.KEY16(1),.MULTI(1)) chip(touch,scl,sdo);
tang_mega_138k_pro_top dut(.clk_50m(clk50),.rst_n(rst_n),.ttp229_scl(scl),.ttp229_sdo(sdo),.i2s_bclk(bc),.i2s_lrck(lr),.i2s_data(da),.pcm5102_bclk(pbc),.pcm5102_lrck(plr),.pcm5102_data(pda),.audio_pa_en(pa),.video_d_p(vp),.video_d_n(vn),.video_ck_p(cp),.video_ck_n(cn));
wire clk=dut.clk_12m288;reg[15:0]accepted=0;integer ons=0,offs=0,nonzero=0;
always @(posedge clk)if(dut.synth_rst_n)begin
 if(dut.event_valid&&dut.event_ready)begin
  if(dut.event_note!==60+dut.event_key_index)$fatal(1,"chord MIDI");
  accepted[dut.event_key_index]=dut.event_note_on;
  if(dut.event_note_on)ons=ons+1;else offs=offs+1;
 end
 if(dut.visual_pcm_valid && dut.visual_pcm!=0)nonzero=nonzero+1;
end
function[15:0]held();integer v,n;begin held=0;for(v=0;v<32;v=v+1)
 if(`BANK.voice_active[v]&&!`BANK.voice_releasing[v])begin n=`BANK.notes[v*7+:7]-60;if(n<0||n>15)$fatal(1,"note bounds");held[n]=1;end end endfunction
task play(input[15:0]v);integer n;begin touch=v;n=0;
 while((accepted!==v || held()!==v || dut.fifo_level || `BANK.ld_busy || dut.key_state!==v) && n<220000)begin @(negedge clk);n=n+1;end
 if(n==220000)$fatal(1,"high chord failed %h accepted %h held %h",v,accepted,held());
 repeat(1024)@(negedge clk);
end endtask
initial begin
 #1;rst_n=1;#1;rst_n=0;#1000;rst_n=1;wait(dut.synth_rst_n);
 play(16'h8001);play(16'h8000);play(0);
 play(16'hf000);play(16'ha000);play(0);
 play(16'h1001);play(16'h1000);play(0);
 if(ons!=8 || offs!=8 || nonzero<100)$fatal(1,"chord coverage on=%0d off=%0d pcm=%0d",ons,offs,nonzero);
 if(dut.diagnostic_chain[47:0]!==48'h000800080008)$fatal(1,"diagnostic chord counts");
 $display("PASS default serial low/high chord and high-four separate releases: 8 On/8 Off, allocation/load/play=8, nonzero PCM=%0d",nonzero);$finish;
end
initial begin #150000000;$fatal(1,"high chord timeout");end
endmodule
