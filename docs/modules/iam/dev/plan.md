# PMServices IAM

План разработки для соло-разработчика с ИИ

Frontend → Backend → Integration

Версия: 2.0

27 декабря 2025

## Содержание

## Контекст и философия плана

### Для кого этот план

Этот план оптимизирован для соло-разработчика, работающего с ИИ-ассистентом.

Ключевые принципы:

Минимум переключения контекста — сначала весь фронтенд, потом весь бэкенд

ИИ как напарник — промпты для получения кода, ручное копирование

GitHub Team возможности — автоматизация через Actions, защита веток

Тестирование обязательно — каждый компонент/класс покрыт тестами

Документация автоматически — агенты обновляют docs/ при мерже

### Почему Frontend → Backend → Integration

| Аспект | Преимущество | Для ИИ |
| --- | --- | --- |
| Контекст | Только TypeScript/Angular 2 недели, потом только C#/SQL 2 недели | ИИ держит фокус на одной технологии, не путается |
| Отладка | Ошибки во фронте проще ловить (DevTools, моки) | ИИ видит весь стек-трейс браузера, легче помогает |
| Мотивация | Видимый результат (UI) через неделю | — |
| Контракты | OpenAPI spec = общий язык, фиксируем заранее | ИИ валидирует код по OpenAPI |

## Настройка GitHub Team (один раз)

### Protected Branches

Запрещаем прямой push в main — только через Pull Request.

Settings → Branches → Add rule для 'main':

Require a pull request before merging

Require status checks to pass (тесты обязательны)

Require branches to be up to date

Include administrators (даже вы не можете пушить напрямую)

### GitHub Projects (Kanban)

Projects → New project → Board.

Колонки: Backlog | In Progress | Testing | Done

### CodeQL Security Scanning

Security → Code scanning → Set up CodeQL.

Автоматически проверяет код на SQL injection, XSS, и другие уязвимости.

### Dependabot

Security → Dependabot → Enable.

Автоматические PR для обновления зависимостей с уязвимостями.

## Ежедневный Workflow

### Начало рабочего дня

GitHub Projects → выбрать задачу из Backlog → переместить в In Progress

```bash
git checkout -b feature/task-name
```

Открыть промпт-шаблон для этой фазы (см. Приложение B)

### Разработка с ИИ

Промпт ИИ → получить код компонента/класса + тесты

Копипаста → вставить код в VS Code / Rider

Запустить тесты → ng test / dotnet test

Если упали → скопировать вывод → промпт 'Вот ошибка, исправь'

### Перед коммитом (Self-Review)

Перерыв 15 минут (кофе, прогулка)

Прочитать свой код свежим взглядом (git diff)

Запустить тесты повторно

Проверить что OpenAPI актуален (если менялись контракты)

Промпт ИИ для code review (см. Приложение C)

### Push и Pull Request

```bash
git add . && git commit -m 'feat: add registration' && git push
```

GitHub → Create Pull Request → заполнить по шаблону (автогенерится)

GitHub Actions автоматически:

Запустит тесты (frontend + backend)

Сгенерит coverage report

Запустит CodeQL security scan

Прокомментирует результаты в PR

### Мердж и автодокументация

Если тесты ✅ → Merge Pull Request

После мерджа в main:

Агент docs-bot автообновляет документацию

Обновляются badges в README (tests, coverage)

Задача в Projects перемещается в Done

## Фазы разработки

Общая длительность: 7-9 недель

| Фаза | Длительность | Технологии | Результат |
| --- | --- | --- | --- |
| 0. Setup | 2-3 дня | Docker, Keycloak, OpenAPI | Инфра работает, контракты зафиксированы |
| 1. Frontend | 2-3 недели | Angular, TypeScript, Jasmine | UI полностью работает с моками |
| 2. Backend | 2-3 недели | C#, SQL, xUnit, Redis | API работает, Swagger = OpenAPI |
| 3. Integration | 3-5 дней | Full-stack отладка | Фронт работает с реальным бэком |
| 4. Polish | 1 неделя | Security, Performance | Готово к деплою |

