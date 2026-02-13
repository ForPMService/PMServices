# Infrastructure Package — Гайд

**Дата:** 2026-02-12  
**Scope:** Только инфра + observability. Ноль C# доменного/прикладного кода.

---

## 1. Карта файлов (18 штук)

| # | Путь в PMServices/ | Действие | Описание |
|---|-------------------|----------|----------|
| 1 | `.gitignore` | **CREATE** | bin/, obj/, .env.iam, elastic-data/, etc. |
| 2 | `Directory.Build.props` | **REPLACE** | net10.0, Nullable, ImplicitUsings, TreatWarningsAsErrors |
| 3 | `ops/iam/.env.iam.example` | **REPLACE** | Все переменные вкл. observability images/ports |
| 4 | `ops/iam/compose.iam.yml` | **REPLACE** | Полный compose: 4 сети, profiles infra/full, observability stack |
| 5 | `ops/iam/compose.iam.dev.yml` | **CREATE** | Dev overlay: hot reload, debug ports, nuget cache |
| 6 | `ops/iam/nginx/default.conf` | **REPLACE** | Security headers (CSP, X-Frame, etc.), catch-all → BFF, /admin/ → 403, token endpoint → 403 |
| 7 | `ops/iam/nginx/ssl.conf` | **CREATE** | TLS 1.3 заглушка для prod (закомментирована) |
| 8 | `ops/iam/keycloak/realm-pmplatform.json` | **CREATE** | Realm pmplatform + bff-client (OIDC confidential) + SMTP via mailpit |
| 9 | `ops/iam/observability/otel-collector/config.yaml` | **CREATE** | OTLP gRPC/HTTP → batch → Elasticsearch (logs/traces) + Prometheus (metrics) |
| 10 | `ops/iam/observability/prometheus/prometheus.yml` | **CREATE** | Scrape: otel-collector, bff, iam-api, keycloak |
| 11 | `ops/iam/observability/grafana/provisioning/datasources/datasources.yaml` | **CREATE** | Auto-provision: Prometheus + 2× Elasticsearch |
| 12 | `ops/iam/observability/grafana/provisioning/dashboards/dashboards.yaml` | **CREATE** | Dashboard provider из /var/lib/grafana/dashboards |
| 13 | `ops/iam/observability/grafana/dashboards/iam-overview.json` | **CREATE** | Стартовый дашборд: HTTP rate, P95 latency, 5xx, container up |
| 14 | `ops/iam/observability/kibana/init.sh` | **CREATE** | Wait-for-kibana + import saved objects |
| 15 | `ops/iam/observability/kibana/saved-objects.ndjson` | **CREATE** | Data views: otel-logs*, otel-traces* |
| 16 | `src/BFF/PM.BFF/Dockerfile` | **CREATE** | Multi-stage: restore → publish → chiseled runtime → dev (dotnet watch) |
| 17 | `src/IAM/PM.IAM.Api/Dockerfile` | **CREATE** | Multi-stage: restore → publish → chiseled runtime → dev (dotnet watch) |
| 18 | `docs/observability-conventions.md` | **CREATE** | Конвенции: service.name, span naming, metric namespace, log format |

---

## 2. Что тебе нужно сделать руками (C# код)

Этот пакет **не включает** C# код (кроме Directory.Build.props). Вот минимум, чтобы инфра-контейнеры BFF/IAM-API стартовали:

### PM.BFF/Program.cs — минимальный каркас

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/health", () => Results.Text("ok"));
app.MapGet("/metrics", () => Results.Text("# placeholder"));

app.Run();
```

### PM.IAM.Api/Program.cs — минимальный каркас

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/health", () => Results.Text("ok"));
app.MapGet("/metrics", () => Results.Text("# placeholder"));

app.Run();
```

Этого достаточно для `dotnet build` и docker build. Потом сам расширишь OTel, health checks, DI и т.д.

### csproj — минимальные

BFF и IAM API csproj должны быть `<Project Sdk="Microsoft.NET.Sdk.Web">` без дополнительных зависимостей на старте. `Directory.Build.props` задаёт `net10.0`.

---

## 3. Как развернуть и проверить

### 3.1 Подготовка

```powershell
# Из корня PMServices/
cp ops\iam\.env.iam.example ops\iam\.env.iam
# (опционально поменяй пароли в .env.iam)
```

### 3.2 Вариант A: Только инфраструктура (без .NET сервисов)

```powershell
docker compose -f ops\iam\compose.iam.yml --env-file ops\iam\.env.iam --profile infra up -d
```

Это поднимет: edge, postgres-iam, postgres-kc, redis, mailpit, keycloak, otel-collector, elasticsearch, kibana, kibana-init, prometheus, grafana.

### 3.3 Вариант B: Полный стек (с .NET сервисами)

```powershell
# Сначала убедись что dotnet build работает
dotnet build PMPlatform.slnx

# Потом
docker compose -f ops\iam\compose.iam.yml --env-file ops\iam\.env.iam --profile full up -d
```

### 3.4 Вариант C: Dev с hot reload

