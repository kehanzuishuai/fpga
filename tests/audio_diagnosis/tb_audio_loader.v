`timescale 1ns/1ps
module tb_audio_loader;
reg clk=0,rst_n=0,req=0;always #5 clk=~clk;
reg [6:0] note=7'bx;reg [7:0] vel=0;wire [31:0] inc;wire busy,we,done;wire [8:0] addr;wire [31:0] data;wire [21:0] release_slope;
note_freq_table f(.midi_note(note),.phase_inc(inc));
piano_note_loader #(.VOICES(1),.IDX_W(1)) d(.clk(clk),.rst_n(rst_n),.req_valid(req),.req_voice(1'b0),.req_note(note),.req_velocity(vel),.req_inc0(inc),.busy(busy),.voice_ready(1'b1),.ld_we(we),.ld_addr(addr),.ld_data(data),.ld_done(done),.ld_rel_slope(release_slope));
integer fo,n,v,k,cycles=0,writes=0,requests=0;reg [7:0] velocities[0:9];
always @(posedge clk)if(rst_n&&we)begin if(^data===1'bx)$fatal(1,"loader X");$fdisplay(fo,"%0d,%0d,%0d,%0d",note,vel,addr,data);writes=writes+1;end
initial begin
velocities[0]=1;velocities[1]=39;velocities[2]=40;velocities[3]=60;velocities[4]=79;velocities[5]=80;velocities[6]=100;velocities[7]=119;velocities[8]=120;velocities[9]=127;
fo=$fopen("tests/audio_diagnosis/loader_words.csv","w");repeat(5)@(negedge clk);rst_n=1;
for(n=24;n<=104;n=n+1)for(k=0;k<10;k=k+1)begin
 @(negedge clk);note=n;vel=velocities[k];req=1;@(negedge clk);req=0;cycles=0;
 while(!done)begin @(negedge clk);cycles=cycles+1;if(cycles>3000)$fatal(1,"loader timeout");end
 if(release_slope[21])$fatal(1,"release signed overflow");requests=requests+1;@(negedge clk);
end
$fclose(fo);if(writes!=810*400)$fatal(1,"words %0d",writes);$display("PASS loader %0d requests %0d words",requests,writes);$finish;end
endmodule
