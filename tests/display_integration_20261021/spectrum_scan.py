"""Only frozen-FFT copy/scan statistics; renderer pixels are verified separately."""
from pathlib import Path
import subprocess,hashlib,json,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
A=R/'audit/display_integration_20261021/optimization'
reference=(A/'visual_renderer.before_font_rom.sv').read_text().replace('module visual_renderer','module visual_renderer_reference')
for name in ['visual_scene','visual_labels','visual_background','visual_light_motion']:reference=reference.replace(name,name+'_reference')
(O/'scan_renderer_reference.sv').write_text(reference)
def header(s,name):
 a=s.index('module '+name);return s[a:s.index(';',a)+1]
stubs=[]
for name in ['visual_scene','visual_labels','visual_background']:
 actual=(R/f'src/display/{name}.sv').read_text()
 original=(A/(name+'.original.sv')).read_text()
 stubs+=[header(actual,name)+'\nendmodule\n',header(original,name).replace(name,name+'_reference')+'\nendmodule\n']
 for source,suffix in [(actual,''),(original,'_reference')]:
  if 'module visual_light_motion' in source:stubs.append(header(source,'visual_light_motion').replace('visual_light_motion','visual_light_motion'+suffix)+'\nendmodule\n')
stubs.append(header((R/'src/display/visual_xy_plot.sv').read_text(),'visual_xy_plot')+'\nendmodule\n')
(O/'scan_pixel_stubs.sv').write_text('\n'.join(stubs))
tb='''`timescale 1ns/1ps
module tb_spectrum_scan;
 reg clk=0,rst=0,blank=0,pending=0;always #5 clk=~clk;
 reg [36:0] memory[0:1023];reg [36:0] data_a=0,data_b=0;
 wire [9:0] addr_a,addr_b;wire release_a,release_b;
 visual_renderer dut(.clk(clk),.rst_n(rst),.x(12'd0),.y(12'd0),.de(1'b0),.hs(1'b0),.vs(1'b0),.blank_start(blank),
 .wave_pending(1'b0),.spec_pending(pending),.wave_data(49'd0),.spec_data(data_a),.spec_addr(addr_a),.spec_release(release_a),.status_live(1'b0),.status_data(512'd0));
 visual_renderer_reference gold(.clk(clk),.rst_n(rst),.x(12'd0),.y(12'd0),.de(1'b0),.hs(1'b0),.vs(1'b0),.blank_start(blank),
 .wave_pending(1'b0),.spec_pending(pending),.wave_data(49'd0),.spec_data(data_b),.spec_addr(addr_b),.spec_release(release_b),.status_live(1'b0),.status_data(512'd0));
 always @(posedge clk)begin data_a<=memory[addr_a];data_b<=memory[addr_b];end
 integer frame,i,n;
 initial begin
  #1;rst=1;#1;rst=0;#20;rst=1;
  for(frame=0;frame<12;frame=frame+1)begin
   for(i=0;i<1024;i=i+1)memory[i]=0;
   case(frame)
    0:begin end
    1:begin memory[1023]=37'd1073741824;memory[900]=37'd262143;memory[901]=37'd262144;end
    2,3,4,5,6:begin memory[64]=37'd16777216;memory[257]=37'd4095;memory[254]=37'd4096;end
    7:begin memory[800]=37'd68719476736;memory[5]=37'd16777216;end
    8:begin memory[0]=37'd137438953471;memory[1023]=37'd1;end
    default:begin
     for(i=0;i<1024;i=i+1)memory[i]=(37'd1<<(i%37)) | (37'(i*17)&((37'd1<<(i%37))-37'd1));
    end
   endcase
   @(negedge clk);pending=1;blank=1;@(negedge clk);blank=0;n=0;
   while(!release_a && n<6000)begin
    @(negedge clk);n=n+1;
    if(addr_a!==addr_b || release_a!==release_b)$fatal(1,"scan handshake changed");
   end
   if(!release_a || !release_b)$fatal(1,"scan timeout");
   if({dut.peak_power,dut.peak_bin,dut.peak_hz,dut.peak_valid,dut.spectrum_range,dut.shrink_count}!==
      {gold.peak_power,gold.peak_bin,gold.peak_hz,gold.peak_valid,gold.spectrum_range,gold.shrink_count})$fatal(1,"scan metadata differs frame%0d",frame);
   for(i=0;i<512;i=i+1)if(dut.spectrum[i]!==gold.spectrum[i])$fatal(1,"pooled spectrum differs");
   if(frame==1 && dut.spectrum_range!=3)$fatal(1,"last-bin growth");
   if(frame==6 && dut.spectrum_range!=0)$fatal(1,"four-frame shrink");
   if(frame==7 && dut.spectrum_range!=3)$fatal(1,"37-bit power threshold");
   pending=0;repeat(4)@(negedge clk);
  end
  $display("PASS12 frozen FFT scans: final-bin peak, threshold +/-1, silence, DC rejection, 37-bit power, grow/shrink hysteresis; all6144 pooled bars exact");$finish;
 end
 initial begin #1000000;$fatal(1,"scanner timeout");end
endmodule
'''
(O/'tb_spectrum_scan.sv').write_text(tb)
files=[R/'src/display/visual_renderer.sv',O/'scan_renderer_reference.sv',O/'scan_pixel_stubs.sv',O/'tb_spectrum_scan.sv']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before={p.relative_to(R).as_posix():sha(p) for p in files}
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('spectrum_scan_compile',[iv,'-g2012','-s','tb_spectrum_scan','-o',O/'spectrum_scan.vvp',*files]),('spectrum_scan',[iv.with_name('vvp.exe'),O/'spectrum_scan.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-3000:])
 print(p.stdout.strip(),flush=True)
assert before=={p.relative_to(R).as_posix():sha(p) for p in files},'Inputs changed'
(O/'SPECTRUM_SCAN_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','frames':12,'pooled_bars':6144,'files':before,'scope':'Production renderer copy/scan state machine; frozen FFT synthetic fixture, archived original oracle; pixel-only modules stubbed, no FFT algorithm or pixel verification claim'},indent=2))
