using System.Management.Automation.Language;
using System;

namespace PSProfilerPrototype
{
    public class Hit
    {
        public Hit(long timestamp, IScriptExtent extent)
        {
            Timestamp = timestamp;
            Extent = extent;
            Duration = TimeSpan.Zero;
        }

        public long Timestamp { get; }
        public TimeSpan Duration { get; internal set; }
        public IScriptExtent Extent { get; }

        public string Path => Extent.File;
        public int Line => Extent.StartLineNumber;
        public int Column => Extent.StartColumnNumber;
        public string Text => Extent.Text;
    
        public int Index { get; internal set; }

        public long Overhead { get; internal set; }
    }
}
