"""Exercise the actual firmware HTTP service using sized RAW callbacks."""
from run import ROOT,OUT,run
compiler='C:/Xilinx/Model_Composer/2020.2/tps/mingw/6.2.0/win64.o/nt/bin/g++.exe'
sdk=ROOT/'tools/toolchains/arduino/data/packages/esp32/hardware/esp32/3.3.10-cn/libraries/WebServer/src'
parser=(sdk/'Parsing.cpp').read_text();handlers=(sdk/'detail/RequestHandlersImpl.h').read_text()
assert 'arg.value = String(plainBuf);' in parser
assert '_currentHandler->raw(*this, _currentUri, *_currentRaw);' in parser
assert '_ufn();' in handlers and 'bool canRaw' in handlers
run('native_http_compile',[compiler,'-std=c++11','-O2','-static','-Itests/remote_music_20261019/native_http','tests/remote_music_20261019/native_http/test.cpp','-o',OUT/'native_http.exe'])
run('native_http',[OUT/'native_http.exe'])
