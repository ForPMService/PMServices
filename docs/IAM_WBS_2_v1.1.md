# IAM Module — Work Breakdown Structure (WBS)

**Версия:** 1.1  
**Дата:** 24.01.2026  
**Статус:** Актуальный (патчи v1.1 применены)

---

## Условные обозначения

| Статус | Описание |
|--------|----------|
| ✅ DONE1 | Выполнено |
| 🔄 IN PROGRESS | В работе |
| ⏳ TODO | Запланировано |
| 🔒 BLOCKED | Заблокировано |

---

# 1. ИНФРАСТРУКТУРА И РАЗВЁРТЫВАНИЕ

## 1.1 Docker-окружение 

| ID | Задача | Статус | Артефакт |
|----|--------|--------|----------|
| 1.1.1 | Создание docker-compose.iam.yml | ⏳ TODO| ops/iam/compose.iam.yml |
| 1.1.2 | Создание файла окружения .env.iam | ⏳ TODO| ops/iam/.env.iam |
| 1.1.3 | Конфигурация Edge (Nginx) | ⏳ TODO| ops/iam/nginx/default.conf |
| 1.1.4 | Настройка volume для PostgreSQL 18 IAM | ⏳ TODO| iam_pgdata |
| 1.1.5 | Настройка volume для PostgreSQL Keycloak | ⏳ TODO| kc_pgdata |
| 1.1.6 | Настройка Redis 8 | ⏳ TODO| Контейнер redis |
| 1.1.7 | Настройка Mailpit (SMTP для dev) | ⏳ TODO| Контейнер mailpit |

## 1.2 Nginx Edge Proxy 

