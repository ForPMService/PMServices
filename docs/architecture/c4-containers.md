# C4 Containers

## Контейнеры

| Контейнер | Технология | Порт (dev) |
|-----------|------------|------------|
| SPA | Angular 21 | 4200 |
| API | ASP.NET Core | 5000 |
| Database | PostgreSQL 18 | 15432 |
| Cache | Redis 8.4 | 6379 |
| Auth | Keycloak 26 | 8085 |
| Mail | Mailpit | 8025 |

## Связи

```
SPA → API (REST/JSON)
SPA → Keycloak (OIDC)
API → Database (SQL)
API → Redis (Cache, Events)
API → Keycloak (JWT validation)
```

## Диаграмма

См. `_assets/diagrams/c4-containers.svg`

TODO: Создать PlantUML диаграмму
