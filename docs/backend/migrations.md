# SQL Migrations — правила и best practices

> **Контекст:** PMServices использует чистый SQL без ORM  
> **Цель:** Безопасные, предсказуемые, откатываемые миграции

---

## 🎯 Основные принципы

### 1. Идемпотентность

**Правило:** Миграция должна безопасно выполняться несколько раз.

**❌ Плохо:**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL
);
```
*Проблема:* При повторном запуске упадет с ошибкой "table already exists"

**✅ Хорошо:**
```sql
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL
);
```

**✅ Еще лучше (с проверкой):**
```sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'users'
  ) THEN
    CREATE TABLE users (
      id UUID PRIMARY KEY,
      email VARCHAR(255) NOT NULL
    );
  END IF;
END
$$;
```

---

### 2. Нумерация миграций

**Формат:** `{YYYYMMDD}_{HHmm}_{description}.sql`

**Примеры:**
```
20251227_1430_create_users_table.sql
20251227_1445_add_email_verification.sql
20251228_0900_create_organizations_table.sql
```

**Почему так:**
- Сортировка гарантирует порядок выполнения
- Дата + время = уникальность (даже при параллельной работе в ветках)
- Описание = понятно что внутри

**Генератор:**
```bash
# Linux/Mac
echo "$(date +%Y%m%d_%H%M)_description.sql"

# PowerShell
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
echo "${timestamp}_description.sql"
```

---

### 3. Структура миграции

Каждая миграция должна содержать:

```sql
-- ============================================
-- Migration: 20251227_1430_create_users_table
-- Author: Your Name
-- Date: 2025-12-27
-- Description: Создание таблицы пользователей
-- ============================================

-- BEGIN TRANSACTION (опционально, зависит от логики)
BEGIN;

-- ============================================
-- FORWARD MIGRATION (применение изменений)
-- ============================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_users_email 
  ON users(email);

-- Уникальные ограничения
CREATE UNIQUE INDEX IF NOT EXISTS uniq_users_email 
  ON users(LOWER(email));

-- Комментарии (документация в БД)
COMMENT ON TABLE users IS 'Пользователи системы';
COMMENT ON COLUMN users.email IS 'Email (уникальный, case-insensitive)';

-- ============================================
-- ROLLBACK (откат изменений)
-- ============================================
-- Записываем в комментарии для ручного отката

/*
ROLLBACK SCRIPT:

DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS uniq_users_email;
DROP TABLE IF EXISTS users;

*/

COMMIT;
```

---

## 📋 Чеклист перед коммитом миграции

- [ ] Имя файла соответствует формату `YYYYMMDD_HHmm_description.sql`
- [ ] Используется `IF NOT EXISTS` / `IF EXISTS` где возможно
- [ ] Есть комментарии с описанием миграции
- [ ] Протестировано локально (запустить дважды — не должно падать)
- [ ] Есть rollback script в комментариях
- [ ] Нет хардкоженных данных (используйте INSERT с ON CONFLICT для seed-данных)
- [ ] Нет `DROP TABLE` без `IF EXISTS`
- [ ] Индексы создаются с `IF NOT EXISTS`

---

## 🔧 Типовые паттерны

### Добавление колонки

```sql
-- ✅ Идемпотентно
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'users' 
    AND column_name = 'phone'
  ) THEN
    ALTER TABLE users ADD COLUMN phone VARCHAR(20);
  END IF;
END
$$;
```

### Изменение типа колонки

```sql
-- ✅ С проверкой текущего типа
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'users' 
    AND column_name = 'phone' 
    AND data_type = 'character varying'
  ) THEN
    ALTER TABLE users ALTER COLUMN phone TYPE TEXT;
  END IF;
END
$$;
```

### Seed данные (справочники)

```sql
-- ✅ Идемпотентно через ON CONFLICT
INSERT INTO roles (id, name, description)
VALUES 
  ('550e8400-e29b-41d4-a716-446655440001', 'Owner', 'Владелец организации'),
  ('550e8400-e29b-41d4-a716-446655440002', 'Admin', 'Администратор'),
  ('550e8400-e29b-41d4-a716-446655440003', 'Member', 'Участник')
ON CONFLICT (id) DO NOTHING;
```

### Переименование таблицы

```sql
-- ✅ С проверкой
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM pg_tables 
    WHERE tablename = 'old_name'
  ) THEN
    ALTER TABLE old_name RENAME TO new_name;
  END IF;
END
$$;
```

---

## 🚨 Опасные операции

### ❌ Никогда не делайте в production миграциях:

1. **DROP без IF EXISTS**
```sql
-- ❌ ОПАСНО
DROP TABLE users;

-- ✅ БЕЗОПАСНО
DROP TABLE IF EXISTS users;
```

2. **ALTER COLUMN без проверки данных**
```sql
-- ❌ ОПАСНО (может потерять данные)
ALTER TABLE users ALTER COLUMN email TYPE VARCHAR(50);

-- ✅ БЕЗОПАСНО (сначала проверить длину)
DO $$
BEGIN
  IF (SELECT MAX(LENGTH(email)) FROM users) <= 50 THEN
    ALTER TABLE users ALTER COLUMN email TYPE VARCHAR(50);
  ELSE
    RAISE EXCEPTION 'Cannot shrink email column: data would be truncated';
  END IF;
