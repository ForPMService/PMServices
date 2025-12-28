# Репозиторий — вариант B (самодостаточные части)

## Цель
Сделать так, чтобы **backend**, **frontend**, **ops** и **docs** жили в одном репозитории,
но были **минимально связаны**: каждую часть можно развивать и собирать отдельно.

## Принцип
- `backend/` — всё .NET: решение, проекты, dockerfile.
- `pmservices-web/` — всё Angular: зависимости Node, сборка, окружения фронта.
- `ops/` — окружение: compose, env, initdb, импорт realm.
- `docs/` — документация как код.

Это снижает “перетекание” артефактов (node_modules в бэкенд, bin/obj в ops и т.д.)
и упрощает CI/CD (можно собирать только нужную часть).

## Структура (рекомендуемая)
```
/
├── ops/
│   ├── compose.yml
│   ├── .env(.example)
│   └── keycloak/import/
├── backend/
│   ├── PMServices.sln
│   ├── Dockerfile
│   ├── src/
│   │   ├── PMServices/                 # host (Web API)
│   │   ├── PMServices.IAM.Domain/
│   │   ├── PMServices.IAM.Application/
│   │   └── ...
│   └── migrations/ (если миграции SQL)
├── pmservices-web/
└── docs/
```

## Как расти, если мы не знаем сколько будет модулей
- Каждый модуль = набор проектов в `backend/src/`, название начинается с `PMServices.<Module>.`
- В `backend/PMServices.sln` добавляем проекты постепенно (Visual Studio / dotnet sln).
- Dockerfile делает `restore` по решению — новые проекты автоматически учитываются.
