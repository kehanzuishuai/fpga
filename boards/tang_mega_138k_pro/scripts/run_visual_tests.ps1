$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'run_checks.ps1') -Suite all