## Фаза 0: Setup & Contracts (2-3 дня)

### Цель

Поднять инфраструктуру, зафиксировать контракты API, настроить Keycloak.

### Задачи

День 1: Docker инфраструктура

```bash
docker compose up -d (Postgres для приложения + Postgres для Keycloak + Redis + Mailpit)
```

Проверить localhost:8025 (Mailpit UI)

Проверить localhost:8085 (Keycloak Admin)

День 2: Keycloak конфигурация

Создать realm 'pmservices'

Создать client 'pmservices-spa' (Public, Authorization Code + PKCE)

Valid Redirect URIs: http://localhost:4200/*

Настроить SMTP: Host=mailpit, Port=1025, From=noreply@pmservices.local

Создать тестового юзера test@example.com / Test123456

Отправить test email → проверить в Mailpit

День 3: OpenAPI спецификация

Промпт для ИИ:

Создай openapi.yaml для IAM модуля по ТЗ.
Включи эндпоинты: registration, session, organizations, rbac, invites.
Для каждого: request/response схемы, error codes, примеры.

Сохранить openapi.yaml в корень репо

Сгенерить TypeScript типы: npx openapi-typescript openapi.yaml -o src/api/types.ts

Закоммитить в main (это base contract)

### Definition of Done

Keycloak работает, можно создать юзера через Admin UI

Mailpit получает письма

openapi.yaml существует и валиден (можно открыть в Swagger Editor)

TypeScript типы сгенерированы

## Фаза 1: Frontend (2-3 недели)

### Цель

Создать полностью работающий UI с моковыми данными. ТОЛЬКО TypeScript/Angular контекст.

### Week 1: OIDC + Skeleton

Промпт для ИИ (см. Приложение B для полной версии):

Настрой Angular 21 с angular-auth-oidc-client.
Realm: pmservices, Client: pmservices-spa,
Authority: http://localhost:8085/realms/pmservices
Покажи app.config.ts и auth guard.

Задачи:

```bash
ng new pmservices-web --routing --style=scss
npm install angular-auth-oidc-client
```

Настроить OIDC config (копипаста из промпта)

Создать AuthGuard

Кнопка 'Войти' → редирект на Keycloak → обратно с токеном

Показать email юзера на главной (из токена)

### Week 2: Mock Services + Forms

Промпт для ИИ:

Создай MockUserApiService по openapi.yaml.
Методы: register(), getMe(), getOrganizations().
Возвращай Promise с задержкой 300ms.
Покажи также сервис + Jasmine тесты.

Задачи:

Создать MockUserApiService (копипаста)

Форма регистрации: Reactive Form с валидацией

Тесты компонента регистрации (ng test)

Форма профиля, org switcher (аналогично)

Coverage >80% (ng test --code-coverage)

### Week 3: RBAC UI + Invites

Список пользователей организации (таблица)

Модалка назначения ролей

Форма отправки приглашения

Все с тестами и моками

### Definition of Done Фазы 1

Можно залогиниться через Keycloak

Все формы работают (с моками)

```bash
ng test → все тесты зеленые
```

Coverage frontend >80%

UI выглядит прилично (базовый дизайн)

## Фаза 2: Backend (2-3 недели)

### Цель

Реализовать все API эндпоинты строго по openapi.yaml. ТОЛЬКО C#/SQL контекст.

### Week 1: Database + Repositories

Промпт для ИИ:

Создай UserRepository на Npgsql (чистый ADO.NET).
Методы: GetByIdAsync, GetByEmailAsync, CreateAsync.
SQL руками (NpgsqlCommand).
Покажи xUnit тесты с Testcontainers.PostgreSql.

Задачи:

SQL миграции: 001_create_users.sql, 002_create_organizations.sql, и т.д.

UserRepository (копипаста из промпта)

