# PMServices — Architecture Index (карта архитектуры)

**Status:** Draft  
**Owner:** (указать)  
**Last reviewed:** 2025-12-20

> Здесь — “входная дверь” в архитектуру: что читать, где лежат схемы, какие решения уже зафиксированы и что менять при росте системы.

---

## 1) Что считаем архитектурой в PMServices

Архитектура — это ответы на вопросы:
- **как части системы связаны** (границы модулей, потоки, зависимости);
- **как устроены данные** (модель, изоляция, миграции);
- **как устроена безопасность** (AuthN/AuthZ, токены, роли/права);
- **как разворачиваем и наблюдаем** (инфра, логирование, метрики).

---

## 2) Маршруты чтения (с чего начать)

### 2.1 Если ты впервые в проекте
1) `01-Context-C4.md` — **C4** (C4 Model — модель архитектурных диаграмм) уровень Context: “что за система и кто вокруг”.  
2) `02-Containers-C4.md` — уровень Container: “из чего состоит” (Angular, API, Keycloak, Postgres, Redis и т.п.).  
3) `03-Auth-IAM-RBAC.md` — **IAM/RBAC** (Identity and Access Management / Role-Based Access Control) и связка с Keycloak.  
4) `04-Data-Model.md` — модель данных, tenancy/organization, ключевые сущности.  
5) `05-API-Contracts.md` — принципы контрактов API.  
6) `06-Observability-Logging.md` — логирование/наблюдаемость (observability).

### 2.2 Если ты про безопасность
- `03-Auth-IAM-RBAC.md` + ADR про хранение токенов и модель RBAC.

### 2.3 Если ты про интеграции и API
- `05-API-Contracts.md` + “Endpoints” в модульных доках `docs/03-Modules/*/02-Endpoints.md`.

---

## 3) Основные архитектурные документы (единая точка истины)

- **01-Context-C4.md** — контекст (акторы, внешние системы, границы).
- **02-Containers-C4.md** — контейнеры (SPA, API, Keycloak, базы, Redis, ELK и т.п.).
- **03-Auth-IAM-RBAC.md** — безопасность: AuthN/AuthZ, токены, RBAC, интеграция фронта/бекенда/Keycloak.
- **04-Data-Model.md** — модель данных (включая мультиарендность/организации/связи).
- **05-API-Contracts.md** — правила API: версии, ошибки, идемпотентность, пагинация.
- **06-Observability-Logging.md** — логирование, аудит, метрики/трейсы (если применяем).

---

## 4) Диаграммы (PlantUML)

**PlantUML** (язык диаграмм) → текстовые диаграммы, которые версионируются как код.  
Правило проекта: **в репо храним и `.puml`, и `.svg`** (чтобы GitHub показывал диаграммы без генерации).

### 4.1 Где лежат диаграммы
- Исходники: `docs/_assets/diagrams/**/<name>.puml`
- Рендеры:  `docs/_assets/diagrams/**/<name>.svg`

### 4.2 Каталог диаграмм (рекомендуемая база)

> Если каких-то файлов пока нет — это список “что должно появиться” по мере наполнения.

#### C4: Context / Container
- `./_assets/diagrams/architecture/c4-context.svg`  
  Исходник: `./_assets/diagrams/architecture/c4-context.puml`
- `./_assets/diagrams/architecture/c4-containers.svg`  
  Исходник: `./_assets/diagrams/architecture/c4-containers.puml`

#### Безопасность: логин/токены/права
- `./_assets/diagrams/auth/login-oidc-sequence.svg`  
  Исходник: `./_assets/diagrams/auth/login-oidc-sequence.puml`
- `./_assets/diagrams/auth/token-refresh-sequence.svg`  
  Исходник: `./_assets/diagrams/auth/token-refresh-sequence.puml`
- `./_assets/diagrams/auth/rbac-check-flow.svg`  
  Исходник: `./_assets/diagrams/auth/rbac-check-flow.puml`

#### Данные и модульность
- `./_assets/diagrams/data/tenancy-model.svg`  
  Исходник: `./_assets/diagrams/data/tenancy-model.puml`
- `./_assets/diagrams/data/core-er.svg`  
  Исходник: `./_assets/diagrams/data/core-er.puml`

#### Инфраструктура (локально / препрод)
- `./_assets/diagrams/infra/local-compose.svg`  
  Исходник: `./_assets/diagrams/infra/local-compose.puml`
- `./_assets/diagrams/infra/preprod-deploy.svg`  
  Исходник: `./_assets/diagrams/infra/preprod-deploy.puml`

---

## 5) ADR (Architectural Decision Record) — ключевые решения

ADR — “контекст → решение → последствия”, чтобы помнить *почему* выбрали именно так.

- `../90-ADR/0001-tenancy-model.md` — модель мультиарендности (tenancy).
- `../90-ADR/0002-rbac-placement.md` — где живёт RBAC (в IAM/в модулях/гибрид).
- `../90-ADR/0003-token-storage-spa.md` — хранение токенов в SPA (Single Page Application — одностраничное приложение).

> Любое решение, которое сложно откатить, должно получить ADR.

---

## 6) Как обновлять архитектуру при изменениях в коде

### 6.1 Когда обязательно менять доки
Если PR меняет:
- контракты API или поведение безопасности;
- модель данных/миграции;
- схему развёртывания/контейнеры/переменные окружения;
- кэширование/инвалидацию/очереди;
- наблюдаемость (логи/аудит/метрики).

### 6.2 Когда обязательно добавлять ADR
Если решение:
- влияет на безопасность или изоляцию данных;
- добавляет новый “стержневой” компонент (например, Kafka/ELK);
- меняет границы модулей или ответственность IAM;
- вводит новый подход (BFF, event-driven, outbox и т.п.).

---

## 7) Что добавим дальше (план расширения архитектурных доков)

Когда пойдём в препрод и начнём стабилизацию, обычно нужны ещё 2–3 документа:

1) **Non-Functional Requirements (NFR, нефункциональные требования)**  
   Что это: производительность, надёжность, безопасность, SLA/SLO.  
   Зачем: чтобы архитектура мерялась метриками, а не ощущениями.  
   Где: `docs/03-Architecture/07-NFR.md` (планируемый).

2) **Threat Model (модель угроз)**  
   Что это: список угроз + меры защиты по точкам входа.  
   Зачем: снизить риск “дыр” в Auth/tenancy.  
   Где: `docs/03-Architecture/08-Threat-Model.md` (планируемый).

3) **Eventing / Messaging (события/очереди)**  
   Что это: правила событий, схемы, гарантии доставки, выбор Redis Streams/Kafka.  
   Зачем: чтобы кэш/аудит/инвалидация были системными, а не “по месту”.  
   Где: `docs/03-Architecture/09-Eventing.md` (планируемый).

---

## 8) Definition of Done (DoD) для архитектуры

Архитектура “в порядке”, если:
- C4 Context + Containers актуальны и соответствуют реальной инфре;
- Auth/IAM/RBAC описывает реальные потоки логина и проверки прав;
- модель данных в доке совпадает с БД (миграции/схемы);
- важные решения закреплены ADR;
- диаграммы имеют `.puml` + `.svg` и встроены в нужные документы.

---
