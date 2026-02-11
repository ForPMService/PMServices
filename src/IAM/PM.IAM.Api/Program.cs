var builder = WebApplication.CreateBuilder(args);

// Минимальный каркас. Дальше тут появятся:
// - DI для Data Layer (Postgres/Redis)
// - Keycloak admin adapter
// - authz/RBAC middleware (внутри IAM API)
builder.Services.AddRouting();

var app = builder.Build();

// Liveness: процесс жив
app.MapGet("/health", () => Results.Text("ok\n", "text/plain"));

// Readiness: позже здесь будут проверки БД/Redis/Keycloak-доступности
app.MapGet("/health/ready", () => Results.Text("ready\n", "text/plain"));

app.Run();
