# Events — Outbox + Redis Streams

## Паттерн

```
Service (в транзакции) → outbox_events (таблица) → Dispatcher → Redis Streams
```

## Таблица Outbox

```sql
CREATE TABLE outbox_events (
    id UUID PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ NULL
);
```

## Redis Streams

- Stream: `pmservices.iam.events`
- Retention: `MAXLEN ~500000`
- Consumer Groups для разных обработчиков

## Consumer Groups

| Group | Назначение |
|-------|------------|
| `iam-cache` | Инвалидация кэша |
| `iam-audit` | Запись в аудит |

## См. также

- [modules/iam/api/events](../modules/iam/api/events.md) — события IAM
