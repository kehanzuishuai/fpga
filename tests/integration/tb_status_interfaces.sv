`timescale 1ns/1ps
module tb_status_interfaces;
reg ac=0,pc=0,rst_n=0,fs=0;
always #7 ac=~ac;always #11 pc=~pc;
reg [28:0] number=0;wire [57:0] received;
always @(negedge ac)if(rst_n)number=number+1;
piano_status_cdc cdc(ac,rst_n,1'b1,{number,~number},pc,rst_n,fs,received);
integer frames=0,updates=0;reg [57:0] previous=0;reg frame_edge;
always @(negedge pc)begin frames=frames+1;fs=(frames%17)==0;end
always @(posedge pc)begin
frame_edge=fs;#1;
if(rst_n && received!==previous)begin
 if(!frame_edge)$fatal(1,"status changed outside vblank");
 if((received[57:29]^received[28:0])!==29'h1fffffff)$fatal(1,"torn multibit snapshot");
 updates=updates+1;
end
previous=received;
end
reg [9:0]x=0,y=168;
reg [57:0] status={16'ha005,6'd32,24'h800001,7'd61,1'b1,4'd3};
wire ink,area,keyon;
piano_status_overlay hud(x,y,status,ink,area,keyon);
task character(input integer column,input integer row,input [7:0] expected);
begin x=10'(column*8);y=10'(row);#1;
if(hud.ch!==expected)$fatal(1,"HUD char col%0d row%0d got%h expected%h",column,row,hud.ch,expected);
end endtask
initial begin
#1;rst_n=1;#1;rst_n=0;#40;rst_n=1;
character(0,168,"P");character(1,168,"I");character(14,168,"3");character(15,168,"2");
character(23,168,"C");character(24,168,"#");character(25,168,"4");
character(33,168,"0");character(34,168,"6");character(35,168,"1");
character(5,184,"A");character(8,184,"5");character(16,184,"8");character(21,184,"1");character(30,184,"3");
x=400;y=168;#1;if(!area || !keyon)$fatal(1,"key0");
x=412;#1;if(!area || keyon)$fatal(1,"key1");
x=580;#1;if(!area || !keyon)$fatal(1,"key15");
status[4]=0;character(23,168,"-");character(25,168,"-");
#20000;
if(updates<20)$fatal(1,"mailbox stalled");
rst_n=0;#1;if(received!==0)$fatal(1,"reset stale status");
#100;rst_n=1;#5000;
if(updates<25)$fatal(1,"reset recovery");
$display("PASS status HUD characters, real key bitmap, coherent 58bit CDC, vblank-only updates, reset/recovery; %0d snapshots",updates);$finish;
end
endmodule

