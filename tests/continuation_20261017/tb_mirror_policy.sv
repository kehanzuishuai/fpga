`timescale 1ns/1ps
module tb_mirror_policy;
reg clk=0,rst_n=0;always #40.69 clk=~clk;
reg[15:0]touch=0;wire scl,sdo;wire[15:0]keys,raw;wire fv,fe,busy,m16,m8;
ttp229_bfm #(.KEY16(1),.MULTI(1)) chip(touch,scl,sdo);
ttp229_reader #(.STRICT_IDLE(1)) reader(clk,rst_n,scl,sdo,keys,fv,fe,busy,raw,m16,m8);
task frames(input integer n);integer j;begin for(j=0;j<n;j=j+1)begin @(posedge fv);@(negedge clk);end end endtask
initial begin
 #1;rst_n=1;#1;rst_n=0;#1000;rst_n=1;
 touch=16'hffff;frames(4);
 if(raw!==16'hffff || keys!==16'h00ff || m16)$fatal(1,"cold symmetric-frame policy differs");
 $display("OBSERVED cold raw=ffff -> keys=00ff: conservative mirror guard, not 16-key hardware proof");
 touch=16'hf000;frames(4);
 if(raw!==16'hf000 || keys!==16'hf000 || !m16)$fatal(1,"upper-four cold proof rejected");
 touch=16'hffff;frames(4);
 if(keys!==16'hffff)$fatal(1,"all16 after asymmetric proof rejected");
 $display("PASS assumed serial mirror policy: high four alone accepted, symmetric initial frame suppresses upper byte until asymmetric proof");$finish;
end
initial begin #80000000;$fatal(1,"mirror timeout");end
endmodule