```powershell
docker compose -f ops\iam\compose.iam.yml -f ops\iam\compose.iam.dev.yml --env-file ops\iam\.env.iam --profile full up -d
```

---

## 4. Чек-лист проверки

Выполни последовательно. Каждый пункт = конкретная команда и ожидаемый результат.

### 4.1 Контейнеры поднялись

```powershell
docker compose -f ops\iam\compose.iam.yml --env-file ops\iam\.env.iam --profile infra ps
```
**Ожидание:** все сервисы в `Up` или `Up (healthy)`. Keycloak может стартовать 30-60 сек.

### 4.2 Edge отвечает

```powershell
curl.exe -s http://localhost:8090/
```
**Ожидание:** `edge ok`

### 4.3 /admin/ заблокирован

```powershell
curl.exe -s -o NUL -w "%{http_code}" http://localhost:8090/admin/
```
**Ожидание:** `403`

### 4.4 Token endpoint заблокирован

```powershell
curl.exe -s -o NUL -w "%{http_code}" http://localhost:8090/realms/pmplatform/protocol/openid-connect/token
```
**Ожидание:** `403`

### 4.5 Security headers

```powershell
curl.exe -s -I http://localhost:8090/ | findstr /I "X-Frame Content-Security Referrer Permissions X-Content"
```
**Ожидание:** 5 заголовков: X-Frame-Options: DENY, Content-Security-Policy: ..., X-Content-Type-Options: nosniff, Referrer-Policy: strict-origin-when-cross-origin, Permissions-Policy: camera=()...

### 4.6 Keycloak НЕ опубликован наружу

```powershell
docker ps --format "table {{.Names}}\t{{.Ports}}" | findstr keycloak
```
**Ожидание:** `pm-keycloak` БЕЗ `0.0.0.0:xxxx->` в столбце Ports.

### 4.7 PostgreSQL healthy

```powershell
docker inspect pm-postgres-iam --format "{{.State.Health.Status}}"
docker inspect pm-postgres-kc --format "{{.State.Health.Status}}"
```
**Ожидание:** `healthy` для обоих.

### 4.8 Redis healthy

```powershell
docker inspect pm-redis --format "{{.State.Health.Status}}"
```
**Ожидание:** `healthy`

### 4.9 Keycloak healthy + realm создан

```powershell
docker inspect pm-keycloak --format "{{.State.Health.Status}}"
```
**Ожидание:** `healthy`

```powershell
# Проверить что keycloak-init отработал
docker logs pm-keycloak-init 2>&1 | findstr -i "import"
```
**Ожидание:** сообщения об успешном импорте realm pmplatform.

### 4.10 Mailpit Web UI

Открой в браузере: `http://localhost:8026`  
**Ожидание:** интерфейс Mailpit (пустой inbox).

### 4.11 OTel Collector работает

```powershell
docker logs pm-otel-collector 2>&1 | findstr -i "everything is ready"
```
**Ожидание:** лог "Everything is ready" или аналогичный.

### 4.12 Elasticsearch healthy

```powershell
docker exec pm-elasticsearch curl -sf http://localhost:9200/_cluster/health?pretty
```
**Ожидание:** JSON с `"status" : "green"` (или `"yellow"` для single-node).

### 4.13 Kibana UI + Data Views

Открой: `http://localhost:5601`  
Перейди в **Discover** → проверь что есть data views `otel-logs*` и `otel-traces*`.

### 4.14 Prometheus targets

Открой: `http://localhost:9090/targets`  
**Ожидание:** 4 targets (otel-collector, bff, iam-api, keycloak). `bff` и `iam-api` будут DOWN пока .NET сервисы не запущены — это нормально.

### 4.15 Grafana UI + Datasources

Открой: `http://localhost:3000` (admin / admin)  
Перейди в **Connections → Data Sources**.  
**Ожидание:** 3 datasources: Prometheus, Elasticsearch-Logs, Elasticsearch-Traces.  
Перейди в **Dashboards → PMPlatform → IAM Platform Overview**.  
**Ожидание:** дашборд загружается (данные появятся когда .NET сервисы заработают).

### 4.16 (Только profile full) BFF через Edge

```powershell
curl.exe -s http://localhost:8090/health
```
**Ожидание:** `ok` (502 если BFF не поднят).

---

## 5. Покрытие WBS и Плана

### Фаза 0 — Exit Criteria из Roadmap v1.2:

| Критерий | Статус | Примечание |
|----------|--------|------------|
| CSP/TLS настроены | ✅ CSP готов, TLS stub для prod | CSP через nginx map, TLS = ssl.conf (prod) |
| OTel Collector работает | ✅ | config.yaml + compose service |
| Prometheus scrapes /metrics | ✅ | prometheus.yml + 4 targets |
| Grafana дашборды | ✅ | Auto-provisioned datasources + starter dashboard |
| Keycloak недоступен снаружи | ✅ | Нет ports, /admin/ → 403, token → 403 |

### WBS секция 1 — ИНФРАСТРУКТУРА И РАЗВЁРТЫВАНИЕ:

