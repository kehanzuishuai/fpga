`timescale 1ns/1ps
module tb_pair_serial;
 reg clk=0,rst=0;always #40.69 clk=~clk;
 reg[15:0]touch0=0,touch1=0;wire scl0,scl1,model0,model1;
 reg fault0=0,fault1=0;
 wire sdo0=fault0?1'b0:model0,sdo1=fault1?1'b0:model1;
 ttp229_bfm #(.KEY16(1),.MULTI(1)) b0(touch0,scl0,model0),b1(touch1,scl1,model1);
 wire[31:0]keys,raw,ar,rs;wire[1:0]fv,fe,busy,m16,m8;wire me;wire[63:0]rej;
 ttp229_keyboard_pair dut(clk,rst,scl0,scl1,sdo0,sdo1,keys,ar,raw,rs,fv,fe,busy,m16,m8,me,rej);
 wire[31:0]permuted;wire perm_error;
 ttp229_keyboard_pair #(.RAW_MAP0(1),.RAW_INDEX0(64'h0123456789abcdef),
 .RAW_MAP1(1),.RAW_INDEX1(64'h0fedcba987654321)) perm(
 .clk(clk),.rst_n(rst),.sdo0(sdo0),.sdo1(sdo1),.key_state(permuted),.mapping_error(perm_error));
 // Duplicate MIDI across banks must disable both admissions.
 wire[31:0]badkeys;wire badmap;
 ttp229_keyboard_pair #(.NOTES(224'd0)) invalid(
 .clk(clk),.rst_n(rst),.sdo0(sdo0),.sdo1(sdo1),.key_state(badkeys),.mapping_error(badmap));
 integer checks=0,k,error0=0,error1=0;time fall0=0,fall1=0,lastfall0=0,lastfall1=0;
 integer edges0=0,edges1=0;
 // These use the production 123/36864/246 counts, not an accelerated reader.
 always @(negedge scl0)if(rst)begin
  if(lastfall0 && $time-lastfall0>1000000)begin if(edges0!=16)$fatal(1,"bank0 incomplete frame");edges0=0;end
  lastfall0=$time;fall0=$time;edges0++;
 end
 always @(posedge scl0)if(rst && fall0 && $time-fall0<1000000)
  if($time-fall0<10000 || $time-fall0>10020)$fatal(1,"bank0 SCL low width");
 always @(negedge scl1)if(rst)begin
  if(lastfall1 && $time-lastfall1>1000000)begin if(edges1!=16)$fatal(1,"bank1 incomplete frame");edges1=0;end
  lastfall1=$time;fall1=$time;edges1++;
 end
 always @(posedge scl1)if(rst && fall1 && $time-fall1<1000000)
  if($time-fall1<10000 || $time-fall1>10020)$fatal(1,"bank1 SCL low width");
 always @(posedge clk)if(rst)begin if(fe[0])error0++;if(fe[1])error1++;
  if(badkeys || !badmap)$fatal(1,"duplicate note table admitted");end
 task waitkeys(input[31:0]want);integer n,j;reg[31:0]expected_perm;begin
  n=0;while(keys!==want && n<160000)begin @(negedge clk);n++;end
  repeat(5)@(negedge clk);checks++;
  if(keys!==want || me)$fatal(1,"serial pair want%h got%h",want,keys);
  expected_perm[31:16]={want[16],want[31:17]};
  for(j=0;j<16;j++)expected_perm[j]=want[15-j];
  if(permuted!==expected_perm || perm_error)$fatal(1,"independent per-bank raw permutation");
 end endtask
 initial begin
  #1;rst=1;#1;rst=0;repeat(4)@(negedge clk);rst=1;
  touch0=16'hffff;touch1=16'hffff;waitkeys(32'hffffffff);
  touch0=0;touch1=0;waitkeys(0);
  for(k=0;k<32;k++)begin
   if(k<16)touch0=16'b1<<k;else touch1=16'b1<<(k-16);
   waitkeys(32'b1<<k);touch0=0;touch1=0;waitkeys(0);
  end
  touch0=16'h8001;touch1=16'h8001;waitkeys(32'h80018001);
  touch0=16'h0001;waitkeys(32'h80010001);
  touch1=16'h0001;waitkeys(32'h00010001);
  touch0=0;touch1=0;waitkeys(0);
  // A disconnected/stuck-active second module must not block the first one.
  @(negedge clk);fault1=1;repeat(90000)@(negedge clk);
  touch0=16'h1234;waitkeys(32'h00001234);
  if(error1<1 || error0)$fatal(1,"bank1 fault not isolated");
  touch0=0;waitkeys(0);fault1=0;touch1=16'h8000;waitkeys(32'h80000000);
  touch1=0;waitkeys(0);
  fault0=1;repeat(90000)@(negedge clk);touch1=16'h2481;waitkeys(32'h24810000);
  if(error0<1)$fatal(1,"bank0 fault not exercised");touch1=0;waitkeys(0);
  fault0=0;
  $display("PASS serial pair: %0d cases, production timing, 32 physical bits, independent frame admission/faults/raw permutations, duplicate table rejected",checks);$finish;
 end
 initial begin #700000000;$fatal(1,"serial timeout");end
endmodule
