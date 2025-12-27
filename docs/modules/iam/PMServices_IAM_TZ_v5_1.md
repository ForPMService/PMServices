# PMServices — Техническое задание (ТЗ) на IAM‑модуль

Версия: 5.1 (Redis Streams — обязательно)

Дата: 27 декабря 2025

## Назначение документа

Этот документ задаёт требования к разработке модуля IAM (Identity and Access Management — управление идентичностями и доступом) для платформы PMServices.

IAM является частью системы PMServices и предоставляет:

регистрацию пользователей и организаций;

управление организациями и членством;

RBAC (Role‑Based Access Control — управление доступом по ролям) и разрешениями;

выбор контекста (активной организации) после логина;

аудит изменений и события безопасности;

API и внутренние контракты для использования IAM другими модулями платформы.

Ключевое архитектурное решение: PMServices реализуется как модульный монолит (.NET 10, единый процесс). Модули взаимодействуют через внутренние интерфейсы (DI) и события внутри процесса, а наружу (SPA/админ‑панель) публикуются HTTP‑контроллеры.

Ключевое инфраструктурное решение: для событий и согласованности кэша используются Redis Streams (обязательно).

## Термины и сокращения

При первом упоминании:

IAM (Identity and Access Management) — управление пользователями, организациями и доступами.

IdP (Identity Provider) — поставщик идентификации (Keycloak).

OIDC (OpenID Connect) — протокол аутентификации поверх OAuth 2.0.

RBAC (Role‑Based Access Control) — доступы через роли.

Permission (разрешение) — атомарное право на действие (например project.edit).

Org / Organization — организация (тенант).

Workspace — выбранная активная организация в UI.

Redis Streams — журнал событий в Redis с группами потребителей.

Outbox (таблица исходящих событий) — способ гарантировать, что событие будет опубликовано только после фиксации транзакции в БД.

Термины ИБ (угроза/уязвимость/инцидент/объект защиты/субъект доступа) закрепляются в глоссарии безопасности проекта и используются единообразно.

## Контекст системы и границы IAM

### Место IAM в PMServices

IAM — сквозной модуль платформы. Другие модули (Projects, Tasks, Reports, Billing и т.п.) не реализуют собственные модели доступа, а используют IAM как источник истины.

IAM предоставляет:

внешний API для SPA/админ‑панели;

внутренние интерфейсы для модулей внутри монолита;

события через Redis Streams для асинхронных реакций (инвалидация кэша, аудит, нотификации, интеграции).

### Разделение ответственности Keycloak vs IAM

Keycloak (IdP) отвечает за:

аутентификацию пользователя (логин/пароль, social login, SSO);

выпуск access token (JWT) и refresh token;

управление политиками MFA/Passkeys (как расширение);

управление пользователями в IdP (через Admin API) — создание, блокировка, сброс сессий.

IAM‑модуль PMServices отвечает за:

доменные сущности платформы: Organization, Membership, Role, Permission, Audit;

орг‑контекст: выбор активной организации, контроль доступа внутри организации;

RBAC‑модель в разрезе организации;

аудит и поток событий изменений;

API для других модулей: Can(userId, orgId, permission).

Правило: refresh token не уходит на backend. Он используется только между SPA и Keycloak.

## Технологии и целевые версии

Backend: .NET 10, ASP.NET Core.

API стиль: контроллеры (Controllers) + OpenAPI.

БД: PostgreSQL 18.

Кэш и события: Redis 8.4 (Redis Streams).

IdP: Keycloak 26.4.7.

Frontend: Angular 21 (Node.js 24 для сборки).

Логи и наблюдаемость: ELK (Elasticsearch + Kibana) + агент доставки логов.

## Общие требования к модулю

### Переиспользуемость другими модулями

IAM должен предоставлять стабильный контракт:

внешний HTTP API;

внутренние интерфейсы (DI) для внутри‑процессного использования.

Другие модули должны уметь:

проверять права (Can) и получать контекст;

получать список доступных пользователю организаций/ролей/permissions;