OrganizationRepository, MembershipRepository (аналогично)

Тесты репозиториев с Testcontainers

```bash
dotnet test → все зеленые
```

### Week 2: JWT Auth + Registration

Настроить JWT Bearer Authentication (валидация токенов от Keycloak)

Контроллер RegistrationController (POST /api/iam/registration/personal)

Создание юзера в Keycloak через Admin API

Отправка email подтверждения (Mailpit)

Unit-тесты + интеграционные тесты

### Week 3: RBAC + Redis Streams

Реализовать Can(userId, orgId, permission) логику

Кэширование permissions в Redis (iam:perm:{orgId}:{userId})

Outbox таблица + фоновый worker для публикации в Redis Streams

Consumer для инвалидации кэша

Тесты RBAC логики (TDD — обязательно!)

### Definition of Done Фазы 2

Swagger UI работает, можно дергать эндпоинты

Swagger соответствует openapi.yaml

```bash
dotnet test → все зеленые
```

Coverage backend >85%

Redis Streams работает (события публикуются)

## Фаза 3: Integration (3-5 дней)

### Цель

Подключить фронтенд к реальному бэкенду, отладить интеграцию.

### Задачи

Заменить MockUserApiService на HttpUserApiService

Настроить HttpInterceptor (добавление токена в заголовки)

Проверить через Network tab: запросы идут на localhost:5000

Отладить несовпадения контрактов (если есть)

End-to-end тест: регистрация → логин → выбор орг → создание проекта

### Definition of Done

Можно зарегистрироваться через UI

Письмо приходит в Mailpit

Логин работает, токен валидный

Все UI функции работают с реальными данными

## Фаза 4: Polish & Security (1 неделя)

### Задачи

Rate Limiting (Redis): 5 req/sec на /registration, 10 req/sec на /session

Security headers: CSP, X-Content-Type-Options, X-Frame-Options

Password policy в Keycloak: минимум 12 символов

Account lockout: 5 неудачных попыток → блокировка 15 минут

Нагрузочный тест Can() — <5ms при кэше

Обновить документацию (агент docs-bot)

Runbook для инцидентов

### Definition of Done

Rate limiting работает (429 при превышении)

Security headers присутствуют

CodeQL security scan — 0 critical issues

Документация актуальна

Готово к деплою на preprod

## Приложение A: GitHub Actions Workflows

См. отдельные YAML файлы в пакете артефактов.

### A.1. ci.yml — тесты на каждый PR

Запускает тесты backend + frontend, генерит coverage, комментирует результаты в PR.

### A.2. docs-update.yml — автообновление документации

После мерджа в main обновляет docs/ на основе изменений в коде, коммитит как docs-bot.

### A.3. codeql.yml — security scanning

CodeQL анализ на каждый push, проверяет SQL injection, XSS и другие уязвимости.

## Приложение B: Промпт-шаблоны для ИИ

См. файл PROMPTS.md в пакете артефактов для полных версий.

### B.1. Получение кода компонента/класса

Контекст: [Angular/C#]
Требование: [описание]
Ограничения: [без ORM, async, и т.д.]
Формат: готовый к копипасте с импортами
Также покажи: unit-тесты

### B.2. Фикс упавшего теста

Вот результат теста:
[вывод]

Проблема: [описание]
Исправь код, сохраняя тесты.

### B.3. Code Review (ручной)

Я написал такой код:
[diff]

Проверь:
- Есть ли тесты
- Нет ли SQL injection
- Соответствует ли OpenAPI
- Обработаны ли ошибки

Ответь чеклистом.

## Заключение

Этот план оптимизирован для реальности соло-разработчика с ИИ-ассистентом. Ключевые принципы:

Фокус — не переключаться между стеками

Контракты — OpenAPI как источник истины

Тестирование — каждый компонент покрыт

Автоматизация — GitHub Actions делает рутину

Документация — обновляется автоматически

7-9 недель до production-ready IAM модуля!
