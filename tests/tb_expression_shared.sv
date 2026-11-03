module tb_expression_shared;
reg clk=0;always #5 clk=~clk;reg rst_n=0,tick=0;reg [31:0] starts=0;reg [6:0] glide=1;reg [21:0] seed=32768;reg signed [7:0] lfo=0;wire [703:0] ratios;
expression_pitch_bank dut(clk,rst_n,tick,starts,glide,seed,lfo,ratios);
integer i,j;reg [21:0] prior[0:31];
task frame;begin @(negedge clk);tick=1;@(negedge clk);tick=0;repeat(254)@(negedge clk);end endtask
initial begin #12;rst_n=1;@(negedge clk);starts=32'hffffffff;@(negedge clk);starts=0;
 for(j=0;j<32;j=j+1)prior[j]=32768;
 for(i=0;i<2000;i=i+1)begin frame();for(j=0;j<32;j=j+1)begin
 if((^ratios[j*22+:22])===1'bx || ratios[j*22+:22]<prior[j] || ratios[j*22+:22]>65536)$fatal(1,"shared glide voice %d frame %d",j,i);
 prior[j]=ratios[j*22+:22];end end
 for(j=0;j<32;j=j+1)if(ratios[j*22+:22]!=65536)$fatal(1,"not converged");
 lfo=64;repeat(3)frame();for(j=0;j<32;j=j+1)if(ratios[j*22+:22]!=67584)$fatal(1,"vibrato voice %d",j);
 lfo=-64;repeat(3)frame();for(j=0;j<32;j=j+1)if(ratios[j*22+:22]!=63488)$fatal(1,"negative vibrato");
 lfo=0;glide=0;#1;for(j=0;j<32;j=j+1)if(ratios[j*22+:22]!==65536)$fatal(1,"bypass");
 $display("PASS shared32 monotonic glide, all voices converge, signed vibrato depth and exact zero bypass");$finish;end
endmodule
