param (
    [switch] $CI,
    [string[]] $File
)

$ErrorActionPreference = 'Stop'

Get-Module Pester, Profiler | Remove-Module

Import-Module Pester -MinimumVersion '5.0.0'
Import-Module $PSScriptRoot/bin/Profiler.psd1

$configuration = [PesterConfiguration]::Default

if ($null -ne $File -and 0 -lt @($File).Count) {
    $configuration.Run.Path = $File
}
else
{
    $configuration.Run.Path = "$PSScriptRoot/tst"
}

$configuration.Run.PassThru = $true

if ($CI) {
    $configuration.Run.Exit = $true

    # $configuration.CodeCoverage.Enabled = $true
    # $configuration.CodeCoverage.Path = "$PSScriptRoot/src/*"

    $configuration.TestResult.Enabled = $true
}

$r = Invoke-Pester -Configuration $configuration
if ("Failed" -eq $r.Result) {
    throw "Run failed!"
}
