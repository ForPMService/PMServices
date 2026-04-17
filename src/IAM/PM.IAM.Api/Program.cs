using PM.Platform.Infrastructure;
using PM.Platform.Infrastructure.Redis;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;

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

// Liveness: no dependency checks
app.MapHealthChecks("/health", new HealthCheckOptions { Predicate = _ => false });

// Readiness: include dependency checks (e.g. Redis tagged as "ready")
app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = r => r.Tags.Contains("ready") });

app.Run();
