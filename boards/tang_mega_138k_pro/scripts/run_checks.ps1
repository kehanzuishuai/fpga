param([ValidateSet('all','dac','adc')][string]$Suite='all')
$ErrorActionPreference='Stop'
$pythonCommand=$env:FPGA_PYTHON
if(-not $pythonCommand){
    foreach($candidate in @('python','python3','py')){
        $found=Get-Command $candidate -ErrorAction SilentlyContinue
        if($found){$pythonCommand=$found.Source; break}
    }
}
if(-not $pythonCommand){throw 'Python not found. Install on PATH or set FPGA_PYTHON.'}
$entry=switch($Suite){'dac'{'verify_pcm5102a.py'} 'adc'{'verify_adc.py'} default{'run_regression.py'}}
& $pythonCommand (Join-Path $PSScriptRoot $entry)
if($LASTEXITCODE -ne 0){throw "FPGA $Suite checks failed; see simulation reports."}
