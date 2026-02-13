# Фаза 0 — Покрытие план vs. инфра-пакет

**Легенда:**
- ✅ **В пакете** — файл/конфиг есть в `infra-package.tar.gz`
- 🔧 **Ты руками** — нужно написать C# код / dotnet-специфичное
- ⏳ **Не покрыто** — не в пакете и не C# (пропущено / на потом)

---

## Шаг 1. Baseline + .gitignore

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 1.1 | Baseline smoke (curl /, /admin/, /health) | 🔧 | Это **проверка**, не файл. Команды есть в GUIDE_INFRA.md §4 |
| 1.2 | `.gitignore` | ✅ | В пакете |

---

## Шаг 2. Каркас платформы и сервисов

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 2.1 | `Directory.Build.props` | ✅ | net10.0, Nullable, ImplicitUsings, TreatWarningsAsErrors |
| 2.2 | PM.Platform.Core (IEntity, CQRS, Behaviors, Exceptions) | 🔧 | **C# код — кодишь сам** |
| 2.3 | PM.Platform.Infrastructure (Redis, OTel, HealthChecks extensions) | 🔧 | **C# код — кодишь сам** |
| 2.4 | PM.Platform.Contracts (common.proto) | 🔧 | **C# код — кодишь сам** |
| 2.5 | PM.IAM.Contracts (iam.proto) | 🔧 | **C# код — кодишь сам** |
| 2.6 | PM.IAM.Domain (Entities, ValueObjects, Events, Enums) | 🔧 | **C# код — кодишь сам** |
| 2.7 | PM.IAM.Application (Commands, Queries, Services) | 🔧 | **C# код — кодишь сам** |
| 2.8 | PM.IAM.Infrastructure (пустые папки) | 🔧 | **C# код — кодишь сам** |
| 2.9 | PM.BFF/Program.cs (OTel, /health, /health/ready) | 🔧 | **C# код — кодишь сам.** Минимальный пример в GUIDE_INFRA.md §2 |
| 2.10 | PM.IAM.Api/Program.cs (OTel, /health, /health/ready) | 🔧 | **C# код — кодишь сам.** Минимальный пример в GUIDE_INFRA.md §2 |

---

## Шаг 3. Dockerfiles

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 3.1 | `src/BFF/PM.BFF/Dockerfile` | ✅ | Multi-stage: restore → publish → chiseled → dev |
| 3.2 | `src/IAM/PM.IAM.Api/Dockerfile` | ✅ | Аналогично |

---

## Шаг 4. Docker Compose: profiles, сети, healthchecks

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 4.1 | 4 сети (frontend-net, backend-net, db-net, observ-net) | ✅ | В compose.iam.yml |
| 4.2 | Profiles: infra, full | ✅ | |
| 4.3 | BFF и IAM API как build-сервисы (profile: full) | ✅ | |
| 4.4 | Edge без depends_on на BFF | ✅ | |
| 4.5 | Postgres/Redis порты только в dev-override | ✅ | compose.iam.dev.yml |
| 4.6 | Keycloak healthcheck (KC_HEALTH_ENABLED, /health/ready) | ✅ | |
| 4.7 | compose.iam.dev.yml (build target dev, volumes, debug ports) | ✅ | |
| 4.8 | Volumes: /var/lib/postgresql, ES, Grafana, Prometheus | ✅ | |
| 4.9 | Nginx default.conf — Keycloak закрыт, catch-all → BFF | ✅ | |

---

## Шаг 5. Edge hardening

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 5.1 | Security headers (X-Frame, X-Content-Type, Referrer, Permissions, server_tokens off) | ✅ | В nginx/default.conf |
| 5.2 | CSP + Trusted Types | ✅ | `map $uri $csp_header` + `require-trusted-types-for 'script'` |
| 5.3 | `/invite` → BFF (явный location) | ✅ | |
| 5.4 | Sane defaults (client_max_body_size, timeouts) | ✅ | |
| 5.5 | TLS — два конфига (default.conf + ssl.conf) | ✅ | ssl.conf = prod stub |

---