END
$$;
```

3. **Изменение PRIMARY KEY**
```sql
-- ❌ Очень опасно
-- Вместо этого создайте новую таблицу и мигрируйте данные
```

4. **Массовые UPDATE без WHERE**
```sql
-- ❌ КАТАСТРОФА
UPDATE users SET role = 'admin';

-- ✅ Всегда с условием
UPDATE users SET role = 'admin' WHERE email = 'admin@example.com';
```

---

## 🧪 Тестирование миграций

### Локально (обязательно перед коммитом):

```bash
# 1. Применить миграцию
psql -h localhost -U postgres -d pmservices < Migrations/20251227_1430_create_users_table.sql

# 2. Проверить что применилась
psql -h localhost -U postgres -d pmservices -c "\dt"

# 3. Применить повторно (должно быть ОК)
psql -h localhost -U postgres -d pmservices < Migrations/20251227_1430_create_users_table.sql

# 4. Проверить rollback (из комментариев)
# Скопировать ROLLBACK SCRIPT из миграции
psql -h localhost -U postgres -d pmservices -c "DROP TABLE IF EXISTS users;"
```

### В CI (автоматически):

CI проверяет:
1. Нумерация корректна (нет дубликатов, нет пропусков)
2. SQL синтаксис валиден (pg_dump --schema-only)
3. Миграции идемпотентны (запускает дважды)

---

## 📊 Tracking применённых миграций

### Вариант 1: Таблица migrations (рекомендуется)

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(50) PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);

-- В каждой миграции в конце:
INSERT INTO schema_migrations (version) 
VALUES ('20251227_1430')
ON CONFLICT (version) DO NOTHING;
```

### Вариант 2: Скрипт применения

```bash
#!/bin/bash
# apply-migrations.sh

MIGRATIONS_DIR="./Migrations"
DB_URL="postgresql://postgres:postgres@localhost:5432/pmservices"

for migration in $(ls $MIGRATIONS_DIR/*.sql | sort); do
  echo "Applying: $migration"
  psql $DB_URL < $migration
  
  if [ $? -ne 0 ]; then
    echo "❌ Migration failed: $migration"
    exit 1
  fi
done

echo "✅ All migrations applied"
```

---

## 🎓 Best Practices Summary

| Что | Как | Почему |
|-----|-----|--------|
| Создание таблицы | `CREATE TABLE IF NOT EXISTS` | Идемпотентность |
| Добавление колонки | `DO $$ ... IF NOT EXISTS ...` | Безопасность |
| Seed данные | `INSERT ... ON CONFLICT DO NOTHING` | Можно запускать повторно |
| Удаление | `DROP ... IF EXISTS` | Не падает если уже удалено |
| Индексы | `CREATE INDEX IF NOT EXISTS` | Идемпотентность |
| Имя файла | `YYYYMMDD_HHmm_description.sql` | Порядок + уникальность |
| Rollback | В комментариях миграции | Быстрый откат при проблемах |
| Транзакции | Используйте BEGIN/COMMIT | Атомарность |

---

## 🔍 CI Проверка миграций

Добавлено в `.github/workflows/ci.yml`:

```yaml
migration-check:
  name: Validate SQL Migrations
  runs-on: ubuntu-latest
  
  steps:
    - uses: actions/checkout@v4
    
    - name: Check migration naming
      run: |
        cd Migrations
        for file in *.sql; do
          if [[ ! $file =~ ^[0-9]{8}_[0-9]{4}_.*\.sql$ ]]; then
            echo "❌ Invalid migration name: $file"
            echo "Expected format: YYYYMMDD_HHmm_description.sql"
            exit 1
          fi
        done
        echo "✅ All migration names valid"
    
    - name: Check for duplicates
      run: |
        cd Migrations
        duplicates=$(ls *.sql | cut -d'_' -f1-2 | sort | uniq -d)
        if [ -n "$duplicates" ]; then
          echo "❌ Duplicate migration timestamps found:"
          echo "$duplicates"
          exit 1
        fi
        echo "✅ No duplicate timestamps"
    
    - name: Test idempotency
      run: |
        docker run -d --name pg-test \
          -e POSTGRES_PASSWORD=postgres \
          -p 5555:5432 \
          postgres:18
        
        sleep 5
        
        # Apply all migrations
        for migration in $(ls Migrations/*.sql | sort); do
          psql postgresql://postgres:postgres@localhost:5555/postgres < $migration
        done
        
        # Apply again (should not fail)
        for migration in $(ls Migrations/*.sql | sort); do
          psql postgresql://postgres:postgres@localhost:5555/postgres < $migration
        done
        
        echo "✅ Migrations are idempotent"
```

---

## 🆘 Troubleshooting

### Миграция зависла

```sql
-- Найти активные запросы
SELECT pid, query, state 
FROM pg_stat_activity 
WHERE state != 'idle';

-- Убить зависший процесс
SELECT pg_terminate_backend(PID);
```

### Откат миграции

```sql
-- Вручную применить ROLLBACK SCRIPT из комментариев миграции
-- Удалить запись из schema_migrations
DELETE FROM schema_migrations WHERE version = '20251227_1430';
```

### Конфликт миграций в Git

```bash
# При мерже двух веток с миграциями — переименовать одну:
mv Migrations/20251227_1430_feature_a.sql \
   Migrations/20251227_1445_feature_a.sql
   
# Обновить дату в файле и закоммитить
```

---

**Последнее обновление:** 27 декабря 2025  
**Версия:** 1.0
