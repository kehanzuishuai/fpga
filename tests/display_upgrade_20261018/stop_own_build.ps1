$displayProcesses = @(Get-CimInstance Win32_Process)
$displayBuilds = @($displayProcesses | Where-Object { $_.Name -eq 'gw_sh.exe' -and $_.CommandLine -match 'tools[\\/]build_gowin\.tcl' })
if ($displayBuilds.Count -ne 1) { throw 'Expected exactly our one production build; no process stopped.' }
$displayIds = [System.Collections.Generic.List[uint32]]::new()
$displayIds.Add([uint32]$displayBuilds[0].ProcessId)
for ($displayIndex=0; $displayIndex -lt $displayIds.Count; $displayIndex++) {
    foreach ($displayChild in @($displayProcesses | Where-Object { $_.ParentProcessId -eq $displayIds[$displayIndex] })) { $displayIds.Add([uint32]$displayChild.ProcessId) }
}
$displayTargets = @($displayProcesses | Where-Object { $displayIds.Contains([uint32]$_.ProcessId) })
$displayTargets | Select-Object ProcessId,ParentProcessId,Name,CommandLine | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath 'D:\gaoyun\piano_v2_audio_fix\audit\display_upgrade_20261018\STOP_release_final.json'
for ($displayIndex=$displayIds.Count-1; $displayIndex -ge 0; $displayIndex--) { Stop-Process -Id $displayIds[$displayIndex] -Force -ErrorAction SilentlyContinue }
Write-Output 'Stopped only this task production build and its descendants: known371MHz fabric pulse-width failure; no programming.'
