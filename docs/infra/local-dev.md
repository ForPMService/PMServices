# Local Development

## Prerequisites

- Docker Desktop
- .NET 10 SDK
- Node.js 22+
- Angular CLI 21

## Quick Start

```bash
# 1. Start infrastructure
cd ops
docker compose up -d

# 2. Run API
cd ../
dotnet run

# 3. Run Frontend
cd ../pmservices-web
npm install
ng serve
```

## URLs

| Service | URL |
|---------|-----|
| Frontend | http://localhost:4200 |
| API | http://localhost:5000 |
| Swagger | http://localhost:5000/swagger |
| Keycloak | http://localhost:8085 |
| Mailpit | http://localhost:8025 |

## Keycloak Admin

- URL: http://localhost:8085
- Username: `admin`
- Password: `admin`

## Database

```bash
# Connect
psql -h localhost -p 15432 -U pmservices -d pmservices

# Password: pmservices
```
