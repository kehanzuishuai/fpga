`timescale 1ns/1ps
module tb_mix_gain #(parameter N=32,W=24,MASTER=29491,ATTEN=0);
 localparam L=$clog2(N),MW=W+L;
 reg clk=0,rst_n=0,tick=0;always #5 clk=~clk;
 reg [N*W-1:0] samples=0;reg [L:0] count=0;
 wire signed [MW-1:0] mixed,scaled;wire signed [W-1:0] audio;wire [5:0] shift;
 tree_mixer #(.VOICES(N),.SAMPLE_W(W),.LOG2_VOICES(L)) mix(samples,mixed);
 polyphony_gain #(.SAMPLE_W(W),.LOG2_VOICES(L),.MASTER_GAIN_Q15(16'(MASTER)),
 .MASTER_ATTEN_SHIFT(6'(ATTEN))) gain(clk,rst_n,tick,mixed,count,scaled,shift);
 saturator #(.IN_W(MW),.OUT_W(W)) sat(scaled,audio);
 longint signed sum_ref,expected,sample_ref;
 integer i,j,n,old_gain=MASTER,target,effective,next_gain,fp;
 reg [31:0] rng=32'h12345678;
 task check_output;
 begin
   target=(count==0)?MASTER:MASTER/integer'(count);
   effective=(old_gain<target)?old_gain:target;
   expected=(sum_ref*effective) >>> (15+ATTEN);
   #1;
   if($signed(mixed)!==sum_ref || $signed(scaled)!==expected || $signed(audio)!==expected)
     $fatal(1,"mix/gain mismatch N%0d W%0d case%0d count%0d sum%0d actual%0d expected%0d",N,W,i,count,sum_ref,scaled,expected);
   if(expected>(64'sd1<<(W-1))-1 || expected< -(64'sd1<<(W-1)))$fatal(1,"gain ceiling failure");
 end endtask
 initial begin
 fp=$fopen("sim_out_visual/gain_trace.txt","w");
 if(!fp)$fatal(1,"gain output open");
 #1;rst_n=1;#1;rst_n=0;repeat(3)@(negedge clk);rst_n=1;
 for(i=0;i<1200;i=i+1)begin
   @(negedge clk);tick=0;
   if(i%97==0)begin rst_n=0;old_gain=MASTER;#1;rst_n=1;end
   rng=(rng<<1)^((rng[31])?32'h04c11db7:32'd0);
   if(i<2*N+2)n=i%(N+1);else n=integer'(rng%(N+1));
   count=n[L:0];samples=0;sum_ref=0;
   for(j=0;j<n;j=j+1)begin
     if(i%4==0)sample_ref=(64'sd1<<(W-1))-1;
     else if(i%4==1)sample_ref= -(64'sd1<<(W-1));
     else if(i%4==2)sample_ref=(j%2)? -(64'sd1<<(W-1)):((64'sd1<<(W-1))-1);
     else begin rng=(rng<<1)^((rng[31])?32'h04c11db7:32'd0);sample_ref=$signed(rng[W-1:0]);end
     samples[j*W+:W]=sample_ref[W-1:0];sum_ref=sum_ref+sample_ref;
   end
   check_output(); // count changed between enables: stale gain must be safe now.
   tick=1;@(posedge clk);
   if(old_gain>target)next_gain=target;
   else if(target-old_gain<=64)next_gain=target;else next_gain=old_gain+64;
   old_gain=next_gain;check_output();
   $fwrite(fp,"%0d %0d %0d %0d %0d\n",i,count,sum_ref,old_gain,$signed(audio));
   @(negedge clk);tick=0;
 end
 $fclose(fp);$display("PASS mixer/gain N%0d W%0d master%0d attenuation%0d 1200 random/extreme/reset/pre-edge cases",N,W,MASTER,ATTEN);$finish;
 end
endmodule
