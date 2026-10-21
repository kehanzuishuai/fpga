`timescale 1ns/1ps
module tb_generic;
reg clk=0,rst_n=0,req=0;always #5 clk=~clk;
reg[6:0]note=7'bx;reg[7:0]vel=0;wire[31:0]inc;
wire busy;wire[31:0]we,done;wire[8:0]addr;wire[31:0]data;wire[21:0]release_slope;
note_freq_table f(.midi_note(note),.phase_inc(inc));GSR GSR(.GSRI(1'b1));
piano_note_loader d(.clk(clk),.rst_n(rst_n),.req_valid(req),.req_voice(5'd0),.req_note(note),.req_velocity(vel),.req_inc0(inc),.busy(busy),.voice_ready(32'hffffffff),.ld_we(we),.ld_addr(addr),.ld_data(data),.ld_done(done),.ld_rel_slope(release_slope));
integer n,k,cycles,fo,writes=0;reg[7:0]vels[0:4];
always @(posedge clk)if(rst_n && |we)begin
 if(^data===1'bx)$fatal(1,"unknown parameter");
 if(we!==32'd1)$fatal(1,"wrong target voice");
 $fdisplay(fo,"%0d,%0d,%0d,%0d",note,vel,addr,data);writes=writes+1;
end
initial begin
vels[0]=1;vels[1]=40;vels[2]=80;vels[3]=100;vels[4]=127;
fo=$fopen("tests/recording_20261018_150135/generic/words.csv","w");
repeat(6)@(negedge clk);rst_n=1;
for(n=48;n<=91;n=n+1)for(k=0;k<5;k=k+1)begin
 @(negedge clk);note=n;vel=vels[k];req=1;@(negedge clk);req=0;cycles=0;
 while(!(|done))begin @(negedge clk);cycles=cycles+1;if(cycles>4000)$fatal(1,"timeout");end
 @(negedge clk);
end
$fclose(fo);if(writes!=88000)$fatal(1,"write count%0d",writes);
$display("PASS generic post-synthesis 44 notes x5 velocities,88000 words");$finish;
end
endmodule
