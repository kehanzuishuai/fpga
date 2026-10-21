param([switch]$StopOnly)
$ErrorActionPreference = 'Stop'
$allProcesses = @(Get-CimInstance Win32_Process)
$probe = @($allProcesses | Where-Object { $_.Name -eq 'gw_sh.exe' -and $_.CommandLine -like '*tools/probe_remote_synth.tcl*' })
if ($probe.Count -gt 1) { throw 'Ambiguous synthesis probe; refusing to stop processes.' }
if ($probe.Count -eq 1) {
    $ownedIds = @([int]$probe[0].ProcessId)
    do {
        $children = @($allProcesses | Where-Object { $ownedIds -contains [int]$_.ParentProcessId -and $ownedIds -notcontains [int]$_.ProcessId })
        $ownedIds += @($children | ForEach-Object { [int]$_.ProcessId })
    } while ($children.Count -gt 0)
    foreach ($ownedId in ($ownedIds | Sort-Object -Descending)) { Stop-Process -Id $ownedId -ErrorAction SilentlyContinue }
    Write-Output "Stopped this task's stale synthesis probe and its children."
}
if ($StopOnly) { exit 0 }
Copy-Item -LiteralPath 'tests/remote_music_20261019/out/synth_probe.log' -Destination 'tests/remote_music_20261019/out/synth_probe_stale.log' -Force
& 'C:\Gowin2\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe' 'tools/probe_remote_synth.tcl' *> 'tests/remote_music_20261019/out/synth_probe.log'
exit $LASTEXITCODE
