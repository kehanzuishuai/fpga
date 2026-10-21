from run import ROOT,OUT,run,IVER,VVP
s=(OUT/'tb_wav_dac.sv').read_text().replace('module tb_wav_dac;','module tb_native_replay;')
a=s.index(' initial begin\n  #100;');b=s.index('\n initial begin #2000000000',a)
s=s[:a]+r'''
 integer trace_fd,transfer_length,scan,j,waited;reg [7:0] ignored;
 initial begin
  #100;rst_n=1;#5000;
  $readmemh("tests/remote_music_20261019/out/stereo24_dac_expected.mem",expected);
  expected_frames=256;file_bytes=1622;
  trace_fd=$fopen("tests/remote_music_20261019/out/actual_esp_spi.txt","r");
  if(!trace_fd)$fatal(1,"actual ESP transfer trace missing");
  while(!$feof(trace_fd))begin
   scan=$fscanf(trace_fd,"%d",transfer_length);
   if(scan==1)begin
    if(transfer_length<10 || transfer_length>1034)$fatal(1,"trace length");
    for(j=0;j<transfer_length;j=j+1)begin scan=$fscanf(trace_fd,"%h",packet[j]);if(scan!=1)$fatal(1,"trace bytes");end
    cs=0;#1013;for(j=0;j<transfer_length;j=j+1)spi_byte(packet[j],ignored);
    #507;cs=1;#1019;
   end
  end
  $fclose(trace_fd);waited=0;
  while(status!=3 && error==0)begin #100000;waited=waited+1;if(waited>10000)$fatal(1,"replay timeout");end
  #60000;
  if(error!=0 || transport_error!=0 || matched!=256 || pcm_check.errors!=0 || pt_words<512)$fatal(1,"actual firmware/RTL/DAC mismatch");
  $display("PASS actual firmware C++ SPI-byte replay -> production RIFF/PCM/CDC -> dual DAC: %0d exact stereo WAV frames, %0d PCM5102 frames, %0d PT8211 words; retry caused no duplicated PCM",matched,pcm_check.u_rx.frames,pt_words);
  $finish;
 end
'''+s[b:]
(OUT/'tb_native_replay.sv').write_text(s)
files=['src/remote/wav_spi_stream.sv','src/remote/wav_pcm_player.sv','src/remote/wav_remote.sv','src/remote/stereo_master.sv','src/i2s_tx.v','src/pcm5102_i2s_tx.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v']
run('native_replay_compile',[IVER,'-g2012','-s','tb_native_replay','-o',OUT/'native_replay.vvp',OUT/'tb_native_replay.sv',*files])
run('native_replay',[VVP,OUT/'native_replay.vvp'])
