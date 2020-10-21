# for bp to attach 

function Trace-ScriptPowerShell5 { 
    [CmdletBinding()]
    param($ScriptBlock) 
    
    if ($PSVersionTable.PSVersion.Major -le 5) { 
        Import-Module "$PSScriptRoot/bin/Debug/net452/PSProfilerPrototype.dll"
    }
    else { 
        Import-Module "$PSScriptRoot/bin/Debug/netcoreapp3.1/PSProfilerPrototype.dll"
    }
    
    try {
        [PSProfilerPrototype.Tracer]::PatchOrUnpatch($ExecutionContext, $true)
        Set-PSDebug -Trace 1
        

        $null = & $ScriptBlock
    } 
    finally {
        Set-PSDebug -Trace 0
        [PSProfilerPrototype.Tracer]::PatchOrUnpatch($ExecutionContext, $false)
    }

    # copy the list
    [PSProfilerPrototype.Tracer]::Hits | ForEach-Object { $_ }
}