## Шаг 6. Keycloak: health/metrics, provisioning

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 6.1 | Версия 26.4.7 в .env.iam | ✅ | `KEYCLOAK_IMAGE=quay.io/keycloak/keycloak:26.4.7` |
| 6.2 | KC_HEALTH_ENABLED + KC_METRICS_ENABLED | ✅ | В compose |
| 6.3 | postgres-kc + mailpit | ✅ | |
| 6.4 | keycloak-config-cli (one-shot, idempotent, realm + client) | ✅ | `keycloak-init` сервис + `realm-pmplatform.json` |
| 6.5 | KC_HOSTNAME = публичный домен (Edge) | ✅ | `KC_HOSTNAME: "http://localhost:${EDGE_HTTP_PORT}"` |

---

## Шаг 7. Observability stack

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 7.1 | OTel Collector (config.yaml, compose, contrib-образ) | ✅ | **НО:** по плану Collector экспортирует **только логи и трейсы** в ES. В моём config.yaml он также экспортирует метрики через Prometheus exporter. **Решение:** можно убрать metrics pipeline из Collector если хочешь strict соответствие плану. Prometheus всё равно scrape'ит BFF/IAM напрямую — это основной путь метрик. |
| 7.2 | Elasticsearch (single-node, volume) | ✅ | |
| 7.2a | ILM политика (retention) | ⏳ **НЕ СДЕЛАНО** | Нужно добавить index templates + ILM policy в ES. Можно через init-скрипт аналогично Kibana |
| 7.2b | Index templates (ECS + trace.id, span.id) | ⏳ **НЕ СДЕЛАНО** | Аналогично — через init-скрипт |
| 7.3 | Kibana (compose, observ-net + frontend-net) | ✅ | |
| 7.3a | Kibana provisioning (saved objects + init script) | ✅ | init.sh + saved-objects.ndjson |
| 7.3b | Views: error_code фильтрация, trace.id корреляция | ⏳ **ЧАСТИЧНО** | Data views созданы (otel-logs, otel-traces). Но нет **предустановленных search/filter** по error_code — это делается руками в Kibana Discover |
| 7.4 | Prometheus (scrape BFF, IAM, KC, OTel) | ✅ | prometheus.yml с 4 targets |
| 7.5 | Grafana datasources (provisioned) | ✅ | Prometheus + 2× Elasticsearch |
| 7.5a | Grafana dashboards (provisioned, JSON в репо) | ✅ | iam-overview.json (rate, latency p95, 5xx, up) |
| 7.5b | Шаблоны алертов | ⏳ **НЕ СДЕЛАНО** | Grafana alerting rules не включены |
| 7.6 | Версии образов в .env.iam.example | ✅ | |
| 7.7 | **Валидация трейсов (блокер!)** | 🔧 | Требует работающий BFF с OTel SDK. Это можно проверить **только после** написания C# кода с OTel инструментацией |

---

## Шаг 8. Тестовый каркас

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 8.1 | xUnit проекты (Core.Tests, Domain.Tests, Application.Tests, BFF.Tests) | 🔧 | **C# код — кодишь сам** |
| 8.2 | Smoke-тесты (DI host стартует) | 🔧 | **C# код — кодишь сам** |
| 8.3 | Добавить в PMPlatform.slnx | 🔧 | **Ты сам** |

---

## Шаг 9. Документация и соглашения

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 9.1 | `docs/observability-conventions.md` | ✅ | Покрывает: service.name, trace correlation, metric namespace, log format, span naming |
| 9.1a | WBS 8.1.1 — формат логов JSON+ECS | ✅ | В документе, секция 4 |
| 9.1b | WBS 8.1.2 — trace_id в error responses | ✅ | В документе, секция 2 |
| 9.1c | WBS 8.1.3 — контракт iam_errors_total | ✅ | В документе, секция 3 |
| 9.1d | WBS 8.1.4 — PII маскировка | ⏳ **НЕ ПОКРЫТО** | Упомянуто вскользь, нет детальной политики |
| 9.1e | WBS 8.1.5 — конвенции лейблов | ✅ | В документе, секция 3 |
| 9.1f | WBS 8.1.6 — контракт событийных логов (Invite) | ⏳ **НЕ ПОКРЫТО** | Нет детального описания INVITATION_SENT полей |
| 9.2 | ADR update (Keycloak закрыт, WBS 1.2.4-1.2.9 → Фаза 3) | ⏳ **НЕ СДЕЛАНО** | Нужно обновить ADR документ и Deploy Guide |
| 9.3 | README.md (quick start) | ⏳ **НЕ СДЕЛАНО** | |
| 9.4 | .env.iam.example с observability переменными | ✅ | |

