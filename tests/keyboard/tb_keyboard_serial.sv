`timescale 1ns/1ps
module tb_keyboard_serial;
reg clk=0,rst_n=0;always #40.690 clk=~clk;
reg[15:0]touch=0;reg stuck=0;wire scl,chip_sdo;wire sdo=stuck?1'b0:chip_sdo;
wire[15:0]keys,raw;wire valid,error,busy,m16,m8;
ttp229_bfm #(.KEY16(1),.MULTI(1),.DV_EN(1)) chip(touch,scl,chip_sdo);
ttp229_reader #(.STRICT_IDLE(1),.MIRROR_GUARD(0)) reader(
 clk,rst_n,scl,sdo,keys,valid,error,busy,raw,m16,m8);
integer checks=0,errors=0,frames=0;
always @(posedge clk)if(rst_n)begin if(error)errors=errors+1;if(valid)frames=frames+1;end
task converge(input[15:0]wanted);
integer guard;
begin touch=wanted;guard=0;
 while(keys!==wanted && guard<140000)begin @(negedge clk);guard=guard+1;end
 checks=checks+1;
 if(keys!==wanted)$fatal(1,"serial mismatch touch=%h read=%h",wanted,keys);
end endtask
integer k;reg[15:0]before_stuck;
initial begin
 $dumpfile("tests/results/keyboard/keyboard_serial.vcd");
 $dumpvars(0,clk,rst_n,touch,scl,sdo,raw,keys,valid,error,busy);
 #1;rst_n=1;#1;rst_n=0;repeat(4)@(negedge clk);rst_n=1;
 // FFFF first is deliberately symmetric: the legacy mirror guard would suppress upper bits.
 converge(16'hffff);converge(0);
 for(k=0;k<16;k=k+1)begin converge(16'b1<<k);converge(0);end
 converge(3);converge(7);converge(31);converge(255);converge(65535);
 converge(16'hfffd);converge(0);
 before_stuck=keys;stuck=1;repeat(170000)@(negedge clk);
 if(errors==0 || keys!==before_stuck)$fatal(1,"stuck-active handling");
 stuck=0;converge(16'h0015);converge(16'h0011);converge(0);
 // A change within a serial burst is latched by the BFM for the next burst.
 wait(busy);repeat(1500)@(negedge clk);touch=16'h8001;converge(16'h8001);converge(0);
 rst_n=0;touch=16'h0080;repeat(5)@(negedge clk);rst_n=1;
 converge(16'h0080);converge(0);
 $display("PASS TTP229 assumed serial profile: %0d checks, %0d valid frames, %0d stuck-idle errors; actual BIT-TREE silicon/protocol not confirmed",checks,frames,errors);
 $finish;
end
initial begin #400000000;$fatal(1,"serial timeout");end
endmodule
