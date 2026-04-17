namespace PM.IAM.Infrastructure;

public class TelemetryOptions
{
    public const string SectionName = "Telemetry";
    public string ServiceName { get; set; } = string.Empty;
    public string ServiceVersion { get; set; } = string.Empty;
    public string? OtelEndpoint { get; set; }

}
