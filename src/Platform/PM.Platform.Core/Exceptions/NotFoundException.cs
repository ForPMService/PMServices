using System;
using System.Collections.Generic;
using System.Text;

namespace PM.Platform.Core.Exceptions
{
    public sealed class NotFoundException : Exception
    {
        public NotFoundException(string message) : base(message) { }

        public NotFoundException(string message, Exception innerException) : base(message, innerException) { }
    }
}
