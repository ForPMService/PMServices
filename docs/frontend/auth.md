# Frontend Auth

## Библиотека

`angular-auth-oidc-client`

## Конфигурация

| Параметр | Значение |
|----------|----------|
| Authority | `http://localhost:8085/realms/pmservices` |
| Client ID | `pmservices-spa` |
| Scope | `openid profile email` |
| Response Type | `code` (PKCE) |

## Компоненты

| Компонент | Назначение |
|-----------|------------|
| AuthService | Обёртка над OIDC |
| authGuard | Защита роутов |
| authInterceptor | Добавление токена |

## Keycloak Client

- Type: Public
- Standard Flow: Enabled
- Valid Redirect URIs: `http://localhost:4200/*`
