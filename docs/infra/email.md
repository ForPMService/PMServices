# Email

> Настройки почты для dev и prod.

## Сценарии использования

| Сценарий | Когда |
|----------|-------|
| Email verification | После регистрации |
| Password reset | Forgot password |
| Invite | Приглашение в организацию |
| Notifications | Уведомления (будущее) |

## Development (Mailpit)

| Параметр | Значение |
|----------|----------|
| SMTP Host | `mailpit` (в Docker) / `localhost` |
| SMTP Port | 1025 |
| Web UI | http://localhost:8025 |
| Auth | Не требуется |
| TLS | Не требуется |

### Проверка писем

1. Открыть http://localhost:8025
2. Все отправленные письма видны в inbox
3. Можно кликать ссылки для тестирования

## Production

### Требования

| Требование | Описание |
|------------|----------|
| SPF | DNS запись для авторизации отправителя |
| DKIM | Подпись писем |
| DMARC | Политика обработки |
| TLS | Обязательно для SMTP |

### Рекомендуемые ESP

- SendGrid
- AWS SES
- Mailgun

### Конфигурация

```
Mail__Smtp__Host=smtp.sendgrid.net
Mail__Smtp__Port=587
Mail__Smtp__Username=apikey
Mail__Smtp__Password=<API_KEY>
Mail__Smtp__UseTls=true
Mail__From=noreply@pmservices.com
```

## Шаблоны писем

| Шаблон | Переменные |
|--------|------------|
| `email-verification` | `{name}`, `{link}`, `{expires}` |
| `password-reset` | `{name}`, `{link}`, `{expires}` |
| `invite` | `{inviterName}`, `{orgName}`, `{link}`, `{expires}` |

### Требования к шаблонам

- HTML + plaintext версии
- Responsive design
- Ссылки с TTL (24h для verify, 1h для reset)
- Unsubscribe link (для notifications)

## Rate Limiting

| Тип | Лимит |
|-----|-------|
| Verification resend | 3/hour per email |
| Password reset | 3/hour per email |
| Invites | 10/hour per user |

## См. также

- [01-Local-Dev](./local-dev.md) — запуск Mailpit
- [modules/iam/01-Overview](../modules/iam/overview.md) — email сценарии

