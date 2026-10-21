# Stop only simulation children for this task; leave full Gowin build running.
$ErrorActionPreference='Stop'
$all=@(Get-CimInstance Win32_Process)
$roots=@()
foreach($job in @('share_equiv','gate_bank','regress_latest')){
 $pattern='tests[/\\]remote_music_20261019[/\\]'+[regex]::Escape($job)+'[.]py'
 $matchesForJob=@($all | Where-Object {$_.Name -eq 'python.exe' -and $_.CommandLine -match $pattern})
 if($matchesForJob.Count -gt 1){throw "Multiple $job drivers: refusing to stop anything."}
 $roots+=@($matchesForJob)
}
foreach($root in $roots){
 $rootId=[int]$root.ProcessId;$ids=@($rootId)
 do{
  $children=@($all | Where-Object {$ids -contains [int]$_.ParentProcessId -and $ids -notcontains [int]$_.ProcessId})
  $ids+=@($children | ForEach-Object {[int]$_.ProcessId})
 }while($children.Count -gt 0)
 foreach($ownedId in ($ids | Where-Object {$_ -ne $rootId} | Sort-Object -Descending)){
  Stop-Process -Id $ownedId -ErrorAction SilentlyContinue
 }
}
Write-Output "Stopped children of $($roots.Count) current-task simulation drivers; Gowin build untouched."
