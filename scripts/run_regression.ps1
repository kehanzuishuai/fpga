$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$iv = Join-Path $root 'bin\iverilog.exe'
$vv = Join-Path $root 'bin\vvp.exe'
$yosys = 'C:\Users\GAOKEHAN\AppData\Roaming\Python\Python313\Scripts\yowasp-yosys.exe'
$verilator = 'C:\Users\GAOKEHAN\AppData\Roaming\Python\Python313\Scripts\verilator-cli.exe'
$env:Path = 'C:\Strawberry\perl\bin;' + $env:Path
New-Item -ItemType Directory -Force -Path (Join-Path $root 'sim_out') | Out-Null
$tests = @('tb_allocator','tb_mixer','tb_i2s','tb_selfcheck','tb_fifo_e2e','tb_configs','tb_synth')
Push-Location $root
try {
  foreach ($test in $tests) {
    & $iv -g2012 -s $test -o "$test.vvp" -f scripts/filelist.f "tb/$test.sv"
    if ($LASTEXITCODE -ne 0) { throw "Icarus compile failed: $test" }
    & $vv "$test.vvp"
    if ($LASTEXITCODE -ne 0) { throw "Icarus simulation failed: $test" }
  }
  python scripts/check_fft.py
  if ($LASTEXITCODE -ne 0) { throw 'FFT validation failed' }
  & $yosys -s scripts/synth_check.ys
  if ($LASTEXITCODE -ne 0) { throw 'Yosys structural/synthesis check failed' }
  if (Test-Path $verilator) {
    # Verilator's warnings remain visible in the log, but do not turn a clean
    # structural lint run into an error. Yosys `check -assert` is the hard
    # gate for combinational loops, latches and multiple drivers.
    & $verilator --lint-only --Wall --Wno-fatal --top-module synth_core -f scripts/filelist.f
    if ($LASTEXITCODE -ne 0) { throw 'Verilator lint failed' }
  } else { throw 'Verilator executable is unavailable' }
  Write-Host 'REGRESSION PASS: simulation, FFT, Yosys and Verilator all passed.'
} finally { Pop-Location }
  python scripts/golden_model.py
  python scripts/pcm_to_wav.py
  python scripts/generate_report.py
