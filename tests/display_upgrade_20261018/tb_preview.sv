`timescale 1ns/1ps
// Sample actual RTL at each logical pixel; exact nearest 3x replication is
// separately checked below. Full 2200x1125 scanning is tested by tb_video_1080.
module tb_preview;
 reg clk=0,rst_n=0;always #5 clk=~clk;
 reg [11:0] x=0,y=1080;reg de=0,hs=0,vs=0,blank=0;
 wire [8:0] wa;wire [9:0] sa;wire wr,sr;
 reg wp=1,sp=1;reg [48:0] wd=0;reg [36:0] sd=0;
 reg [48:0] wave[0:511];reg [36:0] spec[0:1023];
 wire [7:0] r,g,b;wire ode,ohs,ovs;
 wire ink,area,keyon;
 piano_status_overlay #(.MAPPING_CONFIRMED(0),.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) hud(
  10'(x/12'd3),10'(y/12'd3),{16'ha005,6'd4,24'h0abcde,7'd60,1'b1,4'd3},ink,area,keyon);
 wire[7:0]fr=ink?8'd240:(area?(keyon?8'd40:8'd16):r);
 wire[7:0]fg=ink?8'd240:(area?(keyon?8'd240:8'd32):g);
 wire[7:0]fb=ink?8'd200:(area?(keyon?8'd96:8'd48):b);

 integer lx,ly,dx,dy,f,pixels=0,phase_pixels=0,writes=0,specs=0,cycles=0;
 reg [23:0] expected;
 visual_renderer dut(clk,rst_n,x,y,de,hs,vs,blank,wp,sp,wd,sd,wa,sa,wr,sr,r,g,b,ode,ohs,ovs);
 always @(posedge clk)begin wd<=wave[wa];sd<=spec[sa];
  if(wr)begin wp<=0;writes=writes+1;end
  if(sr)begin sp<=0;specs=specs+1;end
  if(rst_n && de && dut.xy_busy)$fatal(1,"rebuild crossed active video");
 end
 task point(input integer px,py);
 begin @(negedge clk);x=12'(px);y=12'(py);de=1;repeat(4)@(negedge clk);end endtask
 initial begin
 $readmemh("sim_out_visual/render_wave_preview.hex",wave);$readmemh("sim_out_visual/render_spec.hex",spec);
 f=$fopen("sim_out_visual/frame_hud16.hex","w");
 repeat(3)@(negedge clk);rst_n=1;blank=1;@(negedge clk);blank=0;
 while(specs==0)begin @(negedge clk);cycles=cycles+1;if(cycles>99000)$fatal(1,"vblank budget");end
 while(dut.state!=0)@(negedge clk);
 for(ly=0;ly<360;ly=ly+1)for(lx=0;lx<640;lx=lx+1)begin
  point(lx*3,ly*3);$fdisplay(f,"%02x%02x%02x",fr,fg,fb);pixels=pixels+1;
  if(r==32 && g==210 && b==255)phase_pixels=phase_pixels+1;
 end
 if(writes!=1 || specs!=1 || phase_pixels<100)$fatal(1,"snapshot/visible pixels %d %d %d",writes,specs,phase_pixels);
 // Every subpixel in representative 3x3 blocks must match the logical sample.
 for(ly=20;ly<350;ly=ly+37)for(lx=10;lx<630;lx=lx+41)begin
  point(lx*3,ly*3);expected={r,g,b};
  for(dy=0;dy<3;dy=dy+1)for(dx=0;dx<3;dx=dx+1)begin point(lx*3+dx,ly*3+dy);if({r,g,b}!==expected)$fatal(1,"3x block mismatch");end
 end
 @(negedge clk);de=0;blank=1;@(negedge clk);blank=0;repeat(16)@(negedge clk);
 if(!dut.xy_signal || !dut.initialized || dut.xy_busy)$fatal(1,"old trace erased without new snapshot");
 $fclose(f);$display("PASS actual RTL 640x360 logical pixels, exact3x blocks produce1920x1080, vblank budget and sparse-snapshot retention");$finish;
 end
 initial begin #30000000;$fatal(1,"renderer timeout");end
endmodule
