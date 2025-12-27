# Security Baseline

> Минимальные требования безопасности.

## Принципы

1. **Аутентификация делегируется Keycloak** (OIDC + PKCE)
2. **Авторизация — RBAC** в приложении
3. **Defense in depth** — несколько уровней защиты
4. **Fail secure** — при ошибке — запретить доступ

## OWASP Top 10

| Угроза | Защита |
|--------|--------|
| **Injection** | Параметризованные SQL запросы (Npgsql) |
| **Broken Auth** | Keycloak, PKCE, secure token storage |
| **Sensitive Data** | TLS, шифрование secrets |
| **XXE** | Не используем XML |
| **Broken Access** | RBAC проверки на каждом endpoint |
| **Misconfiguration** | Secure defaults, env validation |
| **XSS** | Angular sanitization, CSP headers |
| **Insecure Deserialization** | Только JSON, валидация |
| **Vulnerable Components** | Dependabot, регулярные обновления |
| **Logging** | Structured logs, audit trail |

## TLS

| Окружение | Требование |
|-----------|------------|
| Dev | HTTP допустим (localhost) |
| Prod | **HTTPS обязателен** (TLS 1.2+) |

### Headers (prod)

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'; ...
```

## Secrets Management

### Запрещено

- ❌ Secrets в коде
- ❌ Secrets в git
- ❌ Secrets в логах

### Разрешено

| Окружение | Хранение |
|-----------|----------|
| Dev | `.env` файл (в `.gitignore`) |
| Prod | Environment variables / Vault |

## Password Policy

Через Keycloak:
- Минимум 12 символов
- Uppercase + lowercase + digit
- Проверка на утечки (haveibeenpwned)

## Anti-Bruteforce

| Механизм | Настройка |
|----------|-----------|
| Account lockout | 5 попыток → блокировка 15 мин |
| Rate limiting | По IP + по email |
| Captcha | После 3 неудачных попыток (будущее) |

## Session Security

| Параметр | Значение |
|----------|----------|
| Access Token TTL | 5 минут |
| Refresh Token TTL | 30 минут |
| Idle timeout | 30 минут |
| Absolute timeout | 8 часов |
| Concurrent sessions | Разрешены (с возможностью revoke) |

## CORS

```
Access-Control-Allow-Origin: https://app.pmservices.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Allow-Credentials: true
```

## Input Validation

- Server-side валидация обязательна
- Client-side — только для UX
- Whitelist подход (разрешённые значения)

## Audit Trail

Логировать все security events:
- Login success/failure
- Password changes
- Permission changes
- Admin actions

См. [infra/05-Observability](../infra/observability.md)

## См. также

- [03-Auth-Overview](./auth-overview.md) — аутентификация
- [06-Modules/IAM](../modules/iam/index.md) — реализация
- [90-ADR](../adr/index.md) — решения по безопасности

