"""Create editable integration copies, leaving the supplied package intact."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
for source, target in [
    ('ref/lanya_20261019/shouji', 'firmware/remote_music/shouji'),
    ('ref/lanya_20261019/esp32', 'firmware/remote_music/esp32'),
    ('ref/lanya_20261019/tongxin', 'src/remote/uart'),
    ('ref/lanya_20261019/kongzhi', 'src/remote/control'),
]:
    dst = root / target
    if dst.exists():
        raise SystemExit(f'Refusing to replace {dst}')
    shutil.copytree(root / source, dst)
shutil.copy2(root/'ref/lanya_20261019/wifi_core.sv', root/'src/remote/wifi_core.sv')
for path in (root/'tests/yinse').rglob('*.sv'):
    if 'sim' not in path.parts:
        dst = root/'src/instruments'/path.relative_to(root/'tests/yinse')
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, dst)
print('Created editable firmware, UART/control and instrument sources.')