| WBS ID | Задача | Статус |
|--------|--------|--------|
| **1.1.1** | compose.iam.yml | ✅ |
| **1.1.2** | .env.iam | ✅ (.env.iam.example) |
| **1.1.3** | Edge (Nginx) | ✅ |
| **1.1.4** | Volume PostgreSQL IAM | ✅ (iam_pgdata:/var/lib/postgresql) |
| **1.1.5** | Volume PostgreSQL Keycloak | ✅ (kc_pgdata:/var/lib/postgresql) |
| **1.1.6** | Redis 8 | ✅ |
| **1.1.7** | Mailpit | ✅ |
| **1.2.1** | /health → BFF | ✅ (catch-all → bff) |
| **1.2.2** | /auth/* → BFF | ✅ (catch-all → bff) |
| **1.2.3** | /api/* → BFF | ✅ (catch-all → bff) |
| **1.2.4–1.2.7, 1.2.9** | Keycloak whitelist | ⏳ **ОСОЗНАННО НЕ СДЕЛАНО** — по ADR 4.7 всё идёт через BFF proxy (Фаза 3). Edge не проксирует KC напрямую. |
| **1.2.8** | /admin/ → 403 | ✅ |
| **1.2.10** | /invite → BFF | ✅ (явный location) |
| **1.2.11** | CSP + Trusted Types | ✅ |
| **1.2.12** | TLS 1.3 (prod) | ✅ (ssl.conf stub) |
| **1.2.13** | Token endpoint → 403 | ✅ |
| **1.2.14** | Security headers baseline | ✅ (X-Frame, X-Content-Type, Referrer, Permissions) |
| **1.3.1** | Keycloak 26.4.7 | ✅ |
| **1.3.2** | KC → отдельная PostgreSQL | ✅ |
| **1.3.3** | KC не публикуется | ✅ |
| **1.4.1–1.4.6** | DoD развёртывания | ✅ (чек-лист выше = команды проверки) |
| **1.5.1** | OTel Collector | ✅ |
| **1.5.2** | Elasticsearch | ✅ |
| **1.5.3** | Kibana | ✅ + init скрипт |
| **1.5.4** | Prometheus | ✅ |
| **1.5.5** | Grafana | ✅ + provisioning |
| **1.5.6** | Базовые дашборды | ✅ (iam-overview.json) |
| **1.5.7** | Базовые алерты | ⏳ НЕ СДЕЛАНО — алерты имеют смысл когда метрики реально текут |
| **1.6.7** | Dockerfile IAM API | ✅ |
| **1.6.8** | Dockerfile BFF | ✅ |
| **1.6.9** | compose build context | ✅ |
| **1.6.10** | Profiles infra/full | ✅ |

### WBS секция 8 — OBSERVABILITY:

| WBS ID | Задача | Статус |
|--------|--------|--------|
| **8.1.5** | Конвенции метрик/лейблов | ✅ (docs/observability-conventions.md) |
| **8.5.1** | Grafana datasources | ✅ |
| **8.5.3** | Dashboard: Latency (p95) | ✅ (iam-overview.json) |

### Что осталось за тобой (C# / .NET):

| WBS ID | Задача | Описание |
|--------|--------|----------|
| **1.6.1** | Solution PMPlatform.slnx | Уже есть в репо |
| **1.6.2** | PM.Platform.Core | Базовые абстракции — кодишь сам |
| **1.6.3** | PM.Platform.Infrastructure | Redis, OTel SDK, HealthChecks — кодишь сам |
| **1.6.4** | PM.Platform.Contracts | common.proto — кодишь сам |
| **1.6.4a** | PM.IAM.Contracts | iam.proto — кодишь сам |
| **1.6.5** | PM.IAM.Api каркас | Program.cs + /health + OTel + DI — кодишь сам |
| **1.6.6** | PM.BFF каркас | Program.cs + /health + OTel + DI — кодишь сам |
| **8.1.1–8.1.4, 8.1.6** | OTel SDK инструментация в .NET | Кодишь сам |
| **8.2.1–8.2.5** | OTel SDK подключение | Кодишь сам |
| Весь домен/приложение | PM.IAM.Domain, PM.IAM.Application | UUIDv7, entities, CQRS — кодишь сам |

---

## 6. Итого — что закрыто при прохождении проверки

При прохождении чек-листа (раздел 4) считаются **закрытыми 28 задач WBS**:

- **1.1 Docker-окружение:** 7/7 ✅
- **1.2 Nginx Edge:** 8/14 ✅ (6 whitelist KC сознательно отложены на Фазу 3)
- **1.3 Keycloak контейнер:** 3/3 ✅
- **1.4 DoD развёртывания:** 6/6 ✅
- **1.5 Observability stack:** 6/7 ✅ (алерты отложены)
- **1.6 Каркас (только Dockerfile/compose):** 4/10 ✅ (остальное = C# код)

**Roadmap Фаза 0 exit criteria: 5/5 ✅** — при прохождении проверки Фаза 0 считается инфраструктурно завершённой. Тебе останется добавить C# каркасы (Program.cs с /health и OTel SDK) чтобы полностью закрыть 1.6.
