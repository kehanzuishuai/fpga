"""Display-only1023tap Hilbert, four MAC lanes within each256clock sample."""
from pathlib import Path
import math,json,hashlib,shutil
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;A=R/'audit/lissajous_video_20261018';A.mkdir(exist_ok=True)
p=R/'src/display/visual_xy_source.sv'
assert not (A/'visual_xy_source_before.sv').exists(),'Do not overwrite before evidence'
shutil.copy2(p,A/'visual_xy_source_before.sv')
co=[round(32768*2/(math.pi*(2*k-511))*(.54-.46*math.cos(2*math.pi*(2*k)/1022))) for k in range(512)]
assert all(co[k]==-co[511-k] for k in range(512))
(O/'hilbert_coefficients_1023.json').write_text(json.dumps(co))
code='''`default_nettype none
// Display-only1023-tap windowed Hilbert FIR, four parallel128-term MACs.
// The63-tap version attenuated C4 quadrature by8.98dB. This length covers
// the full MIDI48..91 range. Real X is delayed511 samples to match Y.
// 130 clocks per sample fits the256-clock48kHz input interval. Audio is
// never stalled or modified; only the display consumes these paired values.
module visual_xy_source(
 input wire clk,rst_n,pcm_valid,input wire signed [23:0] pcm,
 input wire xy_enable,input wire signed [23:0] xy_x,xy_y,
 output reg valid,output reg signed [15:0] wave_sample,x_sample,y_sample,
 output reg direct_mode,output reg [31:0] overruns
);
 reg signed [15:0] history[0:1023];reg [9:0] wp,base;
 reg [10:0] fill;reg busy;reg [7:0] index;
 reg signed [15:0] x_delayed,held_pcm,held_x,held_y;reg held_mode;
 wire accept=pcm_valid && !busy;
 wire [9:0] tap_base=base-{index[6:0],3'b000};
 wire [9:0] addr0=accept?(wp-10'd511):tap_base;
 wire [9:0] addr1=tap_base-10'd2,addr2=tap_base-10'd4,addr3=tap_base-10'd6;
 reg signed [15:0] q0,q1,q2,q3,c0,c1,c2,c3;
 reg signed [39:0] sum0,sum1,sum2,sum3;
 wire signed [31:0] p0=q0*c0,p1=q1*c1,p2=q2*c2,p3=q3*c3;
 wire signed [39:0] t0=sum0+{{8{p0[31]}},p0},t1=sum1+{{8{p1[31]}},p1};
 wire signed [39:0] t2=sum2+{{8{p2[31]}},p2},t3=sum3+{{8{p3[31]}},p3};
 wire signed [41:0] pair01={{2{t0[39]}},t0}+{{2{t1[39]}},t1};
 wire signed [41:0] pair23={{2{t2[39]}},t2}+{{2{t3[39]}},t3};
 wire signed [41:0] total=pair01+pair23;
 function automatic signed [15:0] coefficient(input [8:0] tap);
  begin case(tap)
'''
code+=''.join(f"   9'd{k}:coefficient={'-' if c<0 else ''}16'sd{abs(c)};\n" for k,c in enumerate(co))
code+='''   default:coefficient=0;
  endcase end
 endfunction
 function automatic signed [15:0] saturate(input signed [41:0] value);
  reg signed [41:0] q;
  begin q=value>>>15;
   if(q>32767)saturate=32767;else if(q< -32768)saturate=-32768;else saturate=q[15:0];
  end
 endfunction
 always @(posedge clk)begin
  if(accept)history[wp]<=pcm[23:8];
  q0<=history[addr0];q1<=history[addr1];q2<=history[addr2];q3<=history[addr3];
  c0<=coefficient({index[6:0],2'b00});c1<=coefficient({index[6:0],2'b01});
  c2<=coefficient({index[6:0],2'b10});c3<=coefficient({index[6:0],2'b11});
 end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  wp<=0;base<=0;fill<=0;busy<=0;index<=0;
  sum0<=0;sum1<=0;sum2<=0;sum3<=0;x_delayed<=0;
  held_pcm<=0;held_x<=0;held_y<=0;held_mode<=0;
  valid<=0;wave_sample<=0;x_sample<=0;y_sample<=0;direct_mode<=0;overruns<=0;
 end else begin
  valid<=0;
  if(pcm_valid && busy)overruns<=overruns+1'b1;
  if(accept)begin
   base<=wp;wp<=wp+1'b1;if(fill<1024)fill<=fill+1'b1;
   held_pcm<=pcm[23:8];held_x<=xy_x[23:8];held_y<=xy_y[23:8];held_mode<=xy_enable;
   busy<=1;index<=0;sum0<=0;sum1<=0;sum2<=0;sum3<=0;
  end else if(busy)begin
   index<=index+1'b1;
   if(index==0)x_delayed<=q0;
   else begin sum0<=t0;sum1<=t1;sum2<=t2;sum3<=t3;end
   if(index==128)begin
    busy<=0;wave_sample<=held_pcm;direct_mode<=held_mode;
    x_sample<=held_mode?held_x:x_delayed;
    y_sample<=held_mode?held_y:saturate(total);
    valid<=fill==1024;
   end
  end
 end
 wire [23:0] unused_low={pcm[7:0],xy_x[7:0],xy_y[7:0]};
endmodule
`default_nettype wire
'''
p.write_text(code,encoding='utf8')
(A/'GENERATION.json').write_text(json.dumps({'taps':1023,'nonzero_coefficients':512,'lanes':4,'group_delay_samples':511,'sample_interval_clocks':256,'processing_cycles_max':130,'source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'audio_algorithm_changed':False},indent=2))
print('Generated1023-tap/four-MAC display Hilbert; unchanged external interface.')
