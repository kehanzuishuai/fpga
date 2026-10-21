param([ValidateSet('build','retime')][string]$Job='build')
$ErrorActionPreference='Stop'
$allProcesses=@(Get-CimInstance Win32_Process)
$jobPattern='tests[/\\]remote_music_20261019[/\\]'+[regex]::Escape($Job)+'[.]py'
$drivers=@($allProcesses | Where-Object { $_.Name -eq 'python.exe' -and $_.CommandLine -match $jobPattern })
if($drivers.Count -ne 1){throw 'Expected exactly one current-project build driver.'}
$ownedIds=@([int]$drivers[0].ProcessId)
do {
 $children=@($allProcesses | Where-Object { $ownedIds -contains [int]$_.ParentProcessId -and $ownedIds -notcontains [int]$_.ProcessId })
 $ownedIds+=@($children | ForEach-Object {[int]$_.ProcessId})
} while($children.Count -gt 0)
$allProcesses | Where-Object {$ownedIds -contains [int]$_.ProcessId} | Select-Object Name,ProcessId,CreationDate,@{N='CPU_seconds';E={[math]::Round(([double]$_.UserModeTime+[double]$_.KernelModeTime)/10000000,1)}},@{N='WorkingSet_MB';E={[math]::Round([double]$_.WorkingSetSize/1048576,1)}}
