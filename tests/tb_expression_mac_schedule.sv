module tb_expression_mac_schedule;
 reg clk=0,clock_enable=1;always #5 if(clock_enable)clk=~clk;
 reg rst_n=0,tick=0,start=0,stop=0,ld_we=0,ld_done=0;
 reg [8:0] ld_addr=0;reg [31:0] ld_data=0;reg [21:0] ratio=65536;
 wire ready,ref_ready,valid,ref_valid,overrun,ref_overrun;
 wire gain_valid,ref_gain_valid;wire [15:0] gain,ref_gain;wire [2:0] monitor_phase,ref_monitor_phase;
 wire signed [23:0] sample,ref_sample;
 piano_partial_voice dut(.clk(clk),.rst_n(rst_n),.sample_tick(tick),.start(start),.stop(stop),
  .expression_ratio(ratio),.expression_glide(7'd100),.expression_vibrato(7'd100),
  .phase_inc_in(32'd12345),.note_in(7'd60),.velocity_in(8'd100),.waveform_in(2'd0),.morph_enable(1'b0),.morph_in(10'd0),
  .ld_ready(ready),.ld_we(ld_we),.ld_addr(ld_addr),.ld_data(ld_data),.ld_done(ld_done),.ld_rel_slope(22'd1000),.hammer_enable(1'b1),
  .sample(sample),.dbg_sample_strobe(valid),.dbg_overrun(overrun),.monitor_gain_valid(gain_valid),.monitor_gain(gain),.monitor_phase(monitor_phase));
 piano_partial_voice_reference reference(.clk(clk),.rst_n(rst_n),.sample_tick(tick),.start(start),.stop(stop),
  .expression_ratio(ratio),.expression_glide(7'd100),.expression_vibrato(7'd100),
  .phase_inc_in(32'd12345),.note_in(7'd60),.velocity_in(8'd100),.waveform_in(2'd0),.morph_enable(1'b0),.morph_in(10'd0),
  .ld_ready(ref_ready),.ld_we(ld_we),.ld_addr(ld_addr),.ld_data(ld_data),.ld_done(ld_done),.ld_rel_slope(22'd1000),.hammer_enable(1'b1),
  .sample(ref_sample),.dbg_sample_strobe(ref_valid),.dbg_overrun(ref_overrun),.monitor_gain_valid(ref_gain_valid),.monitor_gain(ref_gain),.monitor_phase(ref_monitor_phase));
 integer frame,j,k,heard=0;reg [27:0] inc;reg [63:0] lo,hi,upper,product;
 initial begin
  #12;rst_n=1;@(negedge clk);start=1;@(negedge clk);start=0;
  wait(ready&&ref_ready);@(negedge clk);
  for(j=0;j<512;j=j+1)begin
   ld_we=1;ld_addr=9'(j);
   case(j%32)
    0:ld_data=$urandom&32'h0fffffff;
    1:ld_data=$urandom&32'h0fffffff;
    default:ld_data=0;
   endcase
   @(negedge clk);
  end
  ld_we=0;ld_done=1;@(negedge clk);ld_done=0;
  for(frame=0;frame<1024;frame=frame+1)begin
   case(frame%8)
    0:ratio=65536;1:ratio=0;2:ratio=32768;3:ratio=2097152;4:ratio=22'h3fffff;
    default:ratio=$urandom;
   endcase
   stop=(frame==768);tick=1;@(negedge clk);tick=0;stop=0;
   for(k=1;k<256;k=k+1)begin
    if(valid!==ref_valid || (valid && sample!==ref_sample))$fatal(1,"MAC schedule sample/strobe mismatch frame %d cycle %d",frame,k);
    if(valid && (^sample===1'bx))$fatal(1,"unknown voice output");
    if(gain_valid!==ref_gain_valid || (gain_valid && (gain!==ref_gain || monitor_phase!==ref_monitor_phase)))$fatal(1,"ADSR monitor mismatch");
    if(overrun || ref_overrun)$fatal(1,"voice budget overrun");
    if(valid && sample!=0)heard=heard+1;
    @(negedge clk);
   end
   for(j=0;j<16;j=j+1)
    if(dut.u_ram.mem[j*32+1]!==reference.u_ram.mem[j*32+1] || dut.u_ram.mem[j*32+2]!==reference.u_ram.mem[j*32+2])
     $fatal(1,"phase/level RAM mismatch frame %d partial %d",frame,j);
  end
  if(heard<100)$fatal(1,"insufficient audible coverage");
  // Verify the actual final adder with full-width boundaries and random data.
  clock_enable=0;
  for(j=0;j<101232;j=j+1)begin
   if(j<1232)begin inc=28'd1<<((j/2)/22);ratio=22'd1<<((j/2)%22);if(j%2)begin inc=~inc;ratio=~ratio;end end
   else begin inc=$urandom;ratio=$urandom;end
   lo=inc[25:0];lo=lo*ratio[16:0];hi=inc[25:0];hi=hi*ratio[21:17];upper=inc[27:26];upper=upper*ratio;
   dut.phase_low=lo[43:16]+{hi[26:0],1'b0};dut.mul_p=upper;product=inc;product=product*ratio;
   #1;if(dut.shared_phase_increment!==product[43:16])$fatal(1,"three-MAC arithmetic mismatch");
  end
  $display("PASS three-MAC: 1024 frames sample/strobe/phase/level/ADSR monitor bit-exact including release, no overrun, 100000 full-width products and boundaries");$finish;
 end
 initial begin #10000000;$fatal(1,"schedule test timeout");end
endmodule
