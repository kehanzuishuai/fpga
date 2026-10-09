`timescale 1ns/1ps
module tb_waveform_quality;
 reg [31:0] phase=0;
 wire signed [23:0] sine,square,saw,triangle;
 waveform_set wave(phase,sine,square,saw,triangle);
 voice v(.clk(1'b0),.rst_n(1'b0),.sample_tick(1'b0),.start(1'b0),.stop(1'b0),
 .phase_inc_in(32'd0),.note_in(7'd0),.velocity_in(8'd0),.waveform_in(2'd0),
 .morph_enable(1'b0),.morph_in(10'd0));
 integer fp,sp,i,j,k;reg [31:0] rng=32'habcde123;
 reg signed [23:0] raw;reg [23:0] env;reg [7:0] velocity;
 reg signed [23:0] result;
 initial begin
 fp=$fopen("sim_out_visual/waveform_quality.txt","w");
 sp=$fopen("sim_out_visual/voice_scaling.txt","w");
 if(!fp || !sp)$fatal(1,"waveform output open");
 for(i=0;i<4352;i=i+1)begin
   rng=(rng<<1)^(rng[31]?32'h04c11db7:32'd0);
   phase=(i<4096)?(32'(i)<<20):rng;#1;
   $fwrite(fp,"%0d %0d %0d %0d %0d\n",phase,sine,square,saw,triangle);
 end
 for(i=0;i<6;i=i+1)for(j=0;j<6;j=j+1)for(k=0;k<256;k=k+1)begin
   rng=(rng<<1)^(rng[31]?32'h04c11db7:32'd0);
   case(i)0:raw=0;1:raw=1;2:raw=-1;3:raw=24'sh7fffff;4:raw=24'sh800000;default:raw=24'(rng);endcase
   case(j)0:env=0;1:env=1;2:env=24'h7fffff;3:env=24'h800000;4:env=24'hffffff;default:env=24'(rng^32'h13579bdf);endcase
   velocity=8'(k);result=v.scale_audio(raw,env,velocity);
   $fwrite(sp,"%0d %0d %0d %0d\n",raw,env,velocity,result);
 end
 $fclose(fp);$fclose(sp);
 $display("PASS waveform and9216 voice scaling boundary vectors exported");$finish;
 end
endmodule
