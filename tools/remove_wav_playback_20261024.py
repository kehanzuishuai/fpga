"""Remove WAV playback from the contest build (user decision, 2026-10-24).

Topic 2 rules: "严禁直接播放预录 PCM 音频、预置推流及整段录音触发" and the
on-site check "验证无预录音频播放行为". The phone -> ESP32 -> SPI -> FPGA WAV
decoder/player is exactly prerecorded PCM streaming, so it leaves the build:
- top level: no wav_remote instance; wav_left/wav_right are 0 (the value they
  always had while no WAV was playing), esp_spi_miso is driven low; the SPI
  pins stay as ports so the proven CST is untouched;
- GPRJ: the three WAV sources are disabled; the files stay on disk.
The synthesised audio path is unchanged. Idempotent.
"""
from pathlib import Path
import sys

TOP_OLD = '''wav_remote u_wav(clk_50m_global,clk_12m288,synth_rst_n,remote_tick,
 esp_spi_sck,esp_spi_cs_n,esp_spi_mosi,esp_spi_miso,wav_left,wav_right);
'''
TOP_NEW = '''// WAV playback removed from the contest build: the topic rules forbid playing
// prerecorded or streamed PCM. The SPI pins stay; no PCM enters the mix.
assign wav_left=24'sd0;assign wav_right=24'sd0;assign esp_spi_miso=1'b0;
// One preserved sampling register keeps the SPI inputs connected (proven CST,
// built with cst_warn_to_error); it drives nothing.
(* syn_preserve=1 *) reg unused_wav_spi;
always @(posedge clk_50m_global)unused_wav_spi<=^{esp_spi_sck,esp_spi_cs_n,esp_spi_mosi};
'''
GPRJ_FILES = ['src/remote/wav_pcm_player.sv', 'src/remote/wav_remote.sv', 'src/remote/wav_spi_stream.sv']


def top(s):
    if 'WAV playback removed from the contest build' in s:
        return s
    assert s.count(TOP_OLD) == 1
    return s.replace(TOP_OLD, TOP_NEW)


def gprj(s):
    for f in GPRJ_FILES:
        on = f'<File path="{f}" type="file.verilog" enable="1"/>'
        off = f'<File path="{f}" type="file.verilog" enable="0"/>'
        if off in s:
            continue
        assert s.count(on) == 1, f
        s = s.replace(on, off)
    return s


def rewrite(path, fn):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    s = raw.decode('utf-8').replace('\r\n', '\n')
    t = fn(s)
    if t != s:
        path.write_bytes((t.replace('\n', '\r\n') if crlf else t).encode('utf-8'))
        print('updated', path)
    else:
        print('unchanged', path)


if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    rewrite(root / 'src/tang_mega_138k_pro_top.v.v', top)
    rewrite(root / 'yinyue_fashengqi.gprj', gprj)
