using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System.Linq;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using StackExchange.Redis;
using System.Threading;
using System.Threading.Tasks;

namespace PM.Platform.Infrastructure;

public static class HealthChecksServiceCollectionExtensions
{
    public static IServiceCollection AddHealthCheckToService (this IServiceCollection service, IConfiguration configuration)
    {
        var healthChecksBuilder = service.AddHealthChecks();

        // If Redis connection multiplexer is registered we add a simple health check for it.
        bool hasRedis = service.Any(sd => sd.ServiceType == typeof(IConnectionMultiplexer));
        if (hasRedis)
        {
            healthChecksBuilder.AddCheck<RedisHealthCheck>("redis");
        }

        return service;
    }

}

internal class RedisHealthCheck : IHealthCheck
{
    private readonly IConnectionMultiplexer _redis;

    public RedisHealthCheck(IConnectionMultiplexer redis)
    {
        _redis = redis;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var db = _redis.GetDatabase();
            await db.PingAsync().WaitAsync(cancellationToken).ConfigureAwait(false);
            return HealthCheckResult.Healthy();
        }
        catch
        {
            return HealthCheckResult.Unhealthy();
        }
    }
}
