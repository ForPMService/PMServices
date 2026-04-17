using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace PM.Platform.Infrastructure;

public static class HealthChecksServiceCollectionExtensions
{
    public static IServiceCollection AddHealthCheckToService (this IServiceCollection service, IConfiguration configuration)
    {
        service.AddHealthChecks();
        return service;
    }

}
