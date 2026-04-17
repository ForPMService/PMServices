using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace PM.Platform.Infrastructure.Redis;

public static class RedisServiceCollectionExtensions
{
    public static IServiceCollection AddRedisToService(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<RedisOptions>()
        .Bind(configuration.GetSection(RedisOptions.SectionName))
        .Validate(
            IsRedisOptionsInvalid,
            $"В разделе конфигурации '{RedisOptions.SectionName}' должна содержаться непустая строка подключения")
        .ValidateOnStart();

        services.AddSingleton<IConnectionMultiplexer>(CreateRedisConnection);

        return services;


    }

    private static IConnectionMultiplexer CreateRedisConnection(IServiceProvider serviceProvider)
    {
        RedisOptions options = serviceProvider
            .GetRequiredService<IOptions<RedisOptions>>()
            .Value;

        return ConnectionMultiplexer.Connect(options.ConnectionString);
    }

    private static bool IsRedisOptionsInvalid(RedisOptions options)
    {
        return !string.IsNullOrEmpty(options.ConnectionString);
    }
}
