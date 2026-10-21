"""Archive the failed implementation, then split two proven long paths."""
from pathlib import Path
import json, shutil
R=Path(__file__).resolve().parents[2]
A=R/'audit/remote_music_20261019/routed_setup_negative_0554'
A.mkdir(exist_ok=False)
b=json.loads((R/'audit/remote_music_20261019/BUILD.json').read_text())
shutil.copy2(R/'audit/remote_music_20261019/BUILD.json',A/'BUILD.json')
for q in b['outputs']:shutil.copy2(R/q,A/Path(q).name)
shutil.copy2(R/'tests/remote_music_20261019/out/gowin.log',A/'gowin.log')
for q in ['src/display/visual_xy_plot.sv','src/remote/wav_spi_stream.sv']:
 p=R/q;shutil.copy2(p,A/p.name)
p=R/'src/display/visual_xy_plot.sv';s=p.read_text()
s=s.replace('PEAK_UPDATE=12;', 'PEAK_UPDATE=12,PEAK_MAX=13;')
s=s.replace('reg [16:0] ax,ay;', 'reg [16:0] ax,ay,candidate_r;')
s=s.replace('wire [16:0] next_peak=candidate>peak?candidate:peak;', 'wire [16:0] next_peak=candidate_r>peak?candidate_r:peak;')
s=s.replace('ax<=0;ay<=0;', 'ax<=0;ay<=0;candidate_r<=0;')
s=s.replace('state<=PEAK_UPDATE;\n   end\n   PEAK_UPDATE:', 'state<=PEAK_MAX;\n   end\n   // Separate max(X,Y) from max(candidate,peak) to avoid serial comparators.\n   PEAK_MAX:begin candidate_r<=candidate;state<=PEAK_UPDATE;end\n   PEAK_UPDATE:')
assert 'PEAK_MAX:begin' in s;p.write_text(s)
p=R/'src/remote/wav_spi_stream.sv';s=p.read_text()
s=s.replace('reg [175:0] status_body_r;', '''reg [175:0] status_body_r,status_body_crc_r;
 reg [15:0] status_crc_half_r;
 function automatic [15:0] status_crc_first(input [175:0] body);
  reg [15:0] c;integer k;
  begin
   c=16'hffff;for(k=0;k<11;k=k+1)c=crc_byte(c,body[k*8+:8]);
   status_crc_first=c;
  end
 endfunction''')
s=s.replace('status_packet(input [175:0] body);','status_packet(input [175:0] body,input [15:0] first_crc);')
s=s.replace("c=16'hffff;for(k=0;k<22;k=k+1)c=crc_byte(c,body[k*8+:8]);",'c=first_crc;for(k=11;k<22;k=k+1)c=crc_byte(c,body[k*8+:8]);')
s=s.replace('// One 50MHz cycle separates FIFO arithmetic from the status CRC tree.', '// Pipeline FIFO arithmetic and the two 11-byte CRC halves.\n // The body travels with its CRC; CS snapshots a coherent status 40ns old.')
s=s.replace('if(!rst_n)status_body_r<=0;else status_body_r<=status_body();', '''if(!rst_n)begin status_body_r<=0;status_body_crc_r<=0;status_crc_half_r<=16'hffff;end
  else begin
   status_body_r<=status_body();
   status_body_crc_r<=status_body_r;status_crc_half_r<=status_crc_first(status_body_r);
  end''')
s=s.replace('status_packet(status_body_r)', 'status_packet(status_body_crc_r,status_crc_half_r)')
assert 'for(k=11;k<22;' in s;p.write_text(s)
print('Archived failed timing and split only XY max and SPI status CRC paths; UI untouched.')
