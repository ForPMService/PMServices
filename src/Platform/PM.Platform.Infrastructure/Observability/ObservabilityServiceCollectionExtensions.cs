using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace PM.Platform.Infrastructure;

public static class ObservabilityServiceCollectionExtensions
{
    public static IServiceCollection AddObservabilityToService(this IServiceCollection services, IConfiguration configuration)
    {
        TelemetryOptions telemetryOptions = CreateTelemetryOptions(configuration);

        OpenTelemetryBuilder openTelemetryBuilder = services.AddOpenTelemetry();

        ConfigureResource(openTelemetryBuilder, telemetryOptions);
        ConfigureTracing(openTelemetryBuilder);
        ConfigureMetrics(openTelemetryBuilder);

        return services;
    }

    private static TelemetryOptions CreateTelemetryOptions(IConfiguration configuration)
    {
        TelemetryOptions telemetryOptions = new();

        configuration
            .GetSection(TelemetryOptions.SectionName)
            .Bind(telemetryOptions);

        return telemetryOptions;
    }

    private static void ConfigureResource(
        OpenTelemetryBuilder openTelemetryBuilder,
        TelemetryOptions telemetryOptions)
    {
        string serviceName = GetServiceName(telemetryOptions);
        string serviceVersion = GetServiceVersion(telemetryOptions);

        openTelemetryBuilder.ConfigureResource(
            CreateResourceConfigurationAction(serviceName, serviceVersion));
    }

    private static Action<ResourceBuilder> CreateResourceConfigurationAction(
        string serviceName,
        string serviceVersion)
    {

        
        void ResourceConfigurationAction(ResourceBuilder builder)
        {
            builder.AddService(serviceName: serviceName, serviceVersion: serviceVersion);
        }

        return ResourceConfigurationAction;
    }

    private static void ConfigureTracing(OpenTelemetryBuilder openTelemetryBuilder)
    {
        openTelemetryBuilder.WithTracing(ConfigureTracingBuilder);
    }

    private static void ConfigureTracingBuilder(TracerProviderBuilder tracingBuilder)
    {
        tracingBuilder.AddAspNetCoreInstrumentation();
        tracingBuilder.AddHttpClientInstrumentation();
    }

    private static void ConfigureMetrics(OpenTelemetryBuilder openTelemetryBuilder)
    {
        openTelemetryBuilder.WithMetrics(ConfigureMetricsBuilder);
    }

    private static void ConfigureMetricsBuilder(MeterProviderBuilder metricsBuilder)
    {
        metricsBuilder.AddAspNetCoreInstrumentation();
        metricsBuilder.AddHttpClientInstrumentation();
        metricsBuilder.AddRuntimeInstrumentation();
    }

    private static string GetServiceName(TelemetryOptions telemetryOptions)
    {
        if (!string.IsNullOrWhiteSpace(telemetryOptions.ServiceName))
        {
            return telemetryOptions.ServiceName;
        }

        return "unknown-service";
    }

    private static string GetServiceVersion(TelemetryOptions telemetryOptions)
    {
        if (!string.IsNullOrWhiteSpace(telemetryOptions.ServiceVersion))
        {
            return telemetryOptions.ServiceVersion;
        }

        return "1.0.0";
    }
}

