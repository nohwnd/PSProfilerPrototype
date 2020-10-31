$ErrorActionPreference = 'Stop'
Get-Module PSTracerForPowerShell5, PSProfiler2 | Remove-Module

$profilerModule = Import-Module $PSScriptRoot/src/Profiler.psd1 -PassThru
$Get_Profile = & ($profilerModule) { Get-Command -Module Profiler Get-Profile }
 
if ($false) { 
    while (-not [System.Diagnostics.Debugger]::IsAttached) {
        Write-Host "Attach to $((Get-Process -Id $pid).Name) $pid"
        Start-Sleep -Seconds 1
    }
}


$trace = Trace-Script { & "$PSScriptRoot/f.ps1" }
$traceOfProfiler = Trace-Script { 
    & $Get_Profile -Trace $trace 
}

$profiles = & $Get_Profile $traceOfProfiler

$profiles.Files | Select-Object -Property Path
# hello.ps1
$profiles.Files[2].Profile | Format-Table -Property Line, Duration, HitCount, Text 

# but how do we know what is slow? Well it's simple: 
$profiles.Top10 |
    Format-Table -Property Percent, HitCount, Duration, Average, Line, Text, CommandHits