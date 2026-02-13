# Observability Conventions — PM Platform

**Версия:** 1.0  
**Дата:** 2026-02-12  

---

## 1. Имена сервисов (OTel `service.name`)

| Сервис     | service.name | Переменная в compose                |
|------------|--------------|-------------------------------------|
| BFF        | `pm-bff`     | `Otel__ServiceName=pm-bff`          |
| IAM API    | `pm-iam-api` | `Otel__ServiceName=pm-iam-api`      |

Паттерн: `pm-{module}[-{layer}]`.  
При добавлении новых сервисов — следовать паттерну.

---

## 2. Traces

### 2.1 Контекст

Все .NET сервисы используют W3C Trace Context (propagator по умолчанию).  
Каждый запрос получает `traceparent` header автоматически.

### 2.2 Span naming

- HTTP: `{HTTP_METHOD} {route}` (автоматически через ASP.NET instrumentation)
- gRPC: `{package}.{service}/{method}`
- Custom spans: `{module}.{operation}` — например `iam.check-permission`

### 2.3 Semantic attributes

Обязательные (по OTel Semantic Conventions):
- `service.name` — автоматически
- `service.version` — из AssemblyVersion
- `deployment.environment` — добавляется Collector (processor attributes/env)

Кастомные для IAM:
- `iam.org_id` — ID организации (на span'ах, где есть org контекст)
- `iam.user_id` — ID пользователя (если доступен из сессии)

---

## 3. Metrics

### 3.1 Namespace

Все кастомные метрики — с prefix `pm_`. Пример: `pm_invitation_created_total`.

OTel SDK автоматически экспортирует:
- `http.server.request.duration` (histogram)
- `http.server.active_requests` (up-down counter)
- `aspnetcore.routing.match_attempts` (counter)

Collector добавляет `pm_` prefix через `exporters.prometheus.namespace`.

### 3.2 Prometheus scrape endpoints

| Target           | URL                            | Job name         |
|------------------|--------------------------------|------------------|
| OTel Collector   | `otel-collector:8889/metrics`  | `otel-collector` |
| BFF              | `bff:8080/metrics`             | `bff`            |
| IAM API          | `iam-api:8080/metrics`         | `iam-api`        |
| Keycloak         | `keycloak:8080/metrics`        | `keycloak`       |

---

## 4. Logs

### 4.1 Формат

Structured JSON через OTel OTLP exporter → Collector → Elasticsearch.

Поля (ECS-aligned):
- `@timestamp` — время события
- `severity_text` — `Information`, `Warning`, `Error`, `Critical`
- `body` — сообщение
- `resource.service.name` — сервис
- `trace_id`, `span_id` — корреляция с трейсами

### 4.2 Elasticsearch indexes

| Index          | Содержимое              | Kibana Data View |
|----------------|-------------------------|------------------|
| `otel-logs*`   | Логи от всех сервисов   | `otel-logs`      |
| `otel-traces*` | Span'ы трейсов          | `otel-traces`    |

---

## 5. Dashboards

### 5.1 Grafana

| Dashboard          | Описание                               |
|--------------------|----------------------------------------|
| IAM Platform Overview | HTTP rate, P95 latency, 5xx rate, up |

Дашборды auto-provisioned из `ops/iam/observability/grafana/dashboards/`.  
Добавлять новые — просто класть `.json` в эту папку.

### 5.2 Kibana

Data Views создаются автоматически через `kibana-init` контейнер.  
Для поиска логов: Kibana → Discover → выбрать `otel-logs`.

---

## 6. Как добавить метрику/трейс в .NET коде

```csharp
// Метрика (в конструкторе или DI)
private static readonly Meter Meter = new("PM.IAM");
private static readonly Counter<long> InvitationCounter = 
    Meter.CreateCounter<long>("pm_invitation_created", "invitations", "Total invitations created");

// В handler'e
InvitationCounter.Add(1, new KeyValuePair<string, object?>("org_id", orgId.ToString()));

// Трейс (кастомный span)
using var activity = ActivitySource.StartActivity("iam.create-invitation");
activity?.SetTag("iam.org_id", orgId.ToString());
```
