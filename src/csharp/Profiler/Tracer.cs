using HarmonyLib;
using System.Reflection;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Collections.Generic;
using System.Diagnostics;
using System;
using System.Linq;

namespace Profiler
{
    public static class Tracer
    {
        private static Hit _previousHit;
        private static Harmony _harmony;
        private static bool _first;
        private static int _index;

        private static List<Hit> _hits;

        private static List<string> _include;
        private static List<string> _exclude;

        public static void Enable(EngineIntrinsics context, IEnumerable<string> include = null, IEnumerable<string> exclude = null)
        {
            _hits = new List<Hit>(1000);
            _harmony = new Harmony("fix.debugger");
            _first = true;
            _index = 0;

            _include = include?.ToList();
            _exclude = exclude?.ToList();

            MethodInfo method = GetMethodToPrefix(context);
            var prefix = typeof(Tracer).GetMethod(nameof(TraceLine), BindingFlags.Static | BindingFlags.NonPublic);
            _harmony.Patch(method, new HarmonyMethod(prefix));
        }

        public static List<Hit> Disable()
        {
            if (_previousHit != null)
            {
                _previousHit.Duration = TimeSpan.FromTicks(Stopwatch.GetTimestamp() - _previousHit.Timestamp);
            }

            if (_harmony != null)
            {
                _harmony.UnpatchAll();
            }

            // and unreference the one in static collection
            var hits = _hits;
            _hits = null;
            // skip last one because that is call to disable tracing that we use to figure out 
            // the duration of the last instruction
            return hits.Take(hits.Count - 1).ToList();
        }

        private static MethodInfo GetMethodToPrefix(EngineIntrinsics context)
        {
            // getting MethodInfo of context._context.Debugger.TraceLine
            var bf = BindingFlags.NonPublic | BindingFlags.Instance;
            var contextInternal = context.GetType().GetField("_context", bf).GetValue(context);
            var debugger = contextInternal.GetType().GetProperty("Debugger", bf).GetValue(contextInternal);
            var method = debugger.GetType().GetMethod(nameof(TraceLine), bf);

            return method;
        }

        private static bool TraceLine(IScriptExtent extent)
        {
            Trace(extent);
            return false;
        }

        private static void Trace(IScriptExtent extent)
        {
            var hasIncludeFilter = _include != null && _include.Count != 0;
            if (hasIncludeFilter)
            {
                if (extent.File == null || !_include.Any(f => f.EndsWith(extent.File)))
                {
                    return;
                }
            }

            var hasExcludeFilter = _exclude != null && _exclude.Count != 0;
            if (hasExcludeFilter)
            {
                if (extent.File != null && !_exclude.Any(f => f.EndsWith(extent.File)))
                {
                    return;
                }
            }

            // Write duration to the previous timestamp. Duration is the start of the 
            // previous entry, till the start of the current entry
            var timestamp = Stopwatch.GetTimestamp();
            if (_previousHit != null)
            {
                _previousHit.Duration = TimeSpan.FromTicks(timestamp - _previousHit.Timestamp);
            }

            // Add the current hit.
            // And set the current hit as the previous so we calculate duration in the 
            // next iteration.
            var currentHit = _previousHit = new Hit(timestamp, extent);

            // Skip adding the first item, because the first item is the call to enable tracing
            // and it would add noise to the measuring
            if (_first)
            {
                _first = false;
            }
            else
            {
                _hits.Add(currentHit);
                currentHit.Index = _index;
                _index++;
            }
            currentHit.Overhead = Stopwatch.GetTimestamp() - timestamp;
        }
    }
}
