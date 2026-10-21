"""Embed the exact tested phone files in the Arduino sketch; writes only this package."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
parts=['#pragma once\n#include <Arduino.h>\n']
for name,file in [('PAGE','index.html'),('APP_JS','app.js'),('SCORE_JS','score.js'),('KEYMAP_PAGE','keymap.html'),('KEYMAP_JS','keymap.js'),('UI_CSS','ui.css'),('UI_TEXT_JS','ui-text.js'),('NAV_JS','navigation.js'),('DEVICE_API_JS','device-api.js')]:
    text=(r/'shouji'/file).read_text(encoding='utf-8')
    assert ')MUSICWEB"' not in text
    parts.append(f'const char {name}[] PROGMEM=R"MUSICWEB({text})MUSICWEB";\n')
(r/'esp32/ESP32_FPGA_Music_Controller/web_page.h').write_text(''.join(parts),encoding='utf-8')
