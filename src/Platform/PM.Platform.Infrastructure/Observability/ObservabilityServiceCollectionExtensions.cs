using System;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using OpenTelemetry.Exporter;

namespace PM.Platform.Infrastructure;

public static class ObservabilityServiceCollectionExtensions
{
    public static IServiceCollection AddObservabilityToService(this IServiceCollection services, IConfiguration configuration)
    {
        // Register TelemetryOptions via options pattern
        services.AddOptions<TelemetryOptions>()
            .Bind(configuration.GetSection(TelemetryOptions.SectionName));

        // Also read options locally for immediate configuration
        TelemetryOptions telemetryOptions = new TelemetryOptions();
        configuration.GetSection(TelemetryOptions.SectionName).Bind(telemetryOptions);

        OpenTelemetryBuilder openTelemetryBuilder = services.AddOpenTelemetry();

        ConfigureResource(openTelemetryBuilder, telemetryOptions);
        ConfigureTracing(openTelemetryBuilder, telemetryOptions);
        ConfigureMetrics(openTelemetryBuilder, telemetryOptions);

        return services;
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

    private static void ConfigureTracing(OpenTelemetryBuilder openTelemetryBuilder, TelemetryOptions telemetryOptions)
    {
        openTelemetryBuilder.WithTracing(builder => ConfigureTracingBuilder(builder, telemetryOptions));
    }

    private static void ConfigureTracingBuilder(TracerProviderBuilder tracingBuilder, TelemetryOptions telemetryOptions)
    {
        tracingBuilder.AddAspNetCoreInstrumentation();
        tracingBuilder.AddHttpClientInstrumentation();

        string? endpoint = GetOtlpEndpoint(telemetryOptions);
        if (!string.IsNullOrWhiteSpace(endpoint))
        {
            if (Uri.TryCreate(endpoint, UriKind.Absolute, out var uri))
            {
                tracingBuilder.AddOtlpExporter(o => o.Endpoint = uri);
            }
            else
            {
                // best-effort: try to interpret as non-absolute URI via environment variable support
                tracingBuilder.AddOtlpExporter();
            }
        }
    }

    private static void ConfigureMetrics(OpenTelemetryBuilder openTelemetryBuilder, TelemetryOptions telemetryOptions)
    {
        openTelemetryBuilder.WithMetrics(builder => ConfigureMetricsBuilder(builder, telemetryOptions));
    }

    private static void ConfigureMetricsBuilder(MeterProviderBuilder metricsBuilder, TelemetryOptions telemetryOptions)
    {
        metricsBuilder.AddAspNetCoreInstrumentation();
        metricsBuilder.AddHttpClientInstrumentation();
        metricsBuilder.AddRuntimeInstrumentation();

        string? endpoint = GetOtlpEndpoint(telemetryOptions);
        if (!string.IsNullOrWhiteSpace(endpoint))
        {
            if (Uri.TryCreate(endpoint, UriKind.Absolute, out var uri))
            {
                metricsBuilder.AddOtlpExporter(o => o.Endpoint = uri);
            }
            else
            {
                metricsBuilder.AddOtlpExporter();
            }
        }
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

    private static string? GetOtlpEndpoint(TelemetryOptions telemetryOptions)
    {
        if (!string.IsNullOrWhiteSpace(telemetryOptions.OtelEndpoint))
        {
            return telemetryOptions.OtelEndpoint;
        }

        return Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT");
    }
}

