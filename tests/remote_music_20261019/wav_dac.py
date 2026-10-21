from run import ROOT,OUT,run,IVER,VVP
s=(ROOT/'tests/remote_music_20261019/tb_wav.sv').read_text().replace('module tb_wav;','module tb_wav_dac;')
a=s.index(' wire start,stop,finish,valid,ready;');b=s.index(' reg [7:0] source',a)
s=s[:a]+r'''
 reg audio_clk=0;always #40.690104 audio_clk=~audio_clk;
 wire frame_tick,capture,bc,lr,da,pbc,plr,pda;
 wire signed [23:0] wl,wr,l,r,mono;wire clipping;
 reg [15:0] volume=65535,gain=65535;
 wav_remote remote(clk,audio_clk,rst_n,frame_tick,sck,cs,mosi,miso,wl,wr);
 wire [7:0] status=remote.state,error=remote.error,transport_error=remote.transport_error;
 wire [14:0] buffered=remote.buffered;
 stereo_master master(audio_clk,rst_n,volume,gain,24'sd0,wl,wr,l,r,mono,clipping);
 i2s_tx #(.SLOT_W(32)) pt(audio_clk,rst_n,l,r,bc,lr,da,capture,frame_tick);
 pcm5102_i2s_tx #(.CAPTURE_DELAY(7)) pcm(audio_clk,rst_n,frame_tick,l,r,pbc,plr,pda);
 pcm5102_frame_check pcm_check(audio_clk,rst_n,frame_tick,l,r,pbc,plr,pda);
 reg pt_started=0,pt_channel;reg [15:0] pt_left,pt_right,pt_shift;
 integer pt_bits=0,pt_words=0;
 always @(posedge lr)if(rst_n)begin
  pt_started=1;pt_channel=1;pt_bits=0;pt_left=l[23:8];pt_right=r[23:8];
 end
 always @(posedge bc)if(rst_n && pt_started)begin
  if(lr!=pt_channel)begin
   if(pt_bits!=16)$fatal(1,"PT8211 word length %d",pt_bits);
   pt_channel=lr;pt_bits=0;
  end
  pt_shift={pt_shift[14:0],da};pt_bits=pt_bits+1;
  if(pt_bits==16)begin
   pt_words=pt_words+1;
   if(pt_shift!==(lr?pt_left:pt_right))$fatal(1,"PT8211 stereo %h expected %h",pt_shift,lr?pt_left:pt_right);
  end
 end
''' +s[b:]
a=s.index(' always @(posedge clk)if(frame_tick');b=s.index(' task automatic fixture_test',a)
s=s[:a]+r'''
 bit started_pcm=0;
 always @(posedge audio_clk)if(capture)begin
  if(l!=0 || r!=0 || (started_pcm && matched<expected_frames))begin
   started_pcm=1;
   if(matched>=expected_frames)$fatal(1,"duplicated WAV frame after EOF");
   if({r,l}!==expected[matched])$fatal(1,"CDC/DAC capture frame%0d got %h/%h expected%h",matched,l,r,expected[matched]);
   matched=matched+1;
  end
 end
''' +s[b:]
s=s.replace('stream.received','remote.stream.received')
s=s.replace('if(error!=0 || matched!=expected_frames)', '#60000;\n   if(error!=0 || matched!=expected_frames)')
a=s.index('  fixture_test("stereo24_48000",0);');b=s.index('  $display("PASS WAV integration")',a)
s=s[:a]+'''  fixture_test("stereo24_dac",0);
  if(pcm_check.u_rx.frames<256 || pcm_check.errors!=0 || pt_words<512)$fatal(1,"dual DAC coverage");
  $display("PASS stereo WAV through real async mailbox and actual dual DAC transmitters: %0d exact WAV captures, %0d PCM5102 frames, %0d PT8211 words",matched,pcm_check.u_rx.frames,pt_words);
'''+s[b:]
(OUT/'tb_wav_dac.sv').write_text(s)
files=['src/remote/wav_spi_stream.sv','src/remote/wav_pcm_player.sv','src/remote/wav_remote.sv','src/remote/stereo_master.sv','src/i2s_tx.v','src/pcm5102_i2s_tx.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v']
run('wav_dac_compile',[IVER,'-g2012','-s','tb_wav_dac','-o',OUT/'wav_dac.vvp',OUT/'tb_wav_dac.sv',*files])
run('wav_dac',[VVP,OUT/'wav_dac.vvp'])
