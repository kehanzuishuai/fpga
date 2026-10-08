$ErrorActionPreference = 'Stop'
$pythonRuntime = 'C:\Users\GAOKEHAN\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $pythonRuntime (Join-Path $PSScriptRoot 'verify_pcm5102a.py')
if ($LASTEXITCODE -ne 0) { throw 'PCM5102A verification failed; inspect sim_out_pcm5102a logs.' }
