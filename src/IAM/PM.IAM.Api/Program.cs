using PM.Platform.Infrastructure;
using PM.Platform.Infrastructure.Redis;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRedisToService(builder.Configuration);
builder.Services.AddHealthCheckToService(builder.Configuration);
builder.Services.AddObservabilityToService(builder.Configuration);
// Минимальный каркас. Дальше тут появятся:
// - DI для Data Layer (Postgres/Redis)
// - Keycloak admin adapter
// - authz/RBAC middleware (внутри IAM API)
builder.Services.AddRouting();



var app = builder.Build();

// Liveness: процесс жив
app.MapHealthChecks("/health");

// Readiness (пока будет тот же набор проверок)
app.MapHealthChecks("/health/ready");

app.Run();
