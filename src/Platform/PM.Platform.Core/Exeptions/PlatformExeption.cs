using System;
using System.Collections.Generic;
using System.Text;

namespace PM.Platform.Core.Exeptions
{
    public abstract class PlatformExeption: Exception
    {
        protected PlatformExeption(string message) : base(message) { }

        protected PlatformExeption(string message, Exception innerException) : base(message, innerException) { }
    }
}
