using HarmonyLib;
using System.Reflection;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Collections.Generic;
using System.Diagnostics;
using System;

namespace PSProfilerPrototype
{
    public static class Tracer
    {
        internal static Hit _previousHit;

        public static List<Hit> Hits { get; } = new List<Hit>();

        public static void PatchOrUnpatch(EngineIntrinsics context, bool patch)
        {
            if (patch == false)
            {
                _previousHit.Duration = TimeSpan.FromTicks(Stopwatch.GetTimestamp() - _previousHit.Timestamp);
            }

            var harmony = new Harmony("fix.debugger");
            var bf = BindingFlags.NonPublic | BindingFlags.Instance;
            var contextInternal = context.GetType().GetField("_context", bf).GetValue(context);
            var debugger = contextInternal.GetType().GetProperty("Debugger", bf).GetValue(contextInternal);
            var traceLine = debugger.GetType().GetMethod("TraceLine", bf);
            var traceLinePrefix = typeof(Tracer).GetMethod("TraceLine", BindingFlags.Static | BindingFlags.Public);

            if (patch)
            {
                harmony.Patch(traceLine, new HarmonyMethod(traceLinePrefix));
            }
            else
            {
                harmony.UnpatchAll();
            }
        }

        public static bool TraceLine(IScriptExtent extent)
        {
            var timestamp = Stopwatch.GetTimestamp();
            if ( _previousHit != null ) {
                _previousHit.Duration = TimeSpan.FromTicks(timestamp - _previousHit.Timestamp);
            }

            _previousHit = new Hit(timestamp, extent);
            Hits.Add(_previousHit);

            // skip the method call to avoid tracing to debug
            return false;
        }
    }
}
