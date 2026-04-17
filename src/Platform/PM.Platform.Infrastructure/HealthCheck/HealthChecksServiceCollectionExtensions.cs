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

        // Если в IServiceCollection зарегистрирован IConnectionMultiplexer, добавляем простую health-проверку для Redis.
        // ПРИМЕЧАНИЕ: это зависит от порядка регистрации — проверка Redis будет добавлена только в том случае,
        // если AddRedisToService был вызван раньше, чем AddHealthCheckToService.
        bool hasRedis = service.Any(sd => sd.ServiceType == typeof(IConnectionMultiplexer));
        if (hasRedis)
        {
            // Пометим проверку redis тегом "ready", чтобы readiness endpoint мог её отфильтровать.
            healthChecksBuilder.AddCheck<RedisHealthCheck>("redis", tags: new[] { "ready" });
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
            // PingAsync в StackExchange.Redis не принимает CancellationToken, вызываем без токена.
            await db.PingAsync().ConfigureAwait(false);
            return HealthCheckResult.Healthy();
        }
        catch
        {
            return HealthCheckResult.Unhealthy();
        }
    }
}
