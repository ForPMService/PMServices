# PMServices — Documentation

## Quick Start

| Задача | Документ |
|--------|----------|
| Поднять локально | [infra/01-Local-Dev](./infra/local-dev.md) |
| Понять архитектуру | [03-Architecture](./architecture/index.md) |
| Начать разработку IAM | [06-Modules/IAM](./modules/iam/index.md) |

## Структура

```
docs/
├── architecture/     # C4, общая картина
├── backend/          # .NET паттерны (описания, не код)
├── frontend/         # Angular паттерны (описания, не код)
├── 06-Modules/          # Бизнес-модули
│   └── IAM/             # Первый модуль
├── infra/            # Docker, Keycloak
└── adr/              # Решения
```

## Принцип

- **Документация** = спецификация (ЧТО делать)
- **prompts.md** = инструкции для ИИ (КАК генерировать код)
- **Код** = генерируется по промптам


