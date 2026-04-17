using Microsoft.AspNetCore.HttpOverrides;
using PM.Platform.Infrastructure;
using PM.Platform.Infrastructure.Redis;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRedisToService(builder.Configuration);
builder.Services.AddHealthCheckToService(builder.Configuration);
builder.Services.AddObservabilityToService(builder.Configuration);
// Важно для reverse-proxy (Nginx edge): корректные scheme/host в редиректах и логах
builder.Services.Configure<ForwardedHeadersOptions>(o =>
{
    o.ForwardedHeaders = ForwardedHeaders.XForwardedFor
                       | ForwardedHeaders.XForwardedProto
                       | ForwardedHeaders.XForwardedHost;

    // В dev-контуре доверяем proxy в docker-сети.
    o.KnownIPNetworks.Clear();
    o.KnownProxies.Clear();
});

var app = builder.Build();

app.UseForwardedHeaders();

// Liveness
app.MapGet("/health", () => Results.Text("ok\n", "text/plain"));

// Дальше появятся:
// - cookie session + CSRF
// - /auth/* маршруты OIDC через Keycloak (не напрямую наружу)
// - proxy action links (verify/reset) через whitelist
// - /api/* проксирование в IAM backend и дальше в модули
app.Run();
