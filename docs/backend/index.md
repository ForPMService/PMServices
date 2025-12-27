# Backend Patterns

## Документы

- [01-Architecture](./01-Architecture.md) — структура кода
- [02-Database](./02-Database.md) — PostgreSQL conventions
- [03-Migrations](./03-Migrations.md) — SQL миграции
- [04-Events](./04-Events.md) — Outbox + Redis Streams

## Принципы

- Модульный монолит (Modules/)
- Без ORM — чистый SQL через Npgsql
- Async везде
- Идемпотентные миграции

## Код

Код генерируется через промпты в `06-Modules/*/dev/PROMPTS.md`
