# PMServices — Documentation Index

Документация PMServices ведётся как **docs-as-code** (документация как код: хранится в репозитории рядом с кодом, меняется через PR, проходит review, версионируется Git’ом).
Цель — чтобы через 6–12+ месяцев документация оставалась **управляемой**, а новый разработчик мог:
- поднять проект локально;
- понять архитектуру и IAM/RBAC;
- безопасно вносить изменения без “устных легенд”.

---

## 1) Start here (куда идти в первую очередь)

1) **Правила документации и как не устроить хаос**  
→ [01-Overview](./01-Overview.md)

2) **Словарь терминов (единые определения)**  
→ [02-Glossary](./02-Glossary.md)

3) **Архитектурная точка истины** (C4, Auth/IAM/RBAC, модель данных, контракты API, логирование)  
→ [03-Architecture/00-Architecture-Index](./03-Architecture/00-Architecture-Index.md)

4) **Инфраструктура и запуск** (Docker Compose, env, препрод, runbook)  
→ [04-Infra/00-Infra-Index](./04-Infra/00-Infra-Index.md)

5) **Frontend (Angular)** (старт, Keycloak, interceptor/guards, env)  
→ [05-Frontend/00-Frontend-Index](./05-Frontend/00-Frontend-Index.md)

6) **Design / UI Kit** (токены, правила компонентов)  
→ [06-Design/00-Design-Index](./06-Design/00-Design-Index.md)

7) **Решения (ADR)** — Architectural Decision Record (запись решения: контекст → решение → последствия)  
→ [90-ADR/README](./90-ADR/README.md)

---

## 2) Быстрый старт (локальная разработка: “поднять и увидеть ping”)

> Детальная инструкция живёт в `04-Infra/01-Local-Dev-Docker.md` и `05-Frontend/01-Start.md`. Здесь — короткий “маршрут”.

### 2.1 Поднять инфраструктуру (Docker)
- Инфраструктура описана в: `ops/compose.yml`
- Переменные окружения: `ops/.env` (как правило, **не коммитится**, хранится локально)

Минимальная логика:
1) Убедиться, что есть `ops/.env` (если нет — создать по шаблону из infra-доков)  
2) Запустить контейнеры через Compose (см. `04-Infra/01-Local-Dev-Docker.md`)  
3) Проверить, что поднялись Postgres (приложение), Postgres (Keycloak), Redis, Keycloak и т.п.

### 2.2 Запустить Backend API
- Backend точка входа: `PMServices/Program.cs`
- После запуска API должна быть доступна проверка `/api/ping` (dev-сценарий)

Проверка:
- `http://localhost:<API_PORT>/api/ping` → ожидается JSON вида `{ ok: true, ts: ... }`

### 2.3 Запустить Frontend (Angular dev server) и связку с API
- Фронт лежит в `pmservices-web/`
- Для локальной связки используется dev-proxy `proxy.conf.json`, чтобы запросы `/api/*` шли на backend без CORS-ада.

Проверка:
1) открыть фронт `http://localhost:<FE_PORT>/`  
2) убедиться, что вызов `/api/ping` работает через прокси (см. `05-Frontend/01-Start.md`)

---

## 3) Documentation map (карта разделов)

| Раздел | Что внутри | Главный документ |
|---|---|---|
| `00-Index.md` | корневая навигация, пути чтения | этот файл |
| `01-Overview.md` | правила docs-as-code, single source of truth, ADR, review | [01-Overview](./01-Overview.md) |
| `02-Glossary.md` | термины и аббревиатуры проекта | [02-Glossary](./02-Glossary.md) |
| `03-Architecture/` | архитектурные спецификации (C4, IAM/RBAC, data model, contracts, observability) | [00-Architecture-Index](./03-Architecture/00-Architecture-Index.md) |
| `03-Modules/` | спецификации модулей (IAM, Organizations, Projects) | индексы модулей |
| `04-Infra/` | запуск, env, препрод, runbook | [00-Infra-Index](./04-Infra/00-Infra-Index.md) |
| `05-Frontend/` | Angular, Keycloak, security patterns | [00-Frontend-Index](./05-Frontend/00-Frontend-Index.md) |
| `06-Design/` | UI Kit, токены, правила компонентов | [00-Design-Index](./06-Design/00-Design-Index.md) |
| `90-ADR/` | решения и их причины | [ADR README](./90-ADR/README.md) |
| `_assets/` | диаграммы и изображения для docs | `_assets/diagrams`, `_assets/images` |

---

## 4) Reading paths (маршруты чтения по ролям)

### 4.1 Я новый в проекте (onboarding)
1. [01-Overview](./01-Overview.md)  
2. [02-Glossary](./02-Glossary.md)  
3. [Architecture: Context (C4)](./03-Architecture/01-Context-C4.md)  
4. [Architecture: Containers (C4)](./03-Architecture/02-Containers-C4.md)  
5. [Architecture: Auth/IAM/RBAC](./03-Architecture/03-Auth-IAM-RBAC.md)  
6. [Infra: Local Dev Docker](./04-Infra/01-Local-Dev-Docker.md)  
7. [IAM Module Index](./03-Modules/IAM/00-IAM-Index.md)

**Результат:** понимаю контуры, умею поднять окружение, понимаю IAM/RBAC и где смотреть детали.

### 4.2 Backend developer (API/DB/модули)
1. [API Contracts](./03-Architecture/05-API-Contracts.md)  
2. [Data Model](./03-Architecture/04-Data-Model.md)  
3. Модульные доки:
   - [IAM](./03-Modules/IAM/00-IAM-Index.md)
   - [Organizations](./03-Modules/Organizations/00-Organizations-Index.md)
   - [Projects](./03-Modules/Projects/00-Projects-Index.md)

