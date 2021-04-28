# See https://github.com/nohwnd/Profiler for module that supports PowerShell 7 and 5. This repository is archived.


## PSProfiler prototype

This prototype uses Harmony to inject a method into the ScriptDebugger to replace call to TraceLine which would normally write to Debug. This allow us to trace scripts on PowerShell 5 

> :fire: Use PowerShell 5, it does not work with PowerShell Core.

You can run it directly from built-0.0.1 folder or root or build it yourself. Run `built-0.0.1\Run.ps1` script and see the magic.


(This is just for fun, but maybe will also allow us to mock .NET calls and stuff like that)