получать списки администраторов организации.

### Отделимость регистрации от авторизации

Registration выделяется как подмодуль, который можно вынести:

отдельный набор контроллеров /api/iam/registration/*;

отдельные сервисы и репозитории;

отдельные шаблоны писем и сценарии подтверждения.

Registration не реализует логин. Логин реализует Keycloak.

## Пользовательские сценарии (UX/бизнес‑логика)

### Регистрация личного аккаунта

Цель: создать пользователя без организации (user only).

Шаги:

Пользователь выбирает тип регистрации «Личный аккаунт».

Заполняет: имя, фамилия, email, телефон (опционально), пароль.

Система создаёт:

запись пользователя в БД PMServices (статус PendingEmailVerification или Active — зависит от политики);

пользователя в Keycloak через Admin API (username=email);

Система отправляет письмо подтверждения (dev: Mailpit; prod: SMTP‑провайдер).

Пользователь подтверждает email.

После подтверждения пользователь может:

создать организацию;

принять приглашение;

войти и попасть на экран «Нет доступных организаций».

### Регистрация аккаунта с организацией

Цель: создать пользователя + организацию + базовые роли.

Шаги:

Пользователь выбирает «Аккаунт организации».

Заполняет личные данные + данные организации.

Система создаёт:

Organization (статус Active или Pending);

Membership пользователя в организации как Owner;

базовый набор ролей и разрешений;

пользователя в Keycloak;

письмо подтверждения.

### Логин

Реализация: OIDC Authorization Code + PKCE.

SPA отправляет введённые пользователем данные в Keycloak.

После успеха SPA получает access token.

SPA вызывает /api/iam/session/me и получает:

профиль пользователя;

список организаций;

признак «нужно выбрать org».

### Выбор активной организации (workspace)

Если организаций > 1 — показывается экран выбора.

Пользователь выбирает организацию, включает «Запомнить выбор» (опционально).

SPA вызывает /api/iam/session/select-organization.

IAM проверяет членство и сохраняет активный контекст:

в Redis (key iam:ctx:{userId} с TTL);

публикует событие iam.session.org_selected в Redis Streams.

Дальше все запросы SPA к API содержат заголовок X-PM-OrgId.

Если организаций нет — показывается пустое состояние «Нет доступных организаций» + кнопка «Создать организацию».

### Приглашения (Invites Flow) — обязательно

Цель: B2B‑сценарий приглашения пользователя в организацию.

Сценарий A: пользователь уже существует

Админ организации создаёт приглашение по email.

Система отправляет письмо со ссылкой.

Пользователь кликает ссылку.

SPA открывает экран принятия приглашения.

Пользователь логинится (если не залогинен).

IAM валидирует invite token, добавляет membership, назначает роли.

Сценарий B: пользователь новый

Пользователь кликает приглашение.

Попадает на регистрацию (можно “мягко” пред‑заполнить email).

После регистрации и логина приглашение автоматически принимается.

Требования к приглашению:

токен одноразовый;

TTL (например 7 дней);

можно отозвать;

все действия логируются в аудит;

изменения публикуются в Redis Streams.

### RBAC‑панель (пользователи/роли/permissions)

Пользователи:

список пользователей организации;

статусы: Active / Suspended / Invited;

назначение ролей;

блокировка/разблокировка;

просмотр активности.

Роли:

создание/редактирование ролей;

назначение permissions;

встроенные системные роли (не удаляются).

Permissions:

каталог permissions по модулям;

UI с группировкой (дерево или секции).

### Восстановление пароля (Password recovery) — обязательно

Цель: безопасно восстановить доступ без раскрытия существования аккаунта.

Базовый принцип: фактическое изменение пароля выполняется через Keycloak reset flow (action‑token / required actions). IAM предоставляет UI‑точки входа и, при необходимости, инициирует отправку письма.

Поток:

Пользователь нажимает «Забыли пароль?».

Вводит email.

SPA вызывает POST /api/iam/auth/forgot-password.

IAM:

всегда отвечает одинаково (202 Accepted), чтобы исключить перечисление пользователей;

если email существует — через Keycloak Admin API инициирует отправку письма «Reset password».

Пользователь переходит по ссылке из письма и завершает смену пароля в Keycloak.

После успешной смены пароля:

все активные сессии пользователя могут быть отозваны (настраиваемо);

публикуется событие iam.auth.password_recovered в Redis Streams (без чувствительных данных).

Дополнительно (опционально): если требуется полностью «свой» UI сброса пароля, вводится POST /api/iam/auth/reset-password (см. §9.5) с одноразовым токеном, но это усложнение и включается отдельным решением.

### Подтверждение email (Email verification) — детали

Политика подтверждения:

по умолчанию email требуется подтвердить (особенно для орг‑аккаунтов и приглашений);

пользователь со статусом PendingEmailVerification:

может войти (если Keycloak уже выдал токен), но доступ ограничен (только экраны подтверждения/профиля/организаций) — вариант A;

или не может войти до подтверждения — вариант B (настраиваемо).

Требования:

ссылка подтверждения имеет TTL (например 24 часа);

доступен resend (повторная отправка) с анти‑флуд защитой;

событие iam.user.email_verified фиксируется в iam.audit_log и публикуется в Redis Streams;

ошибка подтверждения не раскрывает деталей (унифицированные ответы).

### Профиль пользователя (Self‑service) — обязательно

Пользователь должен иметь возможность:

изменить отображаемое имя (first/last/display);

загрузить/сменить аватар;

сменить пароль (через Keycloak);

просмотреть и отозвать активные сессии.

Ограничения:

смена email требует повторного подтверждения;

смена пароля выполняется через Keycloak (policy, lockout, MFA).

## Архитектура модульного монолита

### Модули внутри процесса

IAM

Organizations (если выделяется отдельно)

Projects/Tasks/…

Взаимодействие:

внешнее: HTTP контроллеры;

внутреннее: DI‑интерфейсы (IIamService) + in‑process события (MediatR);

асинхронное/интеграционное: Redis Streams.

### Permission Discovery (обязательно)

IAM не должен знать права всех модулей заранее.

Каждый модуль при старте регистрирует свои permissions через реестр:

IAM предоставляет IPermissionRegistry.

Каждый модуль вызывает Register(moduleName, permissions) в момент инициализации.

Требования:

регистрация идемпотентна;

изменения permissions фиксируются в Postgres;

публикация события iam.permissions.registry_updated в Redis Streams;

возможность получить каталог permissions через API.

## Данные и схема БД (PostgreSQL 18)

### Принципы хранения

единая БД приложения pmservices;

разделение по схемам (минимум iam.*, опционально org.*);

первичные ключи: UUIDv7;

миграции: SQL‑скрипты (без EF);

аудит: отдельная таблица + индексы по времени/организации/субъекту.

### Таблицы (минимальный состав)

iam.users - id (uuid) - email (citext, unique) - phone (text, nullable) - first_name (text, nullable) - last_name (text, nullable) - display_name (text) # отображаемое имя; может быть вычислено из first/last - avatar_url (text, nullable) - status (enum: active/suspended/pending) - created_at, updated_at - status (enum: active/suspended/pending) - created_at, updated_at

iam.organizations - id (uuid) - name (text) - status (active/pending/suspended) - settings (jsonb) # политика MFA, TTL инвайтов, настройки регистрации и др. - created_at, updated_at - created_at, updated_at

iam.memberships - id (uuid) - user_id (uuid, fk users) - org_id (uuid, fk organizations) - member_type (owner/admin/member/guest) - status (active/invited/blocked) - created_at - unique (user_id, org_id)

iam.roles - id (uuid) - org_id (uuid) - code (text) - name (text) - description (text) - is_system (bool) - created_at - unique (org_id, code)

iam.permissions - id (uuid) - module (text) - code (text) # например project.edit - name (text) - description (text) - is_system (bool) - unique (module, code)

iam.role_permissions - role_id (uuid) - permission_id (uuid) - pk (role_id, permission_id)

iam.user_roles - user_id (uuid) - role_id (uuid) - pk (user_id, role_id)

iam.invitations - id (uuid) - org_id (uuid) - email (citext) - role_ids (uuid[]) # какие RBAC‑роли назначить при принятии приглашения - token_hash (text) - expires_at (timestamptz) - status (pending/accepted/revoked/expired) - created_by_user_id (uuid) - created_at

iam.audit_log - id (uuid) - org_id (uuid, nullable) - actor_user_id (uuid, nullable) - subject_type (text) # user/role/permission/invite/session - subject_id (uuid, nullable) - action (text) - details (jsonb) - created_at (timestamptz)

iam.outbox - id (uuid) - event_type (text) - payload (jsonb) - status (pending/published/failed) - created_at - published_at

Индексы:

audit_log(org_id, created_at desc)

memberships(user_id), memberships(org_id)

roles(org_id), user_roles(user_id)

### Стратегия ролей и типов участия (Selected Strategy)

Для упрощения проверки прав (Can(...)) и исключения дублирования логики принимается следующее архитектурное решение:

Member Type как Системная Роль: Поля Owner, Admin, Member, Guest реализуются как предустановленные системные роли в таблице iam.roles (флаг is_system = true).

Единый механизм проверки: Таблица iam.memberships содержит только user_id, org_id и status. Поле member_type из схемы исключается (или используется только как UI-ярлык).

Привязка: При добавлении пользователя в организацию ему автоматически присваивается соответствующая роль в iam.user_roles.

Преимущество: Метод Can(user, org, permission) проверяет разрешения только через одну таблицу связей iam.user_roles, не делая "OR" проверок по типу участия.

## Backend реализация (.NET 10, контроллеры)

### Слои

Controllers: HTTP контракт, валидация входных данных.

Services: бизнес‑логика.

Repositories: SQL‑запросы (Npgsql).

Event Publisher: публикация событий в Redis Streams (через outbox‑dispatcher).

### Требование консистентности: Outbox + Redis Streams

Правило: любое изменение, влияющее на права/членство/контекст, должно:

быть зафиксировано в транзакции Postgres;

создать запись в iam.outbox в той же транзакции;

затем быть опубликовано в Redis Streams асинхронным диспетчером.

Диспетчер:

периодически читает iam.outbox со статусом pending;

публикует XADD в стрим;

помечает событие как published;

при ошибке — failed + retry политика.

Это обеспечивает:

отсутствие «потерянных» событий;

отсутствие публикации «несуществующих» изменений.

Управление памятью Redis (Retention Policy):

Диспетчер Outbox при публикации событий обязан ограничивать рост стрима.

Используется команда: XADD pmservices.iam.events MAXLEN ~ 500000 * ...

Это обеспечивает хранение ~500 000 последних событий IAM. При средней нагрузке это гарантирует сохранность истории событий за несколько суток (буфер на случай падения консьюмеров), при потреблении памяти Redis не более 500-700 МБ.

### Redis Streams: структура

Стрим: pmservices.iam.events

Consumer Groups:

pmservices-iam-cache — инвалидизация кэша permissions и контекстов.

pmservices-iam-audit — доставка в ELK (опционально).

pmservices-iam-notify — уведомления/почта (будущее).

Формат сообщения (fields):

event_id (uuid)

event_type (string)

ts (ISO‑time)

org_id (uuid, nullable)

actor_user_id (uuid, nullable)

subject_type (string)

subject_id (uuid, nullable)

correlation_id (string)

payload (json)

Требование: в payload запрещено хранить секреты, пароли, refresh token.

## HTTP API (контракты)

Все эндпоинты ниже реализуются через контроллеры и описываются в OpenAPI.

### Registration

POST /api/iam/registration/personal - создаёт личный аккаунт.

POST /api/iam/registration/organization - создаёт пользователя + организацию.

POST /api/iam/registration/resend-confirmation - повторная отправка подтверждения.

### Session / Context

GET /api/iam/session/me - профиль + список организаций.

POST /api/iam/session/select-organization - выбирает активную org.

POST /api/iam/session/logout-all - revoke sessions (через Keycloak Admin API).

### Security (self‑service)

GET /api/iam/security/sessions - список активных сессий (через Keycloak Admin API) + признаки устройства/времени.

POST /api/iam/security/sessions/{sessionId}/revoke - отзыв одной сессии.

GET /api/iam/profile # получить свой профиль 
PUT /api/iam/profile # обновить имя/телефон

### Organizations & Memberships

GET /api/iam/organizations

POST /api/iam/organizations - создать организацию (для личного аккаунта без org).

GET /api/iam/organizations/{orgId}/members

POST /api/iam/organizations/{orgId}/invites

POST /api/iam/invites/{token}/accept

POST /api/iam/invites/{token}/revoke

### Auth helper (инициаторы Keycloak flows)

POST /api/iam/auth/forgot-password - инициирует reset‑flow (не раскрывает существование email).

POST /api/iam/auth/resend-verification - повторная отправка подтверждения email (с анти‑флуд защитой).

POST /api/iam/auth/reset-password - опционально: если реализуем собственную форму сброса; в MVP предпочтительно завершать сброс внутри Keycloak.

### RBAC

GET /api/iam/rbac/roles

POST /api/iam/rbac/roles

PUT /api/iam/rbac/roles/{roleId}

DELETE /api/iam/rbac/roles/{roleId} (если не system)

GET /api/iam/rbac/permissions

POST /api/iam/rbac/users/{userId}/roles

### Internal API для модулей

POST /api/iam/internal/authorize - вход: userId, orgId, permissionCode - выход: allow/deny + причины.

GET /api/iam/internal/org-admins?orgId=...

### Стандартизированные ошибки (Error codes)

Ошибки возвращаются в формате:

code — строковый код (например IAM-002)

message — человекочитаемое сообщение

details — опционально (для отладки; на prod — ограничено)

correlationId — для трассировки

Базовый набор кодов:

IAM-001 Email already registered

IAM-002 Invalid invite token

IAM-003 Invite expired

IAM-004 Insufficient permissions

IAM-005 Organization not found

IAM-006 User not a member of organization

IAM-007 Email not verified

IAM-008 Rate limit exceeded

IAM-009 Validation error

IAM-010 Conflict (concurrent update)

Контроллеры обязаны использовать эти коды консистентно.

## Кэширование (Redis)

Кэшируем:

iam:perm:{orgId}:{userId} — эффективный набор permissions.

iam:ctx:{userId} — активная org и версия контекста.

Инвалидация:

при изменении ролей/permissions/user_roles/memberships публикуется событие в Redis Streams;

consumer pmservices-iam-cache очищает соответствующие ключи.

## Логирование, аудит, ELK

### Структурные логи

JSON‑логи API с полями: traceId, correlationId, userId, orgId, route, statusCode.

### Аудит IAM

В iam.audit_log пишутся события:

registration.*

organization.*

membership.*

rbac.role.*

rbac.permission.*

session.*

invite.*

Параллельно ключевые события отправляются через outbox в Redis Streams.

### Инциденты

фиксируется минимальный playbook реагирования;

наличие логов и аудита — обязательное условие для препрода.

## Требования безопасности (минимальный контур)

### Сетевой периметр и TLS

Внешний доступ только через reverse‑proxy (HTTPS).

На preprod/prod порты Postgres/Redis/Mailpit не публикуются наружу.

### Rate limiting (обязательно)

Минимальные лимиты (настраиваемые):

/api/iam/registration/* — 5 req/sec на IP + 20 req/min на email.

/api/iam/session/* — 10 req/sec на IP.

/api/iam/auth/forgot-password — 3 req/min на IP + 3 req/hour на email.

/api/iam/organizations/*/invites — 10 req/min на org.

