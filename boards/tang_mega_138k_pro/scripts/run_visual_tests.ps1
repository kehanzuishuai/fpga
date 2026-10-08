$ErrorActionPreference='Stop'
$runtime='C:\Users\GAOKEHAN\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $runtime (Join-Path $PSScriptRoot 'verify_visual.py')
if($LASTEXITCODE -ne 0){throw 'Visualization verification failed. See sim_out_visual.'}
& (Join-Path $PSScriptRoot 'run_pcm5102a_tests.ps1')
if($LASTEXITCODE -ne 0){throw 'Existing dual-DAC regression failed.'}
