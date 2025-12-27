# Backend Patterns

## Документы

- [01-Architecture](./architecture.md) — структура кода
- [02-Database](./database.md) — PostgreSQL conventions
- [03-Migrations](./migrations.md) — SQL миграции
- [04-Events](./events.md) — Outbox + Redis Streams

## Принципы

- Модульный монолит (Modules/)
- Без ORM — чистый SQL через Npgsql
- Async везде
- Идемпотентные миграции

## Код

Код генерируется через промпты в `06-Modules/*/dev/prompts.md`