При превышении возвращаем 429 с IAM-008.

### CAPTCHA (опционально)

На регистрацию допускается подключение reCAPTCHA v3 / альтернативы.

Включается конфигурацией организации (или окружения).

### Account lockout (через Keycloak) — обязательно

5 неудачных попыток входа → блокировка 15 минут (параметры настраиваются в Keycloak realm).

Для админских ролей может быть более строгая политика.

### Password policy (через Keycloak)

Минимум 12 символов.

Требования к сложности задаются политикой Keycloak (цифры/буквы/спецсимволы — по решению продукта).

### Заголовки безопасности (CSP и др.)

На reverse‑proxy/nginx: Content‑Security‑Policy (CSP), X‑Content‑Type‑Options, X‑Frame‑Options / frame‑ancestors, Referrer‑Policy.

На API: корректные CORS‑настройки только для доверенных origin.

### Секреты и доступы

Секреты не хранятся в репозитории.

На preprod/prod используются секрет‑хранилища/переменные окружения.

Принцип минимальных привилегий для сервисных учёток (Postgres, Keycloak Admin).

### Защита от перечисления пользователей

Регистрация/восстановление пароля/подтверждение email возвращают унифицированные ответы.

## Нефункциональные требования

Время ответа на Can() (внутренний вызов) в среднем < 5 мс при наличии кэша.

