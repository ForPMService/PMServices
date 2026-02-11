using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

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
