param([ValidateSet('build','retime','system','toolchain','regress_latest','share_equiv','gate_bank','audio_top','score_top')][string]$Job)
$ErrorActionPreference = 'Stop'
$allProcesses = @(Get-CimInstance Win32_Process)
if ($Job -eq 'toolchain') {
    $download = @($allProcesses | Where-Object { $_.Name -eq 'arduino-cli.exe' -and $_.CommandLine.Replace('\','/') -like '*piano_v2_audio_fix/tools/toolchains/arduino/arduino-cli.yaml*' -and $_.CommandLine -like '*core install esp32:esp32@3.3.12*' })
    if ($download.Count -ne 1) { throw 'Expected one task-specific old toolchain download.' }
    Stop-Process -Id $download[0].ProcessId
    Write-Output 'Stopped this task old GitHub download so the verified official China mirror can be used.'
    exit 0
}
$suffix = "*tests/remote_music_20261019/$Job.py*"
$owned = @($allProcesses | Where-Object { $_.Name -eq 'python.exe' -and $_.CommandLine.Replace('\','/') -like $suffix })
if ($owned.Count -ne 1) { throw 'Expected one task-specific driver; refusing to stop processes.' }
$parentId = [int]$owned[0].ProcessId
$ownedIds = @($parentId)
do {
    $children = @($allProcesses | Where-Object { $ownedIds -contains [int]$_.ParentProcessId -and $ownedIds -notcontains [int]$_.ProcessId })
    $ownedIds += @($children | ForEach-Object { [int]$_.ProcessId })
} while ($children.Count -gt 0)
foreach ($ownedId in ($ownedIds | Where-Object { $_ -ne $parentId } | Sort-Object -Descending)) {
    Stop-Process -Id $ownedId -ErrorAction SilentlyContinue
}
Write-Output "Stopped only the children of this task's $Job driver. The driver can record the failed attempt."