---

## Шаг 10. Минимальный CI (опционально)

| Подпункт | Описание | Статус | Комментарий |
|----------|----------|--------|-------------|
| 10.1 | CI pipeline (dotnet build + test) | ⏳ | Опционально, не Exit Criteria |

---

## Шаг 11. Финальная приёмка (Exit Criteria)

| Критерий | Что нужно | Из пакета? | Что доделать? |
|----------|-----------|------------|---------------|
| compose --profile full up -d без ошибок | compose.iam.yml | ✅ | Нужен Program.cs в BFF и IAM API |
| Все сервисы healthy | healthchecks | ✅ | |
| Keycloak не публикуется | compose (нет ports) | ✅ | |
| 4 сети | compose | ✅ | |
| `/` → 200 | nginx | ✅ | |
| `/health` → 200 через BFF | nginx + BFF | 🔧 | Нужен Program.cs с /health |
| `/admin/` → 403 | nginx | ✅ | |
| `/realms/.../token` → 403 | nginx | ✅ | |
| `/invite` маршрут | nginx | ✅ | |
| Security headers + CSP | nginx | ✅ | |
| Нет proxy_pass на keycloak | nginx | ✅ | |
| TLS ssl.conf подключаемый | ssl.conf | ✅ | |
| KC 26.4.7 | compose | ✅ | |
| Provisioning идемпотентно | keycloak-init | ✅ | |
| Realm + client exist | realm-pmplatform.json | ✅ | |
| Prometheus targets UP | prometheus.yml | ✅ (конфиг) | Нужен /metrics в BFF/IAM |
| Grafana дашборды | provisioning + JSON | ✅ | |
| Kibana saved objects | init.sh + ndjson | ✅ | |
| ES данные + ILM | compose + **нет ILM** | ⏳ | ILM/templates не сделаны |
| Trace виден по trace.id | — | 🔧 | Нужен OTel SDK в C# |
| observability-conventions.md | docs/ | ✅ | |
| `dotnet build` — 0 ошибок | — | 🔧 | Нужен весь C# каркас |
| `dotnet test` — 0 failures | — | 🔧 | Нужны xUnit проекты |
| ADR обновлён | — | ⏳ | Не сделано |
| Deploy Guide актуализирован | — | ⏳ | Не сделано |

---

## Сводка

### Что в пакете (✅):

| Шаг | Покрытие |
|-----|----------|
| Шаг 1 (.gitignore) | **100%** |
| Шаг 2 (каркас) | **Directory.Build.props только** — 1/10 |
| Шаг 3 (Dockerfiles) | **100%** |
| Шаг 4 (Compose) | **100%** |
| Шаг 5 (Edge hardening) | **100%** |
| Шаг 6 (Keycloak) | **100%** |
| Шаг 7 (Observability) | **~80%** — нет ILM, index templates, алертов |
| Шаг 8 (Тесты) | **0%** — C# код |
| Шаг 9 (Документация) | **~50%** — conventions есть, ADR/README нет |

### Что осталось за тобой (🔧 C# код):

1. **Шаг 2 целиком** (кроме Directory.Build.props): Platform.Core, Platform.Infrastructure, Contracts, IAM.Domain, IAM.Application, IAM.Infrastructure, BFF/Program.cs, IAM.Api/Program.cs
2. **Шаг 8 целиком**: xUnit проекты, smoke-тесты
3. **Шаг 7.7**: валидация трейсов (нужен работающий OTel SDK в C#)

### Что пропущено и нужно доделать (⏳):

1. **ES ILM политика + index templates** (Шаг 7.2a, 7.2b) — init-скрипт для ES по аналогии с Kibana
2. **Grafana шаблоны алертов** (Шаг 7.5b)
3. **Observability conventions: PII маскировка, событийные логи** (Шаг 9.1d, 9.1f)
4. **ADR update** (Шаг 9.2) — зафиксировать решение «KC закрыт»
5. **README.md** (Шаг 9.3)
