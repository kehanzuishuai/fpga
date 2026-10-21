from pathlib import Path
p=Path(__file__).resolve().parents[1]/'src/synth_top.v'
s=p.read_text(encoding='utf-8')
s=s.replace('wire signed [23:0] final_left,final_right;','''wire signed [23:0] final_left,final_right;
wire master_clipped,engine_clipped;
wire [23:0] engine_peak;wire engine_pcm_strobe;wire signed [23:0] engine_pcm;
assign dbg_clip=engine_clipped || (REMOTE_ENABLE!=0 && master_clipped);
''')
s=s.replace('final_left,final_right,visual_pcm);','''final_left,final_right,visual_pcm,master_clipped);
 wire [23:0] abs_left=final_left[23]?-final_left:final_left;
 wire [23:0] abs_right=final_right[23]?-final_right:final_right;
 wire signed [23:0] meter_pcm=abs_left>=abs_right?final_left:final_right;
 wire [COUNT_W-1:0] unused_count;
 audio_telemetry #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W),.COUNT_W(COUNT_W)) meter(
 .clk(clk),.rst_n(rst_n),.sample_tick(sample_tick),.active_voices(active_debug),
 .audio(meter_pcm),.active_voice_count(unused_count),.audio_peak(audio_peak),
 .pcm_strobe(pcm_strobe),.pcm_sample(pcm_sample));''')
s=s.replace('assign final_left=audio_out;assign final_right=audio_out;assign visual_pcm=audio_out;', '''assign final_left=audio_out;assign final_right=audio_out;assign visual_pcm=audio_out;
 assign master_clipped=0;assign audio_peak=engine_peak;assign pcm_strobe=engine_pcm_strobe;assign pcm_sample=engine_pcm;''')
a=s.index(') u_synth (');b=s.index('\n);',a)
part=s[a:b].replace('.audio_peak          (audio_peak)','.audio_peak          (engine_peak)')
part=part.replace('.pcm_strobe          (pcm_strobe)','.pcm_strobe          (engine_pcm_strobe)')
part=part.replace('.pcm_sample          (pcm_sample)','.pcm_sample          (engine_pcm)')
part=part.replace('.dbg_clip            (dbg_clip)','.dbg_clip            (engine_clipped)')
s=s[:a]+part+s[b:];p.write_text(s,encoding='utf-8')
print('Final stereo peak and telemetry now meter the actual DAC signal.')
