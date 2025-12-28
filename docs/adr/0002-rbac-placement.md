# ADR-0002: RBAC Placement

## Status

Accepted

## Context

Где реализовывать RBAC логику — в Keycloak или в приложении?

## Decision

RBAC реализуется **в приложении (IAM модуль)**:
- Keycloak отвечает только за аутентификацию
- PMServices хранит роли, permissions, memberships
- Метод `Can(userId, orgId, permission)` — источник истины

## Consequences

### Положительные

- Полный контроль над моделью ролей
- Гибкость: роли привязаны к организациям
- Кэширование в Redis

### Отрицательные

- Дополнительная сложность в IAM модуле
- Keycloak токены не содержат permissions (нужен запрос к API)
