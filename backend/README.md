# Backend (вариант B)

Здесь живёт весь .NET-слой (решение, проекты, Dockerfile).

## Что где

- `PMServices.sln` — единая точка сборки для всех backend-проектов
- `src/PMServices/` — хост-приложение (Web API / BFF)
- `src/<ModuleName>.*` — будущие модули (IAM, Projects, Organizations и т.д.)
- `Dockerfile` — сборка/запуск backend в контейнере

## Добавление нового модуля

1) Создать проект(ы) модуля в `backend/src/` (например `PMServices.IAM.Domain`, `PMServices.IAM.Application`, `PMServices.IAM.Infrastructure`).
2) Подключить проекты в `backend/PMServices.sln`.
3) Привязать зависимости:
   - Domain не зависит ни от чего внешнего
   - Application зависит от Domain
   - Infrastructure реализует интерфейсы Application
   - Host (PMServices) подключает Infrastructure через DI

## Контейнерная сборка

Контейнер собирается из `backend/Dockerfile`.
`ops/compose.yml` использует build-context `../backend`, поэтому Dockerfile не зависит от наличия фронта/доков.
