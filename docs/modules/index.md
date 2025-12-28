# Модули

Бизнес-модули платформы PMServices.

## Доступные модули

| Модуль | Статус | Описание |
|--------|--------|----------|
| [IAM](./iam/index.md) | 🚧 В разработке | Identity & Access Management |

## Структура модуля

Каждый модуль следует единой структуре:

```
modules/<name>/
├── index.md          # Обзор модуля
├── overview.md       # Детальное описание
├── api/
│   ├── openapi-ref.md   # REST API
│   └── events.md        # Redis Streams события
├── data/
│   └── schema.md        # Схема БД
├── ui/
│   ├── routes.md        # Angular роуты
│   └── pages.md         # Описание страниц
└── dev/
    ├── plan.md          # План разработки
    └── prompts.md       # Промпты для ИИ
```

## Добавление нового модуля

1. Скопировать `modules/_template/` в `modules/<name>/`
2. Заполнить документацию
3. Создать проекты в `backend/src/PMServices.<Name>.*`
4. Создать feature в `pmservices-web/src/app/features/<name>/`
