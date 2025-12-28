# Backend Patterns

## Документы

- [Архитектура](./architecture.md) — структура кода
- [База данных](./database.md) — PostgreSQL conventions
- [Миграции](./migrations.md) — SQL миграции
- [События](./events.md) — Outbox + Redis Streams

## Принципы

- Модульный монолит (Modules/)
- Без ORM — чистый SQL через Npgsql
- Async везде
- Идемпотентные миграции

## Код

Код генерируется через промпты в `modules/*/dev/prompts.md`
