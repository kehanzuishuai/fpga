`timescale 1ns/1ps
`define BANK dut.u_synth_top.u_synth.u_core.u_bank
module tb_loadroute32;
 reg clk50=0,rst=0;always #10 clk50=~clk50;
 reg[15:0]touch0=0,touch1=0;wire scl0,scl1,sdo0,sdo1;
 ttp229_bfm #(.KEY16(1),.MULTI(1)) k0(touch0,scl0,sdo0),k1(touch1,scl1,sdo1);
 tang_mega_138k_pro_top #(.DISPLAY_ENABLE(0)) dut(.clk_50m(clk50),.rst_n(rst),
 .ttp229_scl(scl0),.ttp229_sdo(sdo0),.ttp229_2_scl(scl1),.ttp229_2_sdo(sdo1));
 wire clk=dut.clk_12m288;integer fd,writes=0;
 genvar g;generate for(g=0;g<32;g++)begin:CHECK
  reg[8:0]address;reg[31:0]data;
  always @(posedge clk)if(dut.synth_rst_n && `BANK.G_PARTIAL.G_VOICE[g].u_voice.ld_we)begin
   address=`BANK.G_PARTIAL.G_VOICE[g].u_voice.ld_addr;
   data=`BANK.G_PARTIAL.G_VOICE[g].u_voice.ld_data;
   if(!`BANK.G_PARTIAL.G_VOICE[g].u_voice.u_ram.we ||
      `BANK.G_PARTIAL.G_VOICE[g].u_voice.u_ram.waddr!==address ||
      `BANK.G_PARTIAL.G_VOICE[g].u_voice.u_ram.wdata!==data)$fatal(1,"Loader did not reach actual RAM%0d",g);
   $fdisplay(fd,"%0d,%0d,%0d,%0d",g,`BANK.notes[g*7+:7],address,data);writes++;
   #0.001;
   if(`BANK.G_PARTIAL.G_VOICE[g].u_voice.u_ram.mem[address]!==data)$fatal(1,"RAM write mismatch%0d",g);
  end
 end endgenerate
 initial begin
  fd=$fopen("tests/keyboard32_20261019/voice_ram_words.csv","w");
  #1;rst=1;#1;rst=0;#1000;rst=1;wait(dut.synth_rst_n);
  touch0=16'hffff;touch1=16'hffff;
  wait(writes==12800);repeat(20)@(negedge clk);
  if(`BANK.voice_active!==32'hffffffff)$fatal(1,"last voice not active");
  $fclose(fd);$display("PASS loadroute32: two serial modules -> FIFO -> Loader -> all32 actual Voice RAMs, %0d writes and readbacks",writes);$finish;
 end
 initial begin #25000000;$fatal(1,"RAM-route timeout writes%0d",writes);end
endmodule
