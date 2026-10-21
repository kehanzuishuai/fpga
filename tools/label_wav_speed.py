from pathlib import Path
p=Path(__file__).resolve().parents[1]/'firmware/remote_music/shouji/index.html'
s=p.read_text(encoding='utf-8').replace('for="tempo">播放速度','for="tempo">MIDI/JSON速度')
s=s.replace('WAV保留录音原声，音色选择用于琴键和MIDI/JSON。','WAV按原速度播放并保留录音原声，音色选择用于琴键和MIDI/JSON。')
p.write_text(s,encoding='utf-8')
