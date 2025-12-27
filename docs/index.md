# PMServices — Documentation

## Quick Start

| Задача | Документ |
|--------|----------|
| Поднять локально | [07-Infra/01-Local-Dev](./07-Infra/01-Local-Dev.md) |
| Понять архитектуру | [03-Architecture](./03-Architecture/00-Index.md) |
| Начать разработку IAM | [06-Modules/IAM](./06-Modules/IAM/00-Index.md) |

## Структура

```
docs/
├── 03-Architecture/     # C4, общая картина
├── 04-Backend/          # .NET паттерны (описания, не код)
├── 05-Frontend/         # Angular паттерны (описания, не код)
├── 06-Modules/          # Бизнес-модули
│   └── IAM/             # Первый модуль
├── 07-Infra/            # Docker, Keycloak
└── 90-ADR/              # Решения
```

## Принцип

- **Документация** = спецификация (ЧТО делать)
- **PROMPTS.md** = инструкции для ИИ (КАК генерировать код)
- **Код** = генерируется по промптам
