# Auth Overview

## Аутентификация

- **Flow:** Authorization Code + PKCE
- **Provider:** Keycloak
- **Токены:** Access (5 мин), Refresh (30 мин)

## Авторизация (RBAC)

```
User → Membership → Organization
         ↓
       Role → Permission[]
```

## Проверка прав

1. JWT валидация (middleware)
2. Проверка membership в организации
3. Проверка permission

## Кэширование

- Ключ: `iam:perm:{orgId}:{userId}`
- TTL: 5 минут
- Инвалидация: через Redis Streams события

## См. также

- [06-Modules/IAM](../06-Modules/IAM/00-Index.md) — реализация
- [90-ADR/0003-token-storage](../90-ADR/0003-token-storage-spa.md) — решение по токенам
