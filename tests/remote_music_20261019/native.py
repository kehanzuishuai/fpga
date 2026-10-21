from run import ROOT,OUT,run
compiler='C:/Xilinx/Model_Composer/2020.2/tps/mingw/6.2.0/win64.o/nt/bin/g++.exe'
run('native_wav_compile',[compiler,'-std=c++11','-O2','-static','tests/remote_music_20261019/native_wav.cpp','-o',OUT/'native_wav.exe'])
run('native_wav',[OUT/'native_wav.exe',OUT/'stereo24_dac.wav',OUT/'actual_esp_spi.txt'])
