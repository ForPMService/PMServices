# Backend Architecture

## Структура

```
src/
├── PMServices/
│   ├── Program.cs
│   ├── Modules/
│   │   ├── IAM/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   ├── Repositories/
│   │   │   └── Events/
│   │   └── Projects/
│   └── Shared/
│       ├── Database/
│       ├── Redis/
│       └── Auth/
└── PMServices.Tests/
```

## Слои модуля

| Слой | Ответственность |
|------|-----------------|
| Controllers | HTTP, валидация, DTO |
| Services | Бизнес-логика |
| Repositories | SQL, Npgsql |
| Events | Outbox → Redis Streams |

## DI

Каждый модуль регистрируется в `Program.cs`:
```
builder.Services.AddIAMModule();
builder.Services.AddProjectsModule();
```