Эндпоинты RBAC должны работать постранично.

Redis Streams consumer lag мониторится.

Любое событие изменений IAM должно быть опубликовано в Streams не позднее N секунд (например 5–10) после фиксации БД.

## Развёртывание

Dev: docker compose.

Preprod/Prod: docker compose или оркестратор; обязательны secrets, TLS, закрытые порты БД/Redis.

Keycloak использует отдельную БД keycloak в Postgres (может быть в том же инстансе Postgres, но отдельной БД).

### Хранилище файлов (аватары) — optional/nice

Если включаем аватары:

Dev: локальная файловая система (volume) или простой static‑сервер.

Preprod/Prod: S3‑совместимое хранилище (например MinIO/S3).

API:

POST /api/iam/profile/avatar — multipart/form-data.

Ограничения:

max 2MB;

форматы: jpg/png/webp;

сервер проверяет MIME + сигнатуру файла;

хранение: по ключу avatars/{userId}/{hash}.

Управление устаревшими файлами (Garbage Collection): При загрузке нового аватара (POST /profile/avatar):

Сервис должен сначала успешно сохранить новый файл и получить его URL/Hash.

После обновления записи в БД, сервис обязан инициировать удаление старого файла из S3-хранилища (если он был), чтобы предотвратить бесконечное накопление неиспользуемых файлов ("мусора").

