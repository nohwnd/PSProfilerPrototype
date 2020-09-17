Import-Module "$PSScriptRoot/PSProfilerPrototype.dll"

function Get-Profile ($Path) {
    $files = $Path | foreach { (Resolve-Path $_).Path }

    $fileMap = @{}
    foreach ($file in $files) {
        $lines = Get-Content $file
        $lineProfiles = [Collections.Generic.List[object]]::new($lines.Length)
        $index = 0
        foreach ($line in $lines) {
            $lineProfile = [PSCustomObject] @{
                Line = ++$index # start from 1 as in file
                Duration = [TimeSpan]::Zero
                HitCount = 0
                Text = $line
                Hits = [Collections.Generic.List[object]]::new()
            }

            $lineProfiles.Add($lineProfile)
        }

        $fileMap.Add($file, $lineProfiles)
    }

    foreach ($hit in [PSProfilerPrototype.Tracer]::Hits) {
        if (-not $hit.Extent.File -or -not ($fileMap.Contains($hit.Extent.File))) {
            continue
        }

        $lineProfiles = $fileMap[$hit.Extent.File]
        $lineProfile = $lineProfiles[$hit.Extent.StartLineNumber - 1] # array indexes from 0, but lines from 1
        $lineProfile.Duration += $hit.Duration
        $lineProfile.HitCount++
        $lineProfile.Hits.Add($hit)
    }

    foreach ($pair in $fileMap.GetEnumerator()) {
        [PSCustomObject]@{
            Path = $pair.Key
            Profile = $pair.Value
        }
    }
}

function Measure-Script ($ScriptBlock, $Include) {

    try {
        [PSProfilerPrototype.Tracer]::PatchOrUnpatch($ExecutionContext, $true)
        Set-PSDebug -Trace 1
        [PSProfilerPrototype.Tracer]::Hits.Clear()

        $null = & $ScriptBlock
    } 
    finally {
        Set-PSDebug -Trace 0
        [PSProfilerPrototype.Tracer]::PatchOrUnpatch($ExecutionContext, $false)
    }

    Get-Profile $Include
}

