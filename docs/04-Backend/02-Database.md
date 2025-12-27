# Database Conventions

## Именование

| Объект | Формат | Пример |
|--------|--------|--------|
| Таблица | snake_case, plural | `users` |
| Колонка | snake_case | `created_at` |
| PK | `id` (UUID) | `id UUID PRIMARY KEY` |
| FK | `{table}_id` | `organization_id` |
| Index | `idx_{table}_{cols}` | `idx_users_email` |

## Стандартные колонки

Каждая таблица:
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

## Типы

| PostgreSQL | C# |
|------------|-----|
| UUID | Guid |
| TIMESTAMPTZ | DateTimeOffset |
| JSONB | JsonDocument |
