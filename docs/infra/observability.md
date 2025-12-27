# Observability

> Логирование, метрики, трейсы.

## Structured Logging

### Обязательные поля

| Поле | Описание |
|------|----------|
| `timestamp` | ISO 8601 |
| `level` | Debug/Info/Warning/Error |
| `message` | Текст |
| `correlationId` | ID запроса (из header или генерируем) |
| `userId` | Если авторизован |
| `organizationId` | Текущая организация |
| `module` | IAM/Projects/... |
| `action` | registration/login/invite/... |

### Формат

```json
{
  "timestamp": "2024-12-27T12:00:00Z",
  "level": "Info",
  "message": "User registered",
  "correlationId": "req-123",
  "userId": "user-456",
  "organizationId": "org-789",
  "module": "IAM",
  "action": "registration"
}
```

## Уровни логирования

| Level | Когда |
|-------|-------|
| Debug | Детали для отладки (dev only) |
| Info | Бизнес-события (регистрация, логин) |
| Warning | Потенциальные проблемы (rate limit близко) |
| Error | Ошибки, требующие внимания |

## Аудит (Security Events)

Обязательно логировать:
- Успешный/неуспешный логин
- Регистрация
- Password reset request
- Role assignment
- Session revoke
- Account lockout

## Метрики (будущее)

| Метрика | Тип |
|---------|-----|
| `http_requests_total` | Counter |
| `http_request_duration_seconds` | Histogram |
| `auth_failures_total` | Counter |
| `active_sessions` | Gauge |

## Трейсы (будущее)

OpenTelemetry для распределённой трассировки.

## Инфраструктура

| Окружение | Решение |
|-----------|---------|
| Dev | Console output (JSON) |
| Prod | ELK Stack / Loki |

## См. также

- [backend/04-Events](../backend/events.md) — события для аудита
- [modules/iam/api/events](../modules/iam/api/events.md) — IAM события

