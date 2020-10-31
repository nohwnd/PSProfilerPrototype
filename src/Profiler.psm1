function Trace-Script { 
    [CmdletBinding()]
    param($ScriptBlock) 
        
    try {
        [Profiler.Tracer]::Enable($ExecutionContext, $null, $null)
        Set-PSDebug -Trace 1
        
        $null = & $ScriptBlock
    }
    finally {
        try {
            Set-PSDebug -Trace 0
            $hits = [Profiler.Tracer]::Disable()
            $hits
        }
        catch { 

        }
    }
}

function Measure-Script {
    [CmdletBinding()]
    param($ScriptBlock)
    

    $t = Trace-Script -ScriptBlock $ScriptBlock
    $p =  Get-Profile -Trace $trace

    [PSCustomObject] @{
        Trace = $t
        Profile = $p
    }
}

function Get-Profile ($Trace, $Path) {
    if ($Path) {
        $files = $Path | ForEach-Object { (Resolve-Path $_).Path }
    }
    else { 
        $files = $Trace | Select-Object -ExpandProperty Path
    }

    $fileMap = @{}
    foreach ($file in $files) {
        if (-not $fileMap.ContainsKey($file)) {
            $lines = Get-Content $file
            # each line in this file will gets its own object
            $lineProfiles = [Collections.Generic.List[object]]::new($lines.Length)
            $index = 0
            foreach ($line in $lines) {
                $lineProfile = [PSCustomObject] @{
                    Percent = 0
                    HitCount = 0 
                    Duration = [TimeSpan]::Zero
                    Average = [TimeSpan]::Zero

                    Line = ++$index # start from 1 as in file
                    Text = $line
                    Hits = [Collections.Generic.List[object]]::new()
                    CommandHits = @{}
                    Path = $file
                }

                $lineProfiles.Add($lineProfile)
            }

            $fileMap.Add($file, $lineProfiles)
        }
        else { 
            # skip the file, because we already processed it, this is an alternative to sorting the list 
            # of files and getting unique, but that would be slower
        }
    }

    foreach ($hit in $trace) {
        if (-not $hit.Path -or -not ($fileMap.Contains($hit.Path))) {
            continue
        }

        # get the object that describes this particular file
        $lineProfiles = $fileMap[$hit.Path]

        $lineProfile = $lineProfiles[$hit.Line - 1] # array indexes from 0, but lines from 1
        $lineProfile.Duration += $hit.Duration
        $lineProfile.HitCount++
        $lineProfile.Hits.Add($hit)

        # add distinct entries per column when there are more commands
        # on the same line (like we did it with the Group-Object on foreach ($i in 1...1000))
        if ($lineProfile.CommandHits.ContainsKey($hit.Column)) { 
            $commandHit = $lineProfile.CommandHits[$hit.Column] 
            $commandHit.Duration += $hit.Duration
            $commandHit.HitCount++
        }
        else { 
            $commandHit = [PSCustomObject] @{
                Line = $hit.Line # start from 1 as in file
                Column = $hit.Column
                Duration = $hit.Duration
                HitCount = 1
                Text = $hit.Text
            }
            $lineProfile.CommandHits.Add($hit.Column, $commandHit)
        }
    }

    $total = [TimeSpan]::FromTicks($trace[-1].Timestamp - $trace[0].Timestamp)

    # this is like SelectMany, it joins the arrays of arrays
    # into a single array
    $all = $fileMap.Values | Foreach-Object { $_ } | ForEach-Object { 
        $_.Average = if ($_.HitCount -eq 0) { [TimeSpan]::Zero } else { [TimeSpan]::FromTicks($_.Duration.Ticks / $_.HitCount) }
        $_.Percent = [Math]::Round($_.Duration.Ticks / $total.Ticks, 4, [System.MidpointRounding]::AwayFromZero) * 100
        $_ }

    $top10Percent = $all | 
        Where-Object Percent -gt 0.01 | 
        Sort-Object -Property Percent -Descending | 
        Select-Object -First 10

    $top10Average = $all | 
        Where-Object Average -gt 0 | 
        Sort-Object -Property Average -Descending | 
        Select-Object -First 10
        
    $top10Duration = $all |
        Where-Object Duration -gt 0 | 
        Sort-Object -Property Duration -Descending | 
        Select-Object -First 10
    
    $top10HitCount = $all | 
        Where-Object HitCount -gt 0 | 
        Sort-Object -Property HitCount -Descending | 
        Select-Object -First 10

    [PSCustomObject] @{ 
        Top10 = $top10Percent
        Top10Average = $top10Average
        Top10Duration = $top10Duration
        Top10HitCount = $top10HitCount
        TotalDuration = $total
        Files = foreach ($pair in $fileMap.GetEnumerator()) {
            [PSCustomObject]@{
                Path = $pair.Key
                Profile = $pair.Value
            }
        }
    }
}