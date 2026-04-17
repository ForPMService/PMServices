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
        // Регистрируем TelemetryOptions через options pattern и включаем ValidateOnStart
        services.AddOptions<TelemetryOptions>()
            .Bind(configuration.GetSection(TelemetryOptions.SectionName))
            .ValidateOnStart();

        // Считываем сконфигурированные TelemetryOptions из построенного ServiceProvider для немедленной настройки
        using var sp = services.BuildServiceProvider();
        TelemetryOptions telemetryOptions = sp.GetRequiredService<IOptions<TelemetryOptions>>().Value;

        OpenTelemetryBuilder openTelemetryBuilder = services.AddOpenTelemetry();

        // Настроим ресурс (имя сервиса/версия)
        string serviceName = GetServiceName(telemetryOptions);
        string serviceVersion = GetServiceVersion(telemetryOptions);
        openTelemetryBuilder.ConfigureResource(rb => rb.AddService(serviceName: serviceName, serviceVersion: serviceVersion));

        ConfigureTracing(openTelemetryBuilder, telemetryOptions);
        ConfigureMetrics(openTelemetryBuilder, telemetryOptions);

        return services;
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
                // Попытка по-форсу: если endpoint не абсолютный, просто подключаем экспортёр без явного Endpoint
                // (в этом случае экспортёр может считывать настройки из переменных окружения)
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
                // То же поведение для метрик: если URI не абсолютный, подключаем экспортёр без явного endpoint
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

