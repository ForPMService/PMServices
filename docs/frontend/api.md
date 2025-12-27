# Frontend API

## Принцип

Каждый feature имеет свой API сервис:
- `IamApiService`
- `ProjectsApiService`

## Генерация типов

```bash
npx openapi-typescript ../openapi.yaml -o src/api/generated.types.ts
```

## Dev Proxy

```json
// proxy.conf.json
{
  "/api": {
    "target": "http://localhost:4010",  // Prism mock
    "secure": false
  }
}
```

## Error Handling

Стандартный формат ошибок:
```
{
  "code": "IAM-001",
  "message": "Email already registered"
}
```

Обработка через Error Interceptor.
