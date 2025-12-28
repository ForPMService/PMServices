# Infrastructure

## Документы

- [Локальная разработка](./local-dev.md) — запуск локально
- [Настройка Keycloak](./keycloak-setup.md) — настройка Keycloak
- [Переменные окружения](./env-config.md) — переменные окружения
- [Observability](./observability.md) — логи, метрики, аудит (ELK)
- [Email](./email.md) — почта (Mailpit / ESP)

## Docker Compose

Файл: `ops/compose.yml`

### Базовый запуск

```bash
cd ops
docker compose up -d
```

### С Observability (ELK)

```bash
docker compose --profile observability up -d
```

## Порты (dev)

| Service | Port | Описание |
|---------|------|----------|
| API | 8080 (внутр.) → `${API_HTTP_PORT}` | .NET Backend |
| SPA | 4200 | Angular (ng serve) |
| PostgreSQL (app) | `${APP_DB_PORT}` → 5432 | БД приложения |
| PostgreSQL (keycloak) | `${KC_DB_PORT}` → 5432 | БД Keycloak |
| Redis | `${REDIS_PORT}` → 6379 | Кэш + Streams |
| Keycloak | `${KEYCLOAK_HTTP_PORT}` → 8080 | IdP |
| Mailpit Web | `${MAILPIT_WEB_PORT}` → 8025 | Email UI |
| Mailpit SMTP | `${MAILPIT_SMTP_PORT}` → 1025 | SMTP сервер |

### Observability (профиль)

| Service | Port | Описание |
|---------|------|----------|
| Elasticsearch | 9200 | Хранение логов |
| Kibana | 5601 | UI для логов |

## Сети и volumes

- **Сеть:** `pmnet` (bridge)
- **Volumes:** `pg_app`, `pg_keycloak`, `redis_data`, `es_data`
