namespace PM.Platform.Core;

public sealed class DomainExeption: Exception
{
    public DomainExeption(string message) : base(message) { }

    public DomainExeption(string message, Exception innerException) : base(message, innerException) { }
}
