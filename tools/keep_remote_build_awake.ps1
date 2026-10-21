# Temporary system execution request tied to this project's one build driver.
# Allows the display to turn off; does not alter power plans or block manual sleep.
param([ValidateSet('build','regress_latest','retime')][string]$Job='build')
$ErrorActionPreference='Stop'
$jobPattern='tests[/\\]remote_music_20261019[/\\]'+[regex]::Escape($Job)+'[.]py'
$drivers=@(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'python.exe' -and $_.CommandLine -match $jobPattern })
if($drivers.Count -ne 1){throw 'Expected exactly one current-project build driver.'}
$driver=Get-Process -Id $drivers[0].ProcessId
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RemoteBuildExecutionRequest {
 [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint flags);
}
'@
try {
 if([RemoteBuildExecutionRequest]::SetThreadExecutionState([uint32]2147483649) -eq 0){throw 'Windows rejected the temporary execution request.'}
 Write-Output "Temporary system-awake request active for this task's $Job driver; display may turn off."
 while(-not $driver.WaitForExit(30000)){}
} finally {
 [void][RemoteBuildExecutionRequest]::SetThreadExecutionState([uint32]2147483648)
 Write-Output 'Build ended; temporary execution request released.'
}
