"""Evaluate a short 32-cycle chunk divider without changing the frozen production build."""
from pathlib import Path
from run import ROOT,OUT,run,IVER,VVP
O=ROOT/'tests/remote_music_20261019/resource/wav_variant';O.mkdir(parents=True,exist_ok=True)
s=(ROOT/'src/remote/wav_pcm_player.sv').read_text()
s=s.replace('DONE=7,FAIL=8;','DONE=7,FAIL=8,COUNT=9;')
s=s.replace('reg [3:0] state;reg [5:0] pos;','reg [3:0] state;reg [5:0] pos;\n reg [31:0] quotient;reg [2:0] remainder3;reg [5:0] divide_count;\n wire [3:0] shifted_remainder={remainder3,quotient[31]};\n wire divide_bit=shifted_remainder>={1\'b0,block_align[2:0]};\n wire [3:0] next_remainder=divide_bit?shifted_remainder-{1\'b0,block_align[2:0]}:shifted_remainder;\n wire [31:0] next_quotient={quotient[30:0],divide_bit};')
s=s.replace('assign byte_ready=state!=IDLE','assign byte_ready=state!=COUNT && state!=IDLE')
a=s.index(' function automatic [31:0] frame_count');b=s.index(' wire [31:0] expected_byte_rate',a)
s=s[:a]+s[b:]
s=s.replace('state<=IDLE;pos<=0;offset<=0;','quotient<=0;remainder3<=0;divide_count<=0;state<=IDLE;pos<=0;offset<=0;')
s=s.replace('state<=start?RIFF:IDLE;pos<=0;','quotient<=0;remainder3<=0;divide_count<=0;state<=start?RIFF:IDLE;pos<=0;')
s=s.replace('  if(take)begin','''  if(state==COUNT)begin
   quotient<=next_quotient;remainder3<=next_remainder[2:0];divide_count<=divide_count-1'b1;
   if(divide_count==1)begin
    if(next_remainder!=0)fail(4);
    else begin data_seen<=1;data_frames<=next_quotient;state<=DATA;frame_byte<=0;frame_build<=0;end
   end
  end
  if(take)begin''')
s=s.replace(' || restored_size!=chunk_size_next','')
s=s.replace('data_seen<=1;data_frames<=computed_frames;state<=DATA;','quotient<=chunk_size_next;remainder3<=0;divide_count<=32;state<=COUNT;')
assert 'frame_count' not in s and 'computed_frames' not in s and 'COUNT=9' in s
(O/'wav_pcm_player.sv').write_text(s)
tb=(ROOT/'tests/remote_music_20261019/tb_wav.sv').read_text().replace('module tb_wav;','module tb_wav_variant;')
(OUT/'tb_wav_variant.sv').write_text(tb)
run('wav_variant_compile',[IVER,'-g2012','-s','tb_wav_variant','-o',OUT/'wav_variant.vvp',OUT/'tb_wav_variant.sv','src/remote/wav_spi_stream.sv',O/'wav_pcm_player.sv'])
run('wav_variant',[VVP,OUT/'wav_variant.vvp'])