| ID | Задача | Статус | Примечание |
|----|--------|--------|------------|
| 1.2.1 | Проксирование /health → BFF | ⏳ TODO| proxy_pass http://bff:8080/health |
| 1.2.2 | Проксирование /auth/* → BFF | ⏳ TODO| proxy_pass http://bff:8080 |
| 1.2.3 | Проксирование /api/* → BFF | ⏳ TODO| proxy_pass http://bff:8080 |
| 1.2.4 | Whitelist Keycloak /resources/ | ⏳ TODO| proxy_pass http://keycloak:8080 |
| 1.2.5 | Whitelist Keycloak /realms/.../protocol/openid-connect/auth | ⏳ TODO| Regex location |
| 1.2.6 | Whitelist Keycloak /realms/.../protocol/openid-connect/logout | ⏳ TODO| Regex location |
| 1.2.7 | Whitelist Keycloak /realms/.../login-actions/ | ⏳ TODO| Regex location |
| 1.2.8 | Блокировка /admin/ → 403 | ⏳ TODO| return 403 |
| 1.2.9 | Whitelist Keycloak /realms/.../protocol/openid-connect/registrations | ⏳ TODO| Regex location |
| 1.2.10 | Проксирование /invite → BFF | ⏳ TODO | Публичная точка входа для invite-link: GET /invite?token=... |
| 1.2.11 | CSP header + Trusted Types для SPA (SEC-CSP-001) | ⏳ TODO | Content-Security-Policy заголовком (не meta), как в security matrix |
| 1.2.12 | TLS policy (prod): TLS 1.3 only + strong ciphers | ⏳ TODO | Требования security matrix для Edge TLS |
| 1.2.13 | Явно запретить proxy браузера на Keycloak token endpoint | ⏳ TODO | /realms/{realm}/protocol/openid-connect/token → 403 (token endpoint только server-to-server) |
| 1.2.14 | Edge security headers baseline | ⏳ TODO | Минимум: X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy |


## 1.3 Keycloak (контейнер) 

| ID | Задача | Статус | Примечание |
|----|--------|--------|------------|
| 1.3.1 | Развёртывание Keycloak 26.4.7 | ⏳ TODO| quay.io/keycloak/keycloak:26.4.7 |
| 1.3.2 | Подключение к отдельной PostgreSQL | ⏳ TODO| postgres-kc:5432 |
| 1.3.3 | Keycloak НЕ публикуется наружу | ⏳ TODO| Нет ports в docker-compose |

## 1.4 Проверка Definition of Done развёртывания 

| ID | Задача | Статус | Команда проверки |
|----|--------|--------|------------------|
| 1.4.1 | docker compose up -d без ошибок | ⏳ TODO| docker compose -p iam ps |
| 1.4.2 | Edge отвечает 200 на / | ⏳ TODO| curl http://localhost:8090/ |
| 1.4.3 | /admin/ блокируется → 403 | ⏳ TODO| curl http://localhost:8090/admin/ |
| 1.4.4 | Keycloak не публикован (нет 0.0.0.0) | ⏳ TODO| docker ps --format |
| 1.4.5 | PostgreSQL 18 healthy | ⏳ TODO| docker compose -p iam ps |
| 1.4.6 | Redis healthy | ⏳ TODO| docker compose -p iam ps |

## 1.5 Observability stack (DEV/LOCAL)

| ID | Задача | Статус | Артефакт/Примечание |
|----|--------|--------|---------------------|
| 1.5.1 | OTel Collector (OTLP/gRPC 4317) | ⏳ TODO | ops/iam/otel-collector/config.yaml + compose.iam.yml |
| 1.5.2 | Elasticsearch (логи/трейсы) | ⏳ TODO | ops/iam/elastic/ (ilm, templates) + compose.iam.yml |
| 1.5.3 | Kibana | ⏳ TODO | compose.iam.yml |
| 1.5.4 | Prometheus (scrape /metrics) | ⏳ TODO | ops/iam/prometheus/prometheus.yml |
| 1.5.5 | Grafana (дашборды/алерты) | ⏳ TODO | ops/iam/grafana/ (datasources, dashboards) |
| 1.5.6 | Базовые дашборды (ошибки/латентность/сессии) | ⏳ TODO | Grafana JSON в репозитории |
| 1.5.7 | Базовые алерты из Error Catalog | ⏳ TODO | Prometheus rules / Grafana alerts |

## 1.6 Каркас сервисов (Фаза 0)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 1.6.1 | Создание .NET 10 solution PMPlatform.sln | ⏳ TODO | Единый solution для всей платформы |
| 1.6.2 | Проект PM.Platform.Core | ⏳ TODO | Базовые абстракции (IEntity, IRepository, CQRS) |
| 1.6.3 | Проект PM.Platform.Infrastructure | ⏳ TODO | Общая инфраструктура (Redis, OTel, HealthChecks) |
| 1.6.4 | Проект PM.Platform.Contracts | ⏳ TODO | ТОЛЬКО common.proto (общие типы: Timestamp, UUID, PagedRequest) |
| 1.6.4a | Проект PM.IAM.Contracts | ⏳ TODO | iam.proto (CheckPermission, GetUser), IAM-специфичные DTOs |
| 1.6.5 | Каркас PM.IAM.Api с /health | ⏳ TODO | ASP.NET Core Web API + Controllers |
| 1.6.6 | Каркас PM.BFF с /health | ⏳ TODO | ASP.NET Core Web API + Controllers |
| 1.6.7 | Dockerfile для PM.IAM.Api | ⏳ TODO | aspnet:10.0-noble-chiseled, non-root |
| 1.6.8 | Dockerfile для PM.BFF | ⏳ TODO | aspnet:10.0-noble-chiseled, non-root |
| 1.6.9 | Обновление compose.iam.yml (build context) | ⏳ TODO | Убрать плейсхолдеры, добавить build |
| 1.6.10 | Docker Compose profiles (infra/full) | ⏳ TODO | Режим разработки с IDE |

---

# 2. DATA LAYER (PostgreSQL + Redis)

## 2.1 Схема базы данных IAM

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 2.1.1 | Создание схемы `iam` | ⏳ TODO | CREATE SCHEMA iam; |
| 2.1.2 | Таблица `users` | ⏳ TODO | id, email, name, created_at, updated_at |
| 2.1.3 | Таблица `organizations` | ⏳ TODO | id, name, owner_id, settings, created_at |
| 2.1.4 | Таблица `memberships` | ⏳ TODO | user_id, org_id, role_id, joined_at |
| 2.1.5 | Таблица `roles` | ⏳ TODO | id, org_id, name, is_system, created_at |
| 2.1.6 | Таблица `privileges` | ⏳ TODO | id, code, name, description |
| 2.1.7 | Таблица `role_privileges` | ⏳ TODO | role_id, privilege_id |
| 2.1.8 | Таблица `invitations` | ⏳ TODO | id, org_id, email, token_hash (SHA-256; raw token не хранить), role_id, expires_at, status |
| 2.1.9 | Таблица `audit_log` | ⏳ TODO | id, org_id, actor_id, action, entity_type, entity_id, details, timestamp |
| 2.1.10 | Таблица `outbox_events` | ⏳ TODO | id, event_type, payload, status, created_at, published_at |
| 2.1.11 | Партиционирование `audit_log` + retention | ⏳ TODO | RANGE по timestamp (например, monthly) + архивирование/очистка |
| 2.1.12 | Cleanup для `outbox_events` | ⏳ TODO | Удаление PUBLISHED старше N дней (например, 7d) |
| 2.1.13 | Дедупликация событий — Redis TTL | ⏳ TODO | processed:{consumer}:{event_id} в Redis TTL >= 7d (таблица processed_events НЕ создаётся) |

## 2.2 Row-Level Security (RLS)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 2.2.1 | Включение RLS на таблице organizations | ⏳ TODO | ALTER TABLE ... ENABLE ROW LEVEL SECURITY |
| 2.2.2 | Включение RLS на таблице memberships | ⏳ TODO | Фильтр по org_id |
| 2.2.3 | Включение RLS на таблице roles | ⏳ TODO | Фильтр по org_id |
| 2.2.4 | Включение RLS на таблице invitations | ⏳ TODO | Фильтр по org_id |
| 2.2.5 | Включение RLS на таблице audit_log | ⏳ TODO | Фильтр по org_id |
| 2.2.6 | Политика SELECT для организаций | ⏳ TODO | current_setting('app.current_org_id', true)::uuid (fail-safe, NULL → 0 строк) |
| 2.2.7 | Политика INSERT/UPDATE/DELETE | ⏳ TODO | Соответствие org_id |
| 2.2.8 | Создание роли iam_app (без BYPASSRLS) | ⏳ TODO | CREATE ROLE iam_app NOINHERIT |
| 2.2.9 | Создание роли iam_migrator (для DDL) | ⏳ TODO | CREATE ROLE iam_migrator |

## 2.3 Индексы и оптимизация

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 2.3.1 | Индекс memberships(user_id, org_id) | ⏳ TODO | PRIMARY KEY или UNIQUE |
| 2.3.2 | Индекс roles(org_id) | ⏳ TODO | Для RLS фильтрации |
| 2.3.3 | Индекс invitations(token_hash) | ⏳ TODO | UNIQUE для lookup |
| 2.3.4 | Индекс invitations(email, org_id) | ⏳ TODO | Поиск существующих |
| 2.3.5 | Индекс audit_log(org_id, timestamp) | ⏳ TODO | Для фильтрации и сортировки |
| 2.3.6 | Индекс outbox_events(status, created_at) | ⏳ TODO | Для polling PENDING |

## 2.4 Миграции (Flyway)

| ID | Задача | Статус | Файл |
|----|--------|--------|------|
| 2.4.1 | Настройка Flyway | ⏳ TODO | flyway.conf |
| 2.4.2 | V1__init_schema.sql | ⏳ TODO | Создание схемы и базовых таблиц |
| 2.4.3 | V2__users_organizations.sql | ⏳ TODO | Таблицы users, organizations |
| 2.4.4 | V3__roles_privileges.sql | ⏳ TODO | RBAC таблицы |
| 2.4.5 | V4__memberships.sql | ⏳ TODO | Связи пользователей и организаций |
| 2.4.6 | V5__invitations.sql | ⏳ TODO | Приглашения |
| 2.4.7 | V6__audit_log.sql | ⏳ TODO | Аудит |
| 2.4.8 | V7__outbox.sql | ⏳ TODO | Outbox pattern |
| 2.4.9 | V8__rls_policies.sql | ⏳ TODO | Row-Level Security |
| 2.4.10 | V9__seed_privileges.sql | ⏳ TODO | Начальные привилегии |
| 2.4.11 | V10__audit_partitioning.sql | ⏳ TODO | Партиционирование audit_log (RANGE по времени) |
| 2.4.12 | V11__outbox_retention.sql | ⏳ TODO | Cleanup PUBLISHED outbox + индексы под polling |
| 2.4.13 | Интеграция Flyway в CI/CD | ⏳ TODO | Github CI Job |

## 2.5 Redis структуры

| ID | Задача | Статус | Ключ/Паттерн |
|----|--------|--------|--------------|
| 2.5.1 | Сессии BFF | ⏳ TODO | bff:session:{sid} (Hash) |
| 2.5.2 | RBAC кэш | ⏳ TODO | rbac:cache:{org_id}:{user_id} (Hash) |
| 2.5.3 | OIDC state/nonce | ⏳ TODO | oidc:state:{state} (TTL 5 min) |
| 2.5.4 | Redis Streams для событий | ⏳ TODO | iam.events (единый стрим для событий IAM) |
| 2.5.5 | Rate limiting counters | ⏳ TODO | rate:{ip}:{endpoint} |
| 2.5.6 | Processed events dedup | ⏳ TODO | processed:{event_id} (TTL 7d) |

---

# 3. IAM BACKEND (.NET 10)

## 3.1 Проект и структура

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 3.1.1 | Расширение каркаса PM.IAM.Api | ⏳ TODO | ASP.NET Core Web API (Controllers + gRPC hosting). Каркас создан в Фазе 0 |
| 3.1.2 | Структура слоёв (Clean Architecture) | ⏳ TODO | PM.IAM.Domain, PM.IAM.Application, PM.IAM.Infrastructure, PM.IAM.Api |
| 3.1.3 | Подключение EF Core + Npgsql | ⏳ TODO | NuGet packages |
| 3.1.4 | Подключение StackExchange.Redis | ⏳ TODO | Для Redis |
| 3.1.5 | Подключение Grpc.AspNetCore | ⏳ TODO | Для gRPC сервисов |
| 3.1.5a | PM.IAM.Contracts → PM.IAM.Api ссылка | ⏳ TODO | ProjectReference для gRPC сервисов |
| 3.1.6 | Настройка OpenTelemetry | ⏳ TODO | Traces, Metrics, Logs |

## 3.2 REST API — Organizations

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 3.2.1 | GET /api/iam/v1/organizations | ⏳ TODO | Список организаций пользователя |
| 3.2.2 | GET /api/iam/v1/organizations/{id} | ⏳ TODO | Детали организации |
| 3.2.3 | POST /api/iam/v1/organizations | ⏳ TODO | Создание организации |
| 3.2.4 | PATCH /api/iam/v1/organizations/{id} | ⏳ TODO | Обновление организации |
| 3.2.5 | DELETE /api/iam/v1/organizations/{id} | ⏳ TODO | Удаление организации |
| 3.2.6 | GET /api/iam/v1/organizations/{id}/members | ⏳ TODO | Список участников организации |
| 3.2.7 | PATCH /api/iam/v1/organizations/{id}/members/{userId} | ⏳ TODO | Обновление роли участника |
| 3.2.8 | DELETE /api/iam/v1/organizations/{id}/members/{userId} | ⏳ TODO | Удаление участника |

## 3.3 REST API — Users

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 3.3.1 | GET /api/iam/v1/users | ⏳ TODO | Список пользователей в организации |
| 3.3.2 | GET /api/iam/v1/users/{id} | ⏳ TODO | Профиль пользователя |
| 3.3.3 | GET /api/iam/v1/users/me | ⏳ TODO | Текущий пользователь |
| 3.3.4 | PUT /api/iam/v1/users/{id} | ⏳ TODO | Обновление профиля |
| 3.3.5 | DELETE /api/iam/v1/users/{id} | ⏳ TODO | Удаление/деактивация |

## 3.4 REST API — Roles

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 3.4.1 | GET /api/iam/v1/roles | ⏳ TODO | Список ролей организации |
| 3.4.2 | GET /api/iam/v1/roles/{id} | ⏳ TODO | Детали роли с привилегиями |
| 3.4.3 | POST /api/iam/v1/roles | ⏳ TODO | Создание кастомной роли |
| 3.4.4 | PATCH /api/iam/v1/roles/{id} | ⏳ TODO | Обновление роли |
| 3.4.5 | DELETE /api/iam/v1/roles/{id} | ⏳ TODO | Удаление роли |
| 3.4.6 | GET /api/iam/v1/privileges | ⏳ TODO | Список всех привилегий |

## 3.5 REST API — Invitations

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 3.5.1 | GET /api/iam/v1/invitations | ⏳ TODO | Список приглашений |
| 3.5.2 | POST /api/iam/v1/invitations | ⏳ TODO | Создание приглашения |
| 3.5.3 | DELETE /api/iam/v1/invitations/{id} | ⏳ TODO | Отмена приглашения |
| 3.5.4 | POST /api/iam/v1/invitations/{id}/resend | ⏳ TODO | Повторная отправка |
| 3.5.5 | GET /api/iam/v1/invitations/validate | ⏳ TODO | Проверка токена (публичный): hash(token) → compare token_hash |
| 3.5.6 | POST /api/iam/v1/invitations/accept | ⏳ TODO | Принятие приглашения (создание membership + audit) |

## 3.6 REST API — Audit

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 3.6.1 | GET /api/iam/v1/audit | ⏳ TODO | Список событий аудита |
| 3.6.2 | GET /api/iam/v1/audit/{id} | ⏳ TODO | Детали события |

## 3.7 REST API — RBAC Check

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 3.7.1 | POST /api/iam/v1/access/check | ⏳ TODO | Проверка права доступа |
| 3.7.2 | GET /api/iam/v1/users/{id}/effective-roles | ⏳ TODO | Эффективные роли |

## 3.8 gRPC сервисы

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 3.8.1 | Proto-файл iam.proto | ⏳ TODO | Определение сервисов |
| 3.8.2 | rpc CheckPermission | ⏳ TODO | Быстрая проверка прав |
| 3.8.3 | rpc CheckBatch | ⏳ TODO | Батчевая проверка |
| 3.8.4 | rpc GetEffectiveRoles | ⏳ TODO | Получение ролей |
| 3.8.5 | gRPC reflection | ⏳ TODO | Для отладки |

## 3.9 Интеграция с Keycloak Admin API

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 3.9.1 | HTTP-клиент для Keycloak | ⏳ TODO | Typed HttpClient |
| 3.9.2 | Получение пользователя по ID | ⏳ TODO | GET /admin/realms/{r}/users/{id} |
| 3.9.3 | Поиск пользователя по email | ⏳ TODO | GET /admin/realms/{r}/users?email= |
| 3.9.4 | Logout пользователя everywhere | ⏳ TODO | POST /admin/realms/{r}/users/{id}/logout |
| 3.9.5 | Кэширование Keycloak JWKS | ⏳ TODO | Публичные ключи для JWT |

## 3.10 Бизнес-логика

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 3.10.1 | OrganizationService | ⏳ TODO | CRUD организаций |
| 3.10.2 | UserService | ⏳ TODO | Управление пользователями |
| 3.10.3 | RoleService | ⏳ TODO | Управление ролями |
| 3.10.4 | InvitationService | ⏳ TODO | Приглашения + email |
| 3.10.5 | RbacService | ⏳ TODO | Проверка прав, кэш |
| 3.10.6 | AuditService | ⏳ TODO | Запись событий аудита |
| 3.10.7 | OutboxPublisher | ⏳ TODO | Публикация событий |
| 3.10.8 | OutboxPublisherWorker | ⏳ TODO | Poll outbox_events → publish в Redis Stream iam.events (at-least-once) |

## 3.11 RLS интеграция

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 3.11.1 | Middleware для установки current_org_id | ⏳ TODO | SET LOCAL app.current_org_id = ... |
| 3.11.2 | DbContext с RLS transaction | ⏳ TODO | BeginTransaction + SET LOCAL |
| 3.11.3 | Тесты изоляции данных | ⏳ TODO | Проверка, что RLS работает |

## 3.12 Health и метрики

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 3.12.1 | GET /health | ⏳ TODO | Liveness probe |
| 3.12.2 | GET /health/ready | ⏳ TODO | Readiness (DB, Redis) |
| 3.12.3 | GET /metrics | ⏳ TODO | Prometheus endpoint |

---

# 4. BFF-СЕРВИС (.NET 10)

## 4.1 Проект и структура

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 4.1.1 | Расширение каркаса PM.BFF | ⏳ TODO | ASP.NET Core Web API (Controllers). Каркас создан в Фазе 0 |
| 4.1.2 | Подключение StackExchange.Redis | ⏳ TODO | Сессии |
| 4.1.3 | Подключение HTTP Client для IAM Backend | ⏳ TODO | Typed HttpClient |
| 4.1.4 | Подключение gRPC Client | ⏳ TODO | Для RBAC проверок |
| 4.1.5 | Настройка OpenTelemetry | ⏳ TODO | Трейсинг |

## 4.2 Аутентификация (OIDC)

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 4.2.1 | GET /auth/login | ⏳ TODO | Редирект на Keycloak |
| 4.2.2 | GET /auth/callback | ⏳ TODO | Обмен code на токены |
| 4.2.3 | GET /auth/logout | ⏳ TODO | SSO logout |
| 4.2.4 | GET /auth/me | ⏳ TODO | Текущий пользователь |
| 4.2.5 | Генерация state, nonce, PKCE | ⏳ TODO | Сохранение в Redis |
| 4.2.6 | Валидация state при callback | ⏳ TODO | Сверка с Redis |
| 4.2.7 | Валидация ID Token (signature, nonce) | ⏳ TODO | JWKS verification |
| 4.2.8 | GET /auth/forgot-password | ⏳ TODO | Инициировать reset password (redirect на IdP) |
| 4.2.9 | POST /auth/switch-org | ⏳ TODO | Переключение current org в сессии (session context) |

## 4.3 Action Links Proxy

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 4.3.1 | GET /auth/action | ⏳ TODO | Прокси verify-email/reset-password |
| 4.3.2 | Whitelist допустимых action paths | ⏳ TODO | Безопасная валидация |
| 4.3.3 | Rate limiting на action endpoints | ⏳ TODO | Защита от abuse |

## 4.4 Управление сессиями

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 4.4.1 | Генерация Session ID (256 bit) | ⏳ TODO | Криптостойкий генератор |
| 4.4.2 | Сохранение сессии в Redis Hash | ⏳ TODO | bff:session:{sid} |
| 4.4.3 | Установка cookie __Host-bff.sid | ⏳ TODO | Path=/; Secure; HttpOnly; SameSite=Lax; Max-Age=43200 |
| 4.4.4 | TTL для access_token (5 min) | ⏳ TODO | HEXPIRE в Redis 8 |
| 4.4.5 | TTL для refresh_token (12-24h) | ⏳ TODO | HEXPIRE в Redis 8 |
| 4.4.6 | Idle timeout (30 min) | ⏳ TODO | Обновление last_active |
| 4.4.7 | Absolute timeout (12h) | ⏳ TODO | created_at check |
| 4.4.8 | Session fixation prevention | ⏳ TODO | Новый sid после login |
| 4.4.9 | Автоматический refresh токенов | ⏳ TODO | При истечении access_token |

## 4.5 CSRF защита

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 4.5.1 | Генерация CSRF токена | ⏳ TODO | 128+ бит случайности |
| 4.5.2 | Cookie XSRF-TOKEN (не HttpOnly) | ⏳ TODO | Path=/; Secure; SameSite=Strict; Max-Age=43200 |
| 4.5.3 | Валидация заголовка X-CSRF-Token | ⏳ TODO | Double Submit Cookie |
| 4.5.4 | Проверка Origin/Referer | ⏳ TODO | Дополнительная защита |

## 4.6 API Proxy (/api/*)

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 4.6.1 | Middleware проверки сессии | ⏳ TODO | 401 если нет cookie |
| 4.6.2 | Middleware CSRF для POST/PUT/DELETE | ⏳ TODO | 403 если нет токена |
| 4.6.3 | GET /api/organizations → IAM Backend | ⏳ TODO | Прокси + Authorization |
| 4.6.4 | GET /api/users → IAM Backend | ⏳ TODO | Прокси + org context |
| 4.6.5 | GET /api/roles → IAM Backend | ⏳ TODO | Прокси |
| 4.6.6 | POST /api/* → IAM Backend | ⏳ TODO | С проверкой RBAC |
| 4.6.7 | Проксирование trace headers + X-Request-ID | ⏳ TODO | W3C Trace Context через Edge → BFF → Backend |
| 4.6.8 | Передача X-Org-Id заголовка | ⏳ TODO | Контекст организации |
| 4.6.9 | Compatibility routes без /api | ⏳ TODO | /organizations,/invitations,/roles,/audit,/users/* обрабатываются теми же handlers |

## 4.7 Приглашения

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 4.7.1 | POST /invite | ⏳ TODO | Создание приглашения (RBAC INVITE_USER + CSRF); BFF вызывает IAM POST /invitations |
| 4.7.2 | GET /api/invitations | ⏳ TODO | (Optional) Список приглашений (через /api/* proxy) |
| 4.7.3 | DELETE /api/invitations/{id} | ⏳ TODO | (Optional) Отмена приглашения (RBAC + CSRF) |
| 4.7.4 | POST /api/invitations/{id}/resend | ⏳ TODO | (Optional) Повторная отправка (RBAC + CSRF) |
| 4.7.5 | GET /invite?token=... | ⏳ TODO | Принятие приглашения (публичный вход); внутри BFF вызывает IAM GET /invitations/validate?token=... и оркестрирует редиректы |
| 4.7.6 | IAM: GET /invitations/validate?token=... | ⏳ TODO | Внутренний вызов из BFF; IAM сравнивает SHA-256(token) с token_hash |
| 4.7.7 | IAM: POST /invitations/accept | ⏳ TODO | Внутренний вызов из BFF после auth (авто-финализация: membership + audit) |

## 4.8 Rate Limiting

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 4.8.1 | /auth/login (failed): 5/min per IP | ⏳ TODO | 429 + lockout 5 min, log attempt |
| 4.8.2 | /auth/callback: 10/min per IP + state | ⏳ TODO | Защита от штормов с мусорными code/state |
| 4.8.3 | /auth/action: 20/min per IP | ⏳ TODO | Защита action-links от spam |
| 4.8.4 | /auth/forgot-password: 3/hour per email | ⏳ TODO | 429, silent (no enumeration) |
| 4.8.5 | /invite?token=...: 10/min per IP | ⏳ TODO | Защита от перебора invite токенов |
| 4.8.6 | POST /invite: 20/hour per org | ⏳ TODO | Anti-invite-spam по org |
| 4.8.7 | /api/*: 100/sec per session | ⏳ TODO | Базовый лимит на авторизованные запросы |
| 4.8.8 | /api/users/lookup: 30/min per user | ⏳ TODO | Anti-enumeration |
| 4.8.9 | /api/organizations: 5/day per user | ⏳ TODO | 400 Limit Exceeded |
| 4.8.10 | Redis-based rate limiter | ⏳ TODO | Sliding window + Retry-After |
| 4.8.11 | /auth/login (failed): 10/hour per email | ⏳ TODO | 429 + account lockout, email notification |
| 4.8.12 | Политика lockout (IP/email) | ⏳ TODO | Единые времена блокировок и логирование попыток (без утечек) |
| 4.8.13 | /auth/register: 3/min per IP + captcha/abuse | ⏳ TODO | капча |

## 4.9 Health и метрики

| ID | Задача | Статус | Endpoint |
|----|--------|--------|----------|
| 4.9.1 | GET /health | ⏳ TODO | Liveness |
| 4.9.2 | GET /health/ready | ⏳ TODO | Redis, IAM Backend |
| 4.9.3 | GET /metrics | ⏳ TODO | Prometheus |

## 4.10 Security headers + CORS + hardening (IAM_Security_Test_Matrix)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 4.10.1 | Strict-Transport-Security (HSTS) | ⏳ TODO | max-age >= 1 year (и правила для prod) |
| 4.10.2 | Referrer-Policy | ⏳ TODO | strict-origin-when-cross-origin или строже |
| 4.10.3 | Permissions-Policy | ⏳ TODO | Ограничить опасные browser features |
| 4.10.4 | CORS policy | ⏳ TODO | Allow-Origin только публичный домен, Allow-Credentials=true, Allow-Headers включает X-CSRF-Token, X-Request-ID |
| 4.10.5 | Payload size limits | ⏳ TODO | 413 на большие тела (например 10MB), без crash |

## 4.11 Consuming iam.events (RBAC cache invalidation)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 4.11.1 | Consumer group iam_bff | ⏳ TODO | XGROUP CREATE iam.events iam_bff $ MKSTREAM |
| 4.11.2 | Idempotency store | ⏳ TODO | processed:iam_bff:{event_id} TTL >= 7d |
| 4.11.3 | Handle ROLE_ASSIGNED/REVOKED | ⏳ TODO | DEL rbac:cache:{orgId}:{userId} |
| 4.11.4 | Handle INVITE_ACCEPTED | ⏳ TODO | DEL orgs cache + rbac cache (при необходимости) |
| 4.11.5 | Lag monitoring | ⏳ TODO | Метрика consumer lag + алерт |

---

# 5. FRONTEND SPA (Angular 21)

## 5.1 Проект и структура

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.1.1 | Создание Angular 21 проекта | ⏳ TODO | ng new iam-spa |
| 5.1.2 | Настройка SCSS | ⏳ TODO | styles.scss |
| 5.1.3 | Настройка TypeScript strict | ⏳ TODO | tsconfig.json |
| 5.1.4 | Настройка ESLint + Prettier | ⏳ TODO | Код-стайл |
| 5.1.5 | Настройка Angular Router | ⏳ TODO | Lazy loading |

## 5.2 Core Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.2.1 | AuthService | ⏳ TODO | login(), logout(), isAuthenticated |
| 5.2.2 | UserService | ⏳ TODO | getCurrentUser(), updateProfile() |
| 5.2.3 | OrgService | ⏳ TODO | getOrganizations(), switchOrg() |
| 5.2.4 | HttpInterceptor (CSRF) | ⏳ TODO | X-CSRF-Token header |
| 5.2.5 | HttpInterceptor (Error) | ⏳ TODO | 401/403 handling |
| 5.2.6 | AuthGuard | ⏳ TODO | canActivate |
| 5.2.7 | RoleGuard | ⏳ TODO | canActivate с проверкой роли |

## 5.3 Shared Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.3.1 | LayoutComponent | ⏳ TODO | Header + Sidebar + Content |
| 5.3.2 | HeaderComponent | ⏳ TODO | Logo, Org switcher, User menu |
| 5.3.3 | SidebarComponent | ⏳ TODO | Navigation menu |
| 5.3.4 | ConfirmDialogComponent | ⏳ TODO | Модальное подтверждение |
| 5.3.5 | SpinnerComponent | ⏳ TODO | Loading indicator |
| 5.3.6 | EmptyStateComponent | ⏳ TODO | Пустые списки |
| 5.3.7 | ErrorPageComponent | ⏳ TODO | 403/404/500 |
| 5.3.8 | NotificationService | ⏳ TODO | Toast messages |

## 5.4 Auth Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.4.1 | LoginComponent | ⏳ TODO | Redirect to /auth/login |
| 5.4.2 | AuthCallbackComponent | ⏳ TODO | Обработка callback |
| 5.4.3 | LogoutComponent | ⏳ TODO | Redirect to /auth/logout |
| 5.4.4 | InviteAcceptComponent | ⏳ TODO | Страница приглашения |
| 5.4.5 | SessionExpiredComponent | ⏳ TODO | Сообщение об истечении |

## 5.5 Org Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.5.1 | OrgSelectComponent | ⏳ TODO | Выбор организации |
| 5.5.2 | OrgCreateComponent | ⏳ TODO | Создание организации |
| 5.5.3 | OrgSettingsComponent | ⏳ TODO | Настройки организации |

## 5.6 Users Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.6.1 | UserListComponent | ⏳ TODO | Таблица пользователей |
| 5.6.2 | UserDetailComponent | ⏳ TODO | Просмотр пользователя |
| 5.6.3 | UserEditDialogComponent | ⏳ TODO | Редактирование |
| 5.6.4 | UserService (API) | ⏳ TODO | CRUD операции |

## 5.7 Roles Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.7.1 | RoleListComponent | ⏳ TODO | Таблица ролей |
| 5.7.2 | RoleCreateComponent | ⏳ TODO | Создание роли |
| 5.7.3 | RoleEditComponent | ⏳ TODO | Редактирование роли |
| 5.7.4 | PrivilegePickerComponent | ⏳ TODO | Выбор привилегий |
| 5.7.5 | RoleService (API) | ⏳ TODO | CRUD операции |

## 5.8 Invites Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.8.1 | InviteListComponent | ⏳ TODO | Таблица приглашений |
| 5.8.2 | InviteCreateComponent | ⏳ TODO | Создание приглашения |
| 5.8.3 | InviteService (API) | ⏳ TODO | CRUD операции |

## 5.9 Audit Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.9.1 | AuditLogComponent | ⏳ TODO | Таблица событий |
| 5.9.2 | AuditDetailComponent | ⏳ TODO | Детали события |
| 5.9.3 | AuditFilterComponent | ⏳ TODO | Фильтры |
| 5.9.4 | AuditService (API) | ⏳ TODO | GET /api/audit |

## 5.10 Profile Module

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.10.1 | ProfileComponent | ⏳ TODO | Просмотр профиля |
| 5.10.2 | ProfileEditComponent | ⏳ TODO | Редактирование |
| 5.10.3 | SessionsComponent | ⏳ TODO | Активные сессии |
| 5.10.4 | AccountSettingsComponent | ⏳ TODO | Настройки аккаунта |

## 5.11 Безопасность фронтенда

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.11.1 | CSP header + Trusted Types (через Edge/BFF, не meta) | ⏳ TODO | Должно соответствовать SEC-CSP-001 из матрицы безопасности |
| 5.11.2 | CSRF interceptor | ⏳ TODO | X-CSRF-Token для POST/PUT/DELETE |
| 5.11.3 | 401 → redirect to login | ⏳ TODO | Error interceptor |
| 5.11.4 | XSS protection (Angular built-in) | ⏳ TODO | Sanitization |
| 5.11.5 | Secure state management | ⏳ TODO | Нет токенов в localStorage |
| 5.11.6 | Error Catalog integration | ⏳ TODO | UI показывает локализованный message_key, trace_id и безопасные сценарии ошибок |

## 5.12 i18n и a11y

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 5.12.1 | Настройка @angular/localize | ⏳ TODO | i18n |
| 5.12.2 | Файл переводов ru.json | ⏳ TODO | Русский язык |
| 5.12.3 | Файл переводов en.json | ⏳ TODO | Английский (fallback) |
| 5.12.4 | WCAG 2.1 AA compliance | ⏳ TODO | Accessibility |
| 5.12.5 | Keyboard navigation | ⏳ TODO | Tab order |
| 5.12.6 | Screen reader support | ⏳ TODO | aria-labels |

---

# 6. KEYCLOAK НАСТРОЙКА

## 6.1 Realm и Clients

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 6.1.1 | Создание realm "iam" | ⏳ TODO | Основной realm |
| 6.1.2 | Создание client "bff" | ⏳ TODO | confidential, PKCE |
| 6.1.3 | Настройка redirect URIs | ⏳ TODO | http://localhost:8090/auth/callback |
| 6.1.4 | Настройка post_logout_redirect_uri | ⏳ TODO | Whitelist |
| 6.1.5 | Настройка Frontend URL | ⏳ TODO | Публичный домен |

## 6.2 Email Templates

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 6.2.1 | Verify Email template | ⏳ TODO | Ссылка через публичный домен |
| 6.2.2 | Reset Password template | ⏳ TODO | Ссылка через публичный домен |
| 6.2.3 | Execute Actions template | ⏳ TODO | Required actions |
| 6.2.4 | Настройка SMTP (Mailpit для dev) | ⏳ TODO | mailpit:1025 |

## 6.3 Authentication Flows

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 6.3.1 | Browser flow с WebAuthn | ⏳ TODO | Passkeys support |
| 6.3.2 | Registration flow | ⏳ TODO | Email verification required |
| 6.3.3 | Reset credentials flow | ⏳ TODO | Password reset |

---

# 7. ТЕСТИРОВАНИЕ

## 7.1 Unit Tests

| ID | Задача | Статус | Компонент |
|----|--------|--------|-----------|
| 7.1.1 | IAM Backend: Services | ⏳ TODO | xUnit + Moq |
| 7.1.2 | IAM Backend: Controllers | ⏳ TODO | xUnit |
| 7.1.3 | BFF: Session management | ⏳ TODO | xUnit |
| 7.1.4 | BFF: CSRF validation | ⏳ TODO | xUnit |
| 7.1.5 | Angular: Services | ⏳ TODO | Jasmine/Karma |
| 7.1.6 | Angular: Guards | ⏳ TODO | Jasmine/Karma |
| 7.1.7 | Angular: Interceptors | ⏳ TODO | Jasmine/Karma |

## 7.2 Integration Tests

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 7.2.1 | IAM Backend + PostgreSQL | ⏳ TODO | Testcontainers |
| 7.2.2 | IAM Backend + Redis | ⏳ TODO | Testcontainers |
| 7.2.3 | BFF + Redis | ⏳ TODO | Testcontainers |
| 7.2.4 | BFF + IAM Backend | ⏳ TODO | Testcontainers |
| 7.2.5 | RLS isolation tests | ⏳ TODO | Проверка изоляции данных |
| 7.2.6 | Error contract schema validation | ⏳ TODO | Валидация JSON schema ошибок на BFF и Backend |
| 7.2.7 | Outbox atomicity tests | ⏳ TODO | Изменение + outbox в одной транзакции |

## 7.3 E2E Tests

| ID | Задача | Статус | Сценарий |
|----|--------|--------|----------|
| 7.3.1 | Login flow | ⏳ TODO | Cypress/Playwright |
| 7.3.2 | Logout flow | ⏳ TODO | SSO logout |
| 7.3.3 | Org switch | ⏳ TODO | Смена организации |
| 7.3.4 | Invite user | ⏳ TODO | Приглашение + регистрация |
| 7.3.5 | CRUD users | ⏳ TODO | Управление пользователями |
| 7.3.6 | CRUD roles | ⏳ TODO | Управление ролями |
| 7.3.7 | Session expiration | ⏳ TODO | Idle timeout |

## 7.4 Security Tests (IAM_Security_Test_Matrix)

| ID | Задача | Статус | Категория |
|----|--------|--------|-----------|
| 7.4.1 | OWASP ZAP scan | ⏳ TODO | Automated security scan |
| 7.4.2 | CSRF protection test | ⏳ TODO | Double Submit Cookie |
| 7.4.3 | Session fixation test | ⏳ TODO | New SID after login |
| 7.4.4 | XSS injection test | ⏳ TODO | Input validation |
| 7.4.5 | SQL injection test | ⏳ TODO | Parameterized queries |
| 7.4.6 | RLS bypass test | ⏳ TODO | Cross-org data access |
| 7.4.7 | Rate limiting test | ⏳ TODO | Brute-force protection |
| 7.4.8 | JWT validation test | ⏳ TODO | Signature, expiry, nonce |
| 7.4.9 | Cookie attributes test | ⏳ TODO | Secure, HttpOnly, SameSite |
| 7.4.10 | Dependency scan gate | ⏳ TODO | CI job блокирует уязвимости severity>=High |
| 7.4.11 | Security headers scan | ⏳ TODO | Автотест на наличие обязательных заголовков |
| 7.4.12 | CSP validation | ⏳ TODO | CSP соответствует матрице |
| 7.4.13 | Secret scanning | ⏳ TODO | Блокируем утечки секретов |

## 7.5 Load Tests (IAM_Load_Profile)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 7.5.1 | Login: 50 RPS baseline | ⏳ TODO | k6/Gatling |
| 7.5.2 | RBAC check: 1000 RPS (gRPC) | ⏳ TODO | k6/Gatling |
| 7.5.3 | API endpoints: 300 RPS | ⏳ TODO | k6/Gatling |
| 7.5.4 | Latency p95 < 300ms | ⏳ TODO | SLO verification |
| 7.5.5 | Concurrent users: 100+ | ⏳ TODO | Stress test |

---

# 8. OBSERVABILITY (Мониторинг)

> Важно: observability — не финальный этап, а кросс-срезовой фундамент. Базовые логи/метрики/trace_id должны появляться с первых инкрементов, иначе потом придётся «догонять» и переписывать код и тесты.

## 8.1 Соглашения и кросс‑срезовые требования (делается в начале)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 8.1.1 | Единый формат логов: stdout JSON + ECS | ⏳ TODO | В каждый лог включать service.name, trace.id, span.id для корреляции |
| 8.1.2 | Trace correlation в ошибках | ⏳ TODO | trace_id присутствует во всех error-response (BFF и Backend) |
| 8.1.3 | Контракт метрики ошибок iam_errors_total | ⏳ TODO | iam_errors_total{error_code,http_status,service} как единый стандарт |
| 8.1.4 | Политика редактирования/маскировки | ⏳ TODO | token/password никогда не логировать; PII маскировать/хешировать |
| 8.1.5 | Конвенции по метрикам/лейблам | ⏳ TODO | Избегать high-cardinality лейблов (user_id) в метриках; org_id — только там, где это явно требуется DoD |
| 8.1.6 | Контракт событийных логов (Invite) | ⏳ TODO | INVITATION_SENT: trace_id, org_id, inviter_id_hash, invitee_email_domain (без raw email/PII) |

## 8.2 OpenTelemetry (инструментация сервисов)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 8.2.1 | IAM Backend: OTel SDK | ⏳ TODO | Traces + Metrics + Logs, экспорт OTLP → Collector |
| 8.2.2 | BFF: OTel SDK | ⏳ TODO | Traces + Metrics + Logs, экспорт OTLP → Collector |
| 8.2.3 | Trace context propagation | ⏳ TODO | W3C Trace Context через Edge → BFF → Backend → Keycloak |
| 8.2.4 | Обогащение спанов | ⏳ TODO | route, http.status_code, error_code; без утечек PII |
| 8.2.5 | Спаны invite-flow | ⏳ TODO | bff.invite.create, backend.invite.create, backend.email.send |

## 8.3 Elasticsearch + Kibana (логи и поиск)

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 8.3.1 | Index templates для ECS логов | ⏳ TODO | Поля trace.id/span.id/service.name индексируются |
| 8.3.2 | ILM/retention политика | ⏳ TODO | Горячие/тёплые индексы; очистка по срокам хранения |
| 8.3.3 | Kibana: базовые views | ⏳ TODO | Ошибки по error_code, корреляция по trace.id |
| 8.3.4 | Дашборды для IAM | ⏳ TODO | Login/Logout/Invites/Errors/Outbox |

## 8.4 Метрики (Prometheus)

| ID | Задача | Статус | Метрика/Группа |
|----|--------|--------|----------------|
| 8.4.1 | iam_errors_total{error_code,http_status,service} | ⏳ TODO | Counter (обязательная метрика ошибок) |
| 8.4.2 | iam_login_total{status} | ⏳ TODO | Counter |
| 8.4.3 | iam_logout_total{status} | ⏳ TODO | Counter |
| 8.4.4 | iam_rbac_check_duration_seconds | ⏳ TODO | Histogram |
| 8.4.5 | iam_session_active_total | ⏳ TODO | Gauge |
| 8.4.6 | iam_invitations_sent_total{org_id} | ⏳ TODO | Counter |
| 8.4.7 | bff_http_request_duration_seconds | ⏳ TODO | Histogram |

## 8.5 Grafana (визуализация)

| ID | Задача | Статус | Дашборд/Конфиг |
|----|--------|--------|----------------|
| 8.5.1 | Datasources (Prometheus, Elasticsearch) | ⏳ TODO | Provisioning в репозитории |
| 8.5.2 | Dashboard: Errors (iam_errors_total) | ⏳ TODO | Ошибки по error_code/http_status/service |
| 8.5.3 | Dashboard: Latency (p95/p99) | ⏳ TODO | BFF/Backend latency + SLO |
| 8.5.4 | Dashboard: Auth & Rate limits | ⏳ TODO | Логины/логауты/превышения лимитов |
| 8.5.5 | Dashboard: Sessions & Redis | ⏳ TODO | Активные сессии/ошибки Redis |

## 8.6 Alerting (обязательные алерты + SLO)

| ID | Задача | Статус | Alert |
|----|--------|--------|-------|
| 8.6.1 | Auth.CsrfInvalid > 10/min | ⏳ TODO | Warning |
| 8.6.2 | Rate.LoginExceeded > 50/min | ⏳ TODO | Warning |
| 8.6.3 | System.DatabaseUnavailable > 0 | ⏳ TODO | Critical |
| 8.6.4 | Auth.IdpUnavailable > 0 | ⏳ TODO | Critical (Keycloak) |
| 8.6.5 | System.InternalError > 5/min | ⏳ TODO | Critical |
| 8.6.6 | Любой 5xx > 1% от requests | ⏳ TODO | Warning |
| 8.6.7 | High latency (p95 > 500ms) | ⏳ TODO | Warning |

---

# 9. CI/CD

## 9.1 Build Pipeline

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 9.1.1 | .NET build job | ⏳ TODO | dotnet build |
| 9.1.2 | .NET test job | ⏳ TODO | dotnet test |
| 9.1.3 | Angular build job | ⏳ TODO | ng build --prod |
| 9.1.4 | Angular test job | ⏳ TODO | ng test |
| 9.1.5 | Docker image build | ⏳ TODO | docker build |
| 9.1.6 | Docker image push | ⏳ TODO | docker push |

## 9.2 Database Migration Pipeline

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 9.2.1 | Flyway migrate job | ⏳ TODO | Apply migrations |
| 9.2.2 | Migration validation | ⏳ TODO | Test on clean DB |
| 9.2.3 | DBA review gate (prod) | ⏳ TODO | Manual approval |

## 9.3 Deployment Pipeline

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 9.3.1 | Deploy to dev | ⏳ TODO | Auto on merge |
| 9.3.2 | Deploy to staging | ⏳ TODO | Manual trigger |
| 9.3.3 | Deploy to production | ⏳ TODO | Manual approval |
| 9.3.4 | Rollback procedure | ⏳ TODO | Documented |

---

# 10. ДОКУМЕНТАЦИЯ

## 10.1 API Documentation

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 10.1.1 | OpenAPI spec для IAM Backend | ⏳ TODO | Swagger/OpenAPI 3.0 |
| 10.1.2 | OpenAPI spec для BFF | ⏳ TODO | Swagger/OpenAPI 3.0 |
| 10.1.3 | gRPC proto documentation | ⏳ TODO | protoc-gen-doc |

## 10.2 Developer Documentation

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 10.2.1 | README.md | ⏳ TODO | Quick start |
| 10.2.2 | Architecture overview | ⏳ TODO| ADR документ |
| 10.2.3 | Local development guide | ⏳ TODO | docker-compose up |
| 10.2.4 | Troubleshooting guide | ⏳ TODO | Типовые ошибки |
| 10.2.5 | Solution structure guide | ⏳ TODO | docs/architecture/solution-structure.md |
| 10.2.6 | Development workflow guide | ⏳ TODO | docs/architecture/dev-workflow.md |

## 10.3 Operations Documentation

| ID | Задача | Статус | Описание |
|----|--------|--------|----------|
| 10.3.1 | Deployment guide | ⏳ TODO| Инструкция по развёртыванию |
| 10.3.2 | Runbook | ⏳ TODO | Operational procedures |
| 10.3.3 | Disaster recovery plan | ⏳ TODO | Backup/Restore |

---

# SUMMARY

## Статистика по статусам

| Категория | ⏳ TODO| ⏳ TODO | Всего |
|-----------|---------|--------|-------|
| 1. Инфраструктура | 25 | 10 | 35 |
| 2. Data Layer | 0 | 43 | 43 |
| 3. IAM Backend | 0 | 56 | 56 |
| 4. BFF-сервис | 0 | 64 | 64 |
| 5. Frontend SPA | 0 | 59 | 59 |
| 6. Keycloak | 0 | 12 | 12 |
| 7. Тестирование | 0 | 33 | 33 |
| 8. Observability | 0 | 34 | 34 |
| 9. CI/CD | 0 | 13 | 13 |
| 10. Документация | 2 | 8 | 10 |
| **ИТОГО** | **27** | **332** | **359** |

## Приоритеты следующих шагов

1. **Каркас сервисов (Фаза 0)** — создать PM.Platform.*, PM.IAM.Api, PM.BFF с /health, Dockerfile, обновить compose
2. **Observability bootstrap** — поднять OTel Collector + Prometheus + Grafana, подключить к каркасам
3. **Data Layer** — миграции, таблицы, RLS
4. **IAM Backend** — расширить каркас PM.IAM.Api: REST API + gRPC, бизнес-логика
5. **BFF** — расширить каркас PM.BFF: сессии, OIDC, CSRF (Double Submit)
6. **Keycloak** — realm, clients, email templates
7. **Frontend SPA** — Angular 21
8. **Тестирование** — unit, integration, e2e + security
9. **CI/CD** — pipelines

---

*Документ сгенерирован на основе технических заданий проекта IAM*
