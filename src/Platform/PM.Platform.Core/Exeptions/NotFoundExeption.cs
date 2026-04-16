using System;
using System.Collections.Generic;
using System.Text;

namespace PM.Platform.Core.Exeptions
{
    public sealed class NotFoundExeption : Exception
    {
        public NotFoundExeption(string message) : base(message) { }

        public NotFoundExeption(string message, Exception innerException) : base(message, innerException) { }
    }
}
