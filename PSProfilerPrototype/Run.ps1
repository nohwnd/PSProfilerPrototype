$ErrorActionPreference = 'Stop'
Get-Module PSTracerForPowerShell5, PSProfiler2 | Remove-Module

Import-Module $PSScriptRoot/PSTracerForPowerShell5.psm1
Import-Module $PSScriptRoot/PSProfiler2.psm1
 
$traceCore = Trace-ScriptPowerShell5 { & "$PSScriptRoot/f.ps1" }

$index = 0
$trace = $(foreach ($t in $traceCore) { 
    [PSCustomObject] @{
        # path of the script
        Path = $t.Extent.File

        # the line
        Line = $t.Extent.StartLineNumber
        # the column
        Column = $t.Extent.StartColumnNumber

        # the extent reference
        Extent = $t.Extent
        # or the text if we don't have extent
        Text = $t.Extent.Text

        # when it happened
        Timestamp = $t.Timestamp

        # how long it took
        Duration = $t.Duration

        # on which index in the collection of all events this one is
        Index = $index

        Overhead = [TimeSpan]::Zero
    }

    $index++
})


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