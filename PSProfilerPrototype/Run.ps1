$ErrorActionPreference = 'Stop'
Get-Module PSTracerForPowerShell5, PSProfiler2 | Remove-Module

Import-Module $PSScriptRoot/PSTracerForPowerShell5.psm1
Import-Module $PSScriptRoot/PSProfiler2.psm1
 
if ($false) { 
    while (-not [System.Diagnostics.Debugger]::IsAttached) {
        Write-Host "Attach to $((Get-Process -Id $pid).Name) $pid"
        Start-Sleep -Seconds 1
    }
}

$trace = Trace-ScriptPowerShell5 { & "$PSScriptRoot/f.ps1" }
# $trace = Trace-ScriptPowerShell5 { & "C:\Users\jajares\Dropbox\presentations\pwsh24 2020\ProfilingScripts\scripts\hello.ps1" }
# $trace = Trace-ScriptPowerShell5 { & "C:\Users\jajares\Dropbox\presentations\pwsh24 2020\ProfilingScripts\scripts\good-bye.ps1" }

# $trace = Trace-ScriptPowerShell5 { &  "C:\temp\caller.ps1" }
# $trace = Trace-ScriptPowerShell5 { & "C:\temp\scripts\hello.ps1" }

 
if (-not $trace) {  
    throw "Trace is null something is wrong."
}

Write-Host -ForegroundColor Blue "Trace is done. Processing the it via Get-Profile"
$profiles = Get-Profile -Trace $trace # -Path $hello
Write-Host -ForegroundColor Blue "Get-Profile is done."

$profiles.Files | Select-Object -Property Path
# hello.ps1
$profiles.Files[2].Profile | Format-Table -Property Line, Duration, HitCount, Text 

# but how do we know what is slow? Well it's simple: 
$profiles.Top10 |
    Format-Table -Property Percent, HitCount, Duration, Average, Line, Text, CommandHits