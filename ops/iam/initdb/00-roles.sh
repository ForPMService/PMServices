#!/usr/bin/env bash
# ops/iam/initdb/00-roles.sh
# Создаёт роли БД для IAM-модуля.
# Выполняется PostgreSQL ОДИН РАЗ при первом старте (docker-entrypoint-initdb.d).
# Пароли берутся из env-переменных, которые передаёт compose.iam.yml.
# Схему iam и таблицы создаёт Flyway — этот скрипт только роли.
#
# ВАЖНО: psql не интерполирует переменные :'var' и :"var" внутри DO $$ ... $$ блоков.
# Поэтому все проверки существования ролей делаются на уровне shell, а не SQL.

set -euo pipefail

# Проверяем, что все нужные переменные переданы
: "${POSTGRES_DB:?Не задана переменная POSTGRES_DB}"
: "${POSTGRES_USER:?Не задана переменная POSTGRES_USER}"
: "${IAM_APP_DB_USER:?Не задана переменная IAM_APP_DB_USER}"
: "${IAM_APP_DB_PASSWORD:?Не задана переменная IAM_APP_DB_PASSWORD}"
: "${IAM_MIGRATOR_DB_USER:?Не задана переменная IAM_MIGRATOR_DB_USER}"
: "${IAM_MIGRATOR_DB_PASSWORD:?Не задана переменная IAM_MIGRATOR_DB_PASSWORD}"

# Хелпер: выполнить SQL как суперпользователь
pg() {
    psql -v ON_ERROR_STOP=1 \
         --username "$POSTGRES_USER" \
         --dbname "$POSTGRES_DB" \
         "$@"
}

# Хелпер: роль существует?
role_exists() {
    pg -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$1'" | grep -q 1
}

# ── Роль мигратора (Flyway — DDL, создание схем и таблиц) ──────────────────
if role_exists "$IAM_MIGRATOR_DB_USER"; then
    echo "  → роль '$IAM_MIGRATOR_DB_USER' уже существует, пропускаем CREATE"
else
    pg -c "CREATE ROLE \"${IAM_MIGRATOR_DB_USER}\" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT"
    echo "  ✓ роль '${IAM_MIGRATOR_DB_USER}' создана"
fi

# ── Роль приложения (runtime — только DML, без DDL) ────────────────────────
if role_exists "$IAM_APP_DB_USER"; then
    echo "  → роль '$IAM_APP_DB_USER' уже существует, пропускаем CREATE"
else
    pg -c "CREATE ROLE \"${IAM_APP_DB_USER}\" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT"
    echo "  ✓ роль '${IAM_APP_DB_USER}' создана"
fi

# ── Пароли (устанавливаем/обновляем всегда) ────────────────────────────────
# dollar-quoting безопасен даже если пароль содержит спецсимволы
pg -c "ALTER ROLE \"${IAM_MIGRATOR_DB_USER}\" PASSWORD \$pwd\$${IAM_MIGRATOR_DB_PASSWORD}\$pwd\$"
pg -c "ALTER ROLE \"${IAM_APP_DB_USER}\"      PASSWORD \$pwd\$${IAM_APP_DB_PASSWORD}\$pwd\$"
echo "  ✓ пароли установлены"

# ── Права на БД ────────────────────────────────────────────────────────────
# Убираем дефолтные права PUBLIC
pg -c "REVOKE ALL ON DATABASE \"${POSTGRES_DB}\" FROM PUBLIC"

pg -c "GRANT CONNECT          ON DATABASE \"${POSTGRES_DB}\" TO \"${IAM_APP_DB_USER}\""
pg -c "GRANT CONNECT, CREATE  ON DATABASE \"${POSTGRES_DB}\" TO \"${IAM_MIGRATOR_DB_USER}\""
echo "  ✓ права на БД выданы"

# ── Владелец БД → мигратор (Flyway работает от его имени) ──────────────────
pg -c "ALTER DATABASE \"${POSTGRES_DB}\" OWNER TO \"${IAM_MIGRATOR_DB_USER}\""
echo "  ✓ владелец БД: '${IAM_MIGRATOR_DB_USER}'"

# ── public schema ──────────────────────────────────────────────────────────
pg -c "REVOKE ALL ON SCHEMA public FROM PUBLIC"
pg -c "GRANT USAGE ON SCHEMA public TO \"${IAM_APP_DB_USER}\", \"${IAM_MIGRATOR_DB_USER}\""
echo "  ✓ права на схему public выданы"

echo ""
echo "✓ Роли IAM созданы: ${IAM_APP_DB_USER}, ${IAM_MIGRATOR_DB_USER}"
