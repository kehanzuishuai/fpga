"""Prepare and test a timing candidate outside production SRC/GPRJ."""
from run import ROOT,OUT,run,IVER,VVP
import re,sys
C=OUT/'wav_timing_candidate';C.mkdir(exist_ok=True)
s=(ROOT/'src/remote/wav_pcm_player.sv').read_text()
s=s.replace('COUNT=9;', 'COUNT=9,BOUND_SUM=10,BOUND_CHECK=11;\n reg [32:0] chunk_end;\n reg [31:0] last_source_index,pop_limit;')
s=s.replace('source_index+2<data_frames','source_index<pop_limit')
s=s.replace('source_index+1>=data_frames','source_index>=last_source_index')
s=s.replace('assign byte_ready=state!=COUNT', 'assign byte_ready=state!=BOUND_SUM && state!=BOUND_CHECK && state!=COUNT')
s=s.replace('quotient<=0;remainder3<=0;', 'chunk_end<=0;last_source_index<=0;pop_limit<=0;quotient<=0;remainder3<=0;')
s=s.replace('data_frames<=next_quotient;', "data_frames<=next_quotient;last_source_index<=next_quotient-1'b1;pop_limit<=(next_quotient>2)?next_quotient-2:0;")
start=s.index("      if({1'b0,offset}+33'd1+")
end=s.index('\n     end\n    end\n    FMT:',start)
logic=s[start:end]
logic=logic.replace("if({1'b0,offset}+33'd1+{1'b0,chunk_size_next}+33'(chunk_size_next[0])>{1'b0,file_size})", "if(chunk_end>{1'b0,file_size})").replace('chunk_size_next','chunk_size')
s=s[:start]+'      state<=BOUND_SUM;'+s[end:]
position=s.index('  if(state==COUNT)begin')
s=s[:position]+'''  if(state==BOUND_SUM)begin
   chunk_end<={1'b0,offset}+{1'b0,chunk_size}+33'(chunk_size[0]);state<=BOUND_CHECK;
  end
  if(state==BOUND_CHECK)begin
'''+logic+'''\n  end\n'''+s[position:]
s=s.replace('&& state!=IDLE && state!=FAIL)fail(6);','&& state!=IDLE && state!=FAIL && state!=BOUND_SUM && state!=BOUND_CHECK)fail(6);')
(C/'wav_pcm_player.sv').write_text(s)
s=(ROOT/'src/remote/wav_spi_stream.sv').read_text()
s=s.replace('function automatic [191:0] status_packet;', 'function automatic [175:0] status_body;')
s=s.replace("   c=16'hffff;for(k=0;k<22;k=k+1)c=crc_byte(c,p[k*8+:8]);\n   p[191:176]=c;status_packet=p;",'   status_body=p[175:0];')
where=s.index(' always @(posedge clk or negedge rst_n)')
s=s[:where]+''' reg [175:0] status_body_r;
 function automatic [191:0] status_packet(input [175:0] body);
  reg [15:0] c;integer k;
  begin
   c=16'hffff;for(k=0;k<22;k=k+1)c=crc_byte(c,body[k*8+:8]);
   status_packet={c,body};
  end
 endfunction
 // One 50MHz cycle separates FIFO arithmetic from the status CRC tree.
 always @(posedge clk or negedge rst_n)
  if(!rst_n)status_body_r<=0;else status_body_r<=status_body();
'''+s[where:]
s=s.replace('status_hold<=status_packet();','status_hold<=status_packet(status_body_r);')
(C/'wav_spi_stream.sv').write_text(s)
sources=[C/'wav_spi_stream.sv',C/'wav_pcm_player.sv']
if '--extra' in sys.argv:
 run('wav_candidate_errors_compile',[IVER,'-g2012','-s','tb_wav_errors','-o',C/'errors.vvp',OUT/'tb_wav_errors.sv',*sources])
 run('wav_candidate_errors',[VVP,C/'errors.vvp'])
 files=[*sources,*[ROOT/q for q in ['src/remote/wav_remote.sv','src/remote/stereo_master.sv','src/i2s_tx.v','src/pcm5102_i2s_tx.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v']]]
 run('wav_candidate_dac_compile',[IVER,'-g2012','-s','tb_wav_dac','-o',C/'dac.vvp',OUT/'tb_wav_dac.sv',*files])
 run('wav_candidate_dac',[VVP,C/'dac.vvp'])
 print('PASS candidate error handling and dual DAC; production unchanged')
 sys.exit(0)
run('wav_candidate_compile',[IVER,'-g2012','-s','tb_wav','-o',C/'candidate.vvp',ROOT/'tests/remote_music_20261019/tb_wav.sv',*sources])
run('wav_candidate',[VVP,C/'candidate.vvp'])
run('wav_candidate_formats_compile',[IVER,'-g2012','-s','tb_wav','-o',C/'formats.vvp',OUT/'tb_wav_formats.sv',*sources])
run('wav_candidate_formats',[VVP,C/'formats.vvp'])
print('PASS candidate only; production files unchanged')
