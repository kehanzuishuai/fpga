`timescale 1ns/1ps
module tb_golden_vectors;
  logic clk=0,rst_n=0,tick=1,phase_reset=0,gate_on=0,gate_off=0;
  logic [31:0] phase; logic [7:0] level; logic active; logic [1:0] stage;
  logic signed [23:0] sine,square,saw,triangle,morph_sample;
  logic [9:0] morph;
  logic signed [23:0] m0,m1,m2,m3,mixed_sat;
  logic signed [95:0] packed_samples;
  logic signed [25:0] mixed;
  integer fd,k;
  always #5 clk=~clk;
  always @* packed_samples={m3,m2,m1,m0};
  dds_phase_accum dds(.clk,.rst_n,.sample_tick(tick),.phase_reset,.phase_inc(32'h1234_5678),.phase);
  adsr_env #(.ENV_W(8),.ATTACK_STEP(8'd40),.DECAY_STEP(8'd10),.SUSTAIN(8'd120),.RELEASE_STEP(8'd30)) adsr(
    .clk,.rst_n,.sample_tick(tick),.gate_on,.gate_off,.level,.active,.stage);
  timbre_morph morph_dut(.sine,.square,.saw,.triangle,.morph,.sample(morph_sample));
  tree_mixer #(.VOICES(4),.SAMPLE_W(24)) mixer(.samples(packed_samples),.mixed);
  saturator #(.IN_W(26),.OUT_W(24)) sat(.in(mixed),.out(mixed_sat));
  initial begin
    fd=$fopen("sim_out/golden_vectors.csv","w");
    if(fd==0)$fatal(1,"cannot create golden vector capture");
    $fwrite(fd,"k,phase_reset,gate_on,gate_off,phase,level,active,stage,sine,square,saw,triangle,morph,morph_sample,m0,m1,m2,m3,mixed,mixed_sat\n");
    repeat(3)@(posedge clk);@(negedge clk);rst_n=1;
    for(k=0;k<48;k=k+1) begin
      phase_reset=(k==0);gate_on=(k==0)||(k==24);gate_off=(k==13)||(k==41);
      sine=-24'sd4000000+k*24'sd12345; square=24'sd7000000-k*24'sd10000;
      saw=-24'sd2000000+k*24'sd54321; triangle=24'sd3000000-k*24'sd22222;
      morph=(k*10'd79)%1024;
      m0=-24'sd8000000+k*24'sd333333; m1=24'sd7000000-k*24'sd111111;
      m2=(k[0])?24'sd5000000:-24'sd5000000; m3=24'sd2000000-k*24'sd77777;
      @(posedge clk);#1;
      $fwrite(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
        k,phase_reset,gate_on,gate_off,phase,level,active,stage,sine,square,saw,triangle,morph,morph_sample,m0,m1,m2,m3,mixed,mixed_sat);
      @(negedge clk);
    end
    $fclose(fd);
    $display("TB_GOLDEN_VECTORS PASS: captured 48 DDS/ADSR/Morph/Mixer RTL samples");
    $finish;
  end
endmodule
