# Infrastructure

## Документы

- [01-Local-Dev](./01-Local-Dev.md) — запуск локально
- [02-Keycloak-Setup](./02-Keycloak-Setup.md) — настройка Keycloak
- [03-Env-Config](./03-Env-Config.md) — переменные окружения
- [05-Observability](./05-Observability.md) — логи, метрики, аудит
- [06-Email](./06-Email.md) — почта (Mailpit / ESP)

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