### 4.3 Frontend developer (Angular + Keycloak)
1. [Frontend Start](./05-Frontend/01-Start.md)  
2. [Auth + Keycloak](./05-Frontend/02-Auth-Keycloak.md)  
3. [Http Interceptor + Guards](./05-Frontend/03-Http-Interceptor-Guards.md)  
4. [Frontend Env Configs](./05-Frontend/04-Env-Configs.md)  
5. [Architecture: Auth/IAM/RBAC](./03-Architecture/03-Auth-IAM-RBAC.md)

### 4.4 DevOps / Infra
1. [Local Dev Docker](./04-Infra/01-Local-Dev-Docker.md)  
2. [Env Config](./04-Infra/02-Env-Config.md)  
3. [Preprod Deploy](./04-Infra/03-Preprod-Deploy.md)  
4. [Runbook](./04-Infra/04-Runbook.md)  
5. [Observability/Logging](./03-Architecture/06-Observability-Logging.md)

---

## 5) Верхнеуровневый граф документации (PlantUML)

> Рекомендуемый формат хранения диаграмм:
> - исходник: `./_assets/diagrams/docs-map.puml`
> - (опционально) сгенерированная картинка: `./_assets/diagrams/docs-map.svg`

Если картинка существует, можно подключить так:
- `![Docs Map](./_assets/diagrams/docs-map.svg)`
- Исходник: [docs-map.puml](./_assets/diagrams/docs-map.puml)

Ниже — содержимое `docs-map.puml` (можно вынести в файл один-в-один):

```plantuml
@startuml
left to right direction
skinparam linetype ortho
hide stereotype

rectangle "docs/00-Index.md" as IDX
rectangle "docs/01-Overview.md" as OVR
rectangle "docs/02-Glossary.md" as GLO

IDX --> OVR
IDX --> GLO

package "docs/03-Architecture/" as ARCH {
  rectangle "00-Architecture-Index.md" as A0
  rectangle "01-Context-C4.md" as A1
  rectangle "02-Containers-C4.md" as A2
  rectangle "03-Auth-IAM-RBAC.md" as A3
  rectangle "04-Data-Model.md" as A4
  rectangle "05-API-Contracts.md" as A5
  rectangle "06-Observability-Logging.md" as A6
  A0 --> A1
  A0 --> A2
  A0 --> A3
  A0 --> A4
  A0 --> A5
  A0 --> A6
}

package "docs/03-Modules/" as MOD {
  package "IAM/" as MIAM {
    rectangle "00-IAM-Index.md" as I0
    rectangle "01-Responsibilities.md" as I1
    rectangle "02-Endpoints.md" as I2
    rectangle "03-DB-Schema.md" as I3
    rectangle "04-Scenarios.md" as I4
    I0 --> I1
    I0 --> I2
    I0 --> I3
    I0 --> I4
  }

  package "Organizations/" as MORG {
    rectangle "00-Organizations-Index.md" as O0
    rectangle "01-Responsibilities.md" as O1
    rectangle "02-Endpoints.md" as O2
    rectangle "03-DB-Schema.md" as O3
    rectangle "04-Scenarios.md" as O4
    O0 --> O1
    O0 --> O2
    O0 --> O3
    O0 --> O4
  }

  package "Projects/" as MPRJ {
    rectangle "00-Projects-Index.md" as P0
    rectangle "01-Responsibilities.md" as P1
    rectangle "02-Endpoints.md" as P2
    rectangle "03-DB-Schema.md" as P3
    rectangle "04-Scenarios.md" as P4
    P0 --> P1
    P0 --> P2
    P0 --> P3
    P0 --> P4
  }
}

package "docs/04-Infra/" as INF {
  rectangle "00-Infra-Index.md" as F0
  rectangle "01-Local-Dev-Docker.md" as F1
  rectangle "02-Env-Config.md" as F2
  rectangle "03-Preprod-Deploy.md" as F3
  rectangle "04-Runbook.md" as F4
  F0 --> F1
  F0 --> F2
  F0 --> F3
  F0 --> F4
}

package "docs/05-Frontend/" as FE {
  rectangle "00-Frontend-Index.md" as FE0
  rectangle "01-Start.md" as FE1
  rectangle "02-Auth-Keycloak.md" as FE2
  rectangle "03-Http-Interceptor-Guards.md" as FE3
  rectangle "04-Env-Configs.md" as FE4
  FE0 --> FE1
  FE0 --> FE2
  FE0 --> FE3
  FE0 --> FE4
}

package "docs/06-Design/" as DS {
  rectangle "00-Design-Index.md" as DS0
  rectangle "01-UI-Kit.md" as DS1
  rectangle "02-Tokens-Colors-Typography.md" as DS2
  rectangle "03-Components-Rules.md" as DS3
  DS0 --> DS1
  DS0 --> DS2
  DS0 --> DS3
}

package "docs/90-ADR/" as ADR {
  rectangle "README.md" as ADR0
  rectangle "0001-tenancy-model.md" as ADR1
  rectangle "0002-rbac-placement.md" as ADR2
  rectangle "0003-token-storage-spa.md" as ADR3
  ADR0 --> ADR1
  ADR0 --> ADR2
  ADR0 --> ADR3
}

IDX --> ARCH
IDX --> MOD
IDX --> INF
IDX --> FE
IDX --> DS
IDX --> ADR

@enduml


