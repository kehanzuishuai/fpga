from pathlib import Path
from run import ROOT,OUT,run,IVER,VVP
text=(ROOT/'tests/remote_music_20261019/tb_wav.sv').read_text().replace('module tb_wav;','module tb_wav_errors;')
text=text.replace('if(frame_tick && player.playing)','if(frame_tick && player.playing && 0)')
start=text.index(' initial begin\n  #100;');end=text.index('\n initial begin #2000000000',start)
text=text[:start]+r'''
 task automatic raw_start(input integer bytes);
 begin
  packet[8]=8'(bytes);packet[9]=8'(bytes>>8);packet[10]=8'(bytes>>16);packet[11]=8'(bytes>>24);
  send(1,4,0);seq=seq+1;
 end endtask
 task automatic raw_data(input integer offset,input integer n);
  integer j;begin for(j=0;j<n;j=j+1)packet[8+j]=source[8+offset+j];send(2,n,0);seq=seq+1;end
 endtask
 integer j,offset,waited;
 initial begin
  #100;rst_n=1;#5000;
  $readmemh("tests/remote_music_20261019/out/stereo16_48000.mem",source);
  file_bytes={source[3],source[2],source[1],source[0]};
  raw_start(file_bytes);
  seq=seq+3;packet[8]=0;send(2,1,0);seq=seq-3;
  if(transport_error!=4 || stream.received!=0)$fatal(1,"wrong sequence accepted");
  source[8+32]=3;raw_data(0,file_bytes);send(3,0,0);seq=seq+1;#5000;
  if(error!=5 || l!=0 || r!=0)$fatal(1,"compressed WAV was not rejected: %d",error);
  $display("PASS compressed WAV rejection and invalid SPI sequence");$fflush();
  raw_start(file_bytes);
  source[8+32]=1;source[8+68]=200;raw_data(0,file_bytes);send(3,0,0);seq=seq+1;#5000;
  if(error!=2 || l!=0 || r!=0)$fatal(1,"RIFF bounds were not enforced %d",error);
  $display("PASS malformed RIFF data length rejected");$fflush();
  raw_start(file_bytes);raw_data(0,50);send(3,0,0);
  if(transport_error!=5 || stream.received!=50)$fatal(1,"truncated upload END accepted");
  send(4,0,0);seq=seq+1;#5000;
  if(buffered!=0 || l!=0 || r!=0)$fatal(1,"abort left stale bytes/audio");
  $display("PASS truncated upload rejected and abort flushes bytes/PCM");$fflush();
  $readmemh("tests/remote_music_20261019/out/stereo24_48000.mem",source);
  file_bytes={source[3],source[2],source[1],source[0]};raw_start(file_bytes);
  for(offset=0;offset<9216;offset=offset+1024)begin
   poll();while(response[3][0] || {response[7],response[6]}<1024)poll();raw_data(offset,1024);
  end
  waited=0;while(error==0)begin #100000;waited=waited+1;if(waited>2000)$fatal(1,"underflow not detected");end
  if(error!=7 || played<1000 || l!=0 || r!=0)$fatal(1,"underrun behavior error%0d played%0d",error,played);
  $display("PASS starved stream reports underrun and silences both channels after %0d frames",played);$fflush();
  send(4,0,0);seq=seq+1;#10000;
  if(error!=0 || status!=0 || buffered!=0)$fatal(1,"restart/stop recovery");
  $display("PASS WAV error paths");$finish;
 end
'''+text[end:]
(OUT/'tb_wav_errors.sv').write_text(text)
run('wav_errors_compile',[IVER,'-g2012','-s','tb_wav_errors','-o',OUT/'wav_errors.vvp',OUT/'tb_wav_errors.sv','src/remote/wav_spi_stream.sv','src/remote/wav_pcm_player.sv'])
run('wav_errors',[VVP,OUT/'wav_errors.vvp'])
