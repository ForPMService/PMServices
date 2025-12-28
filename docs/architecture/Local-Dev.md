# Локальная разработка

## Команды (самое частое)

### Инфраструктура
```bash
cd ops
cp .env.example .env
docker compose up -d
```

### Backend
```bash
cd backend
dotnet build PMServices.sln
dotnet run --project src/PMServices/PMServices.csproj
```

### Frontend
```bash
cd pmservices-web
npm i
npm start
```

## Порты (по умолчанию)
- API: 8080
- Keycloak: 8081
- Mailpit UI: 8025
- Postgres app: 5432
- Postgres keycloak: 5433
- Redis: 6379

## Что проверять при первом запуске
- `docker compose ps` — все сервисы Up/healthy
- Keycloak открывается в браузере
- API отвечает (хотя бы health endpoint, когда добавишь)
- фронт стартует без ошибок зависимостей

## Критерии “готово”
- окружение поднимается одной командой из `ops/`
- backend собирается и запускается без ручной правки путей
- frontend живёт отдельно и не зависит от папки backend
