# Infrastructure

## Документы

- [01-Local-Dev](./local-dev.md) — запуск локально
- [02-Keycloak-Setup](./keycloak-setup.md) — настройка Keycloak
- [03-Env-Config](./env-config.md) — переменные окружения
- [05-Observability](./observability.md) — логи, метрики, аудит
- [06-Email](./email.md) — почта (Mailpit / ESP)

## Docker Compose

Файл: `ops/compose.yml`

## Порты (dev)

| Service | Port |
|---------|------|
| API | 5000 |
| SPA | 4200 |
| PostgreSQL | 15432 |
| Redis | 6379 |
| Keycloak | 8085 |
| Mailpit | 8025 |

