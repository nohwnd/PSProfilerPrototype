Import-Module $PSScriptRoot\PSProfilerPrototype.psm1
$profiles = Measure-Script $PSScriptRoot\f.ps1 -Include $PSScriptRoot\f.ps1
$profiles[0].Profile | Format-Table