## Приёмка (Definition of Done)

Функциональные критерии:

работают оба сценария регистрации (личный / с организацией);

работает логин через Keycloak (OIDC + PKCE);

работает выбор организации и сохранение контекста;

работает Invites Flow (оба сценария — существующий и новый пользователь);

RBAC: роли/permissions, назначение ролей, проверка прав;

Permission Discovery: права модулей регистрируются при старте;

аудит пишется в БД;

события публикуются в Redis Streams через outbox.

Технические критерии:

нет EF в IAM‑модуле;

миграции — SQL;

OpenAPI актуален;

базовые интеграционные тесты на ключевые сценарии;

логирование структурное.

## План внедрения (укрупнённо)

Этап 1 (MVP):

Users/Organizations/Memberships

Registration

Org switcher

RBAC базовый

Outbox + Streams + cache invalidation

Этап 2:

MFA политика

Интеграция с ELK

Расширенный аудит/инциденты

Этап 3:

SSO корпоративный, дополнительные IdP

Расширение roles/permissions под доменные модули

## Приложение: минимальные правила данных в событиях Streams

Разрешено:

идентификаторы (userId, orgId, roleId)

тип события

временная метка

техническая корреляция (traceId)

Запрещено:

пароли

refresh token

данные карт/платёжные данные

секреты инфраструктуры

Конец документа.
