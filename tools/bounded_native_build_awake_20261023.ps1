# Temporary execution request on one native thread, with a bounded lifetime.
# Does not change the power policy or override manual sleep/lid actions.
param([ValidateRange(1,180)][int]$Minutes=120)
$ErrorActionPreference='Stop'
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Threading;
public static class BoundedBuildAwake {
 [DllImport("kernel32.dll")] static extern uint SetThreadExecutionState(uint flags);
 public static void Run(int minutes) {
  if (SetThreadExecutionState(0x80000003u)==0) throw new Exception("Execution request rejected");
  try { Thread.Sleep(checked(minutes*60000)); }
  finally { SetThreadExecutionState(0x80000000u); }
 }
}
'@
Write-Output "Bounded build execution request: pid=$PID minutes=$Minutes started=$(Get-Date -Format o)"
[BoundedBuildAwake]::Run($Minutes)
Write-Output 'Temporary execution request released.'
