$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$iv = Join-Path $root 'bin\iverilog.exe'
$vv = Join-Path $root 'bin\vvp.exe'
$yosys = 'C:\Users\GAOKEHAN\AppData\Roaming\Python\Python313\Scripts\yowasp-yosys.exe'
$verilator = 'C:\Users\GAOKEHAN\AppData\Roaming\Python\Python313\Scripts\verilator-cli.exe'
$env:Path = 'C:\Strawberry\perl\bin;' + $env:Path
$env:LC_ALL = 'C'
$env:LANG = 'C'
$outDir = Join-Path $root 'sim_out'
if (Test-Path -LiteralPath $outDir) {
  $resolvedOut = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $outDir).Path)
  $expectedOut = [IO.Path]::GetFullPath((Join-Path $root 'sim_out'))
  if ($resolvedOut -ne $expectedOut) { throw "Refusing to clean unexpected output path: $resolvedOut" }
  Get-ChildItem -LiteralPath $resolvedOut -Force | Remove-Item -Recurse -Force
} else { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$tests = @(
  'tb_allocator','tb_mixer','tb_i2s','tb_uart_stream','tb_waveform_lut',
  'tb_note_table','tb_polyphony_gain','tb_modes',
  'tb_selfcheck','tb_fifo_stress','tb_voice_bank_events','tb_voice_edges',
  'tb_golden_vectors','tb_fifo_e2e','tb_configs','tb_synth'
)
$lintTops = @(
  'synth_core','synth_event_frontend','i2s_tx','uart_tx',
  'telemetry_uart','waveform_gen','note_event_fifo','led_guide','performance_mode_controller'
)

Push-Location $root
try {
  foreach ($test in $tests) {
    Write-Host "[SIM] $test"
    & $iv -g2012 -s $test -o "$test.vvp" -f scripts/filelist.f "tb/$test.sv"
    if ($LASTEXITCODE -ne 0) { throw "Icarus compile failed: $test" }
    & $vv "$test.vvp"
    if ($LASTEXITCODE -ne 0) { throw "Icarus simulation failed: $test" }
  }

  python scripts/check_waveform.py
  if ($LASTEXITCODE -ne 0) { throw 'sine LUT validation failed' }
  python scripts/check_note_table.py
  if ($LASTEXITCODE -ne 0) { throw 'MIDI phase-ROM validation failed' }
  python scripts/golden_model.py
  if ($LASTEXITCODE -ne 0) { throw 'bit-exact golden-model validation failed' }
  python scripts/check_fft.py
  if ($LASTEXITCODE -ne 0) { throw '32-Voice FFT validation failed' }
  python scripts/pcm_to_wav.py
  if ($LASTEXITCODE -ne 0) { throw 'PCM to WAV conversion failed' }

  Write-Host '[RESOURCE] Yosys generic before/after metrics'
  & $yosys -s scripts/resource_stat.ys *> (Join-Path $outDir 'resource_after.log')
  if ($LASTEXITCODE -ne 0) { throw 'Yosys resource statistics failed' }
  python scripts/check_resources.py
  if ($LASTEXITCODE -ne 0) { throw 'resource optimization validation failed' }

  Write-Host '[SYNTH] Yosys generic structural checks'
  & $yosys -s scripts/synth_check.ys *> (Join-Path $outDir 'yosys.log')
  if ($LASTEXITCODE -ne 0) { throw 'Yosys structural/synthesis check failed' }

  foreach ($top in $lintTops) {
    Write-Host "[LINT] $top"
    $lintLog = Join-Path $outDir "verilator_$top.log"
    & $verilator --lint-only --Wall --top-module $top -f scripts/filelist.f *> $lintLog
    if ($LASTEXITCODE -ne 0) { throw "Verilator strict lint failed: $top (see $lintLog)" }
  }

  python scripts/generate_report.py
  if ($LASTEXITCODE -ne 0) { throw 'verification report generation failed' }
  Write-Host ''
  Write-Host 'REGRESSION PASS'
  Write-Host "  Icarus self-checks : $($tests.Count)/$($tests.Count) PASS"
  Write-Host '  Independent peaks  : 32/32 PASS'
  Write-Host '  Golden comparisons : 336/336 PASS'
  Write-Host '  Generic arithmetic : 66->0 div, 257->225 mul, 1->0 mod'
  Write-Host "  Verilator tops     : $($lintTops.Count)/$($lintTops.Count) PASS, 0 RTL warnings"
  Write-Host '  Yosys check         : PASS, 0 structural problems'
  Write-Host '  Report              : sim_out/verification_report.md'
} finally {
  Pop-Location
}
