# ADR-0003: Token Storage for SPA

## Status

Accepted

## Context

Где хранить токены в SPA (Angular)?

Варианты:
1. localStorage — уязвим к XSS
2. sessionStorage — теряется при закрытии вкладки
3. Memory + Refresh — безопаснее, но сложнее
4. HttpOnly Cookie — требует BFF

## Decision

Используем **angular-auth-oidc-client** с настройками:
- Access token хранится в memory
- Refresh token в sessionStorage (или silent refresh через iframe)
- Не используем localStorage для токенов

## Consequences

### Положительные

- Защита от XSS (токен не в localStorage)
- Стандартная библиотека с поддержкой PKCE

### Отрицательные

- При обновлении страницы — silent refresh
- Сложнее дебажить
