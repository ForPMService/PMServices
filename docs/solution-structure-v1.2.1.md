# Структура решения PMPlatform

**Версия:** 1.2.1  
**Дата:** 25.01.2026  
**Статус:** Актуальный

---

## 1. Обзор

PMPlatform — переиспользуемая платформа для построения multi-tenant приложений с готовой системой аутентификации, авторизации и RBAC.

### 1.1 Ключевые принципы

| Принцип | Описание |
|---------|----------|
| **IAM как фундамент** | Модуль IAM — обязательный, все модули зависят от него для RBAC |
| **BFF-паттерн** | Единая точка входа для SPA, токены не попадают в браузер |
| **Модульность** | Бизнес-модули добавляются независимо, используют общую инфраструктуру |
| **Clean Architecture** | Каждый модуль: Domain → Application → Infrastructure → Contracts → Api |
| **Контракты в модулях** | Каждый модуль владеет своими gRPC/DTO контрактами |
| **gRPC-first внутри платформы** | Межсервисное взаимодействие через gRPC; SPA → BFF: REST/JSON (cookie+CSRF) |

### 1.2 Технологический стек

| Компонент | Технология |
|-----------|------------|
| Backend | .NET 10, ASP.NET Core, gRPC |
| Frontend | Angular 21, TypeScript |
| Database | PostgreSQL 18 + RLS |
| Cache/Events | Redis 8 (Streams, Sessions) |
| IdP | Keycloak 26 |
| Observability | OpenTelemetry → Prometheus/Grafana/ELK |
| Containers | Docker, docker-compose |

---

## 2. Структура репозитория

```
PMServices/
│
├── src/                              # Исходный код backend (.NET 10)
│   ├── Platform/                     # 🔷 Платформенный слой
│   │   ├── PM.Platform.Core/         # Базовые абстракции
│   │   ├── PM.Platform.Infrastructure/ # Общая инфраструктура
│   │   └── PM.Platform.Contracts/    # Только common.proto
│   │
│   ├── IAM/                         # 🔐 IAM-модуль (Identity & Access Management)
│   │   ├── PM.IAM.Domain/
│   │   ├── PM.IAM.Application/
│   │   ├── PM.IAM.Infrastructure/
│   │   ├── PM.IAM.Contracts/        # iam.proto
│   │   └── PM.IAM.Api/
│   │
│   ├── BFF/                          # 🚪 BFF-сервис
│   │   └── PM.BFF/
│   │
│   └── Modules/                      # 📦 Бизнес-модули
│       ├── _Template/                # Шаблон
│       ├── ProjectManagement/
│       └── Analytics/
│
├── tests/                            # Тесты
│   ├── Platform/
│   ├── IAM/
│   ├── BFF/
│   └── Modules/
│
├── web/                              # Frontend (Angular 21)
│   └── pm-web/
│       └── projects/
│           ├── shell/                # Основное приложение
│           ├── iam/                  # IAM UI
│           ├── shared/               # Общие компоненты
│           └── [module]/             # Feature modules
│
├── ops/                              # DevOps
│   ├── iam/                          # Source of Truth для IAM/Platform контура на старте
│   │   ├── compose.iam.yml
│   │   ├── .env.iam
│   │   ├── nginx/
│   │   │   └── default.conf
│   │   ├── keycloak/
│   │   ├── observability/
│   │   └── scripts/
│   └── platform/                     # появится позже, когда будет 2+ модулей (надстройка над iam)
│
├── docs/                             # Документация
│   └── architecture/
│
└── PMPlatform.sln                    # Solution
```

---

## 3. Платформенный слой (src/Platform/)

Общие библиотеки для **всех** модулей. Не содержит бизнес-логики.

### 3.1 PM.Platform.Core

**Назначение:** Базовые абстракции, независимые от инфраструктуры.

```
PM.Platform.Core/
├── Domain/
│   ├── Entities/
│   │   ├── IEntity.cs                  # interface IEntity { Guid Id; }
│   │   ├── IAuditableEntity.cs         # CreatedAt, UpdatedAt, CreatedBy
│   │   └── ISoftDeletable.cs           # IsDeleted, DeletedAt
│   │
│   ├── Events/
│   │   ├── IDomainEvent.cs             # Внутри bounded context
│   │   └── IIntegrationEvent.cs        # Между модулями
│   │
│   └── Interfaces/
│       ├── IRepository.cs              # Generic repository
│       └── IUnitOfWork.cs
│
├── Application/
│   ├── CQRS/
│   │   ├── ICommand.cs                 # IRequest<TResult>
│   │   ├── IQuery.cs                   # IRequest<TResult>
│   │   └── ICommandHandler.cs
│   │
│   ├── Behaviors/
│   │   ├── ValidationBehavior.cs       # FluentValidation pipeline
│   │   ├── LoggingBehavior.cs
│   │   └── TransactionBehavior.cs
│   │
│   └── Exceptions/
│       ├── NotFoundException.cs
│       ├── ForbiddenException.cs
│       ├── ConflictException.cs
│       └── ValidationException.cs
│
└── PM.Platform.Core.csproj
```

**Зависимости:**
```xml
<PackageReference Include="MediatR" />
<PackageReference Include="FluentValidation.DependencyInjectionExtensions" />
```

---

### 3.2 PM.Platform.Infrastructure

**Назначение:** Общая инфраструктура для всех сервисов.

```
PM.Platform.Infrastructure/
├── Persistence/
│   ├── DbContextBase.cs                # Базовый DbContext с Outbox, Audit
│   ├── Extensions/
│   │   ├── RlsExtensions.cs            # SetOrgContext(), ClearOrgContext()
│   │   └── OutboxExtensions.cs         # AddOutboxMessage()
│   ├── Interceptors/
│   │   ├── AuditableEntityInterceptor.cs
│   │   └── OutboxInterceptor.cs
│   └── Repositories/
│       └── RepositoryBase.cs
│
├── Redis/
│   ├── RedisConnectionFactory.cs
│   ├── RedisCacheService.cs            # IDistributedCache wrapper
│   ├── RedisStreamPublisher.cs         # Публикация в Redis Streams
│   └── RedisStreamConsumer.cs          # Потребление из Redis Streams
│
├── Messaging/
│   ├── OutboxProcessor.cs              # Background service
│   ├── EventDispatcher.cs
│   └── IdempotencyService.cs           # Redis TTL дедупликация
│
├── Observability/
│   ├── OpenTelemetryExtensions.cs      # AddPlatformTelemetry()
│   ├── HealthChecks/
│   │   ├── RedisHealthCheck.cs
│   │   ├── PostgresHealthCheck.cs
│   │   └── KeycloakHealthCheck.cs
│   └── Metrics/
│       └── PlatformMetrics.cs
│
├── Security/
│   ├── CurrentUserAccessor.cs          # ICurrentUser из HttpContext
│   └── OrgContextAccessor.cs           # Текущая организация
│
├── Extensions/
│   └── ServiceCollectionExtensions.cs  # AddPlatformInfrastructure()
│
└── PM.Platform.Infrastructure.csproj
```

**Зависимости:**
```xml
<PackageReference Include="Microsoft.EntityFrameworkCore" />
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" />
<PackageReference Include="StackExchange.Redis" />
<PackageReference Include="OpenTelemetry.Extensions.Hosting" />
<PackageReference Include="OpenTelemetry.Instrumentation.AspNetCore" />
<PackageReference Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" />
```

---

### 3.3 PM.Platform.Contracts

**Назначение:** **ТОЛЬКО** общие типы для межсервисного взаимодействия.

> ⚠️ **Важно:** Модуль-специфичные контракты (iam.proto, pm.proto) размещаются в `{Module}.Contracts`, не здесь!

```
PM.Platform.Contracts/
├── Protos/
│   └── common.proto
│
├── DTOs/
│   ├── PagedResult.cs
│   ├── ErrorResponse.cs
│   └── HealthStatus.cs
│
└── PM.Platform.Contracts.csproj
```

**common.proto:**
```protobuf
syntax = "proto3";
package pm.common.v1;

option csharp_namespace = "PM.Platform.Contracts";

// === Общие типы ===

message Timestamp {
  int64 seconds = 1;
  int32 nanos = 2;
}

message UUID {
  string value = 1;  // RFC 4122 format
}

// === Пагинация ===

message PagedRequest {
  int32 page = 1;           // 1-based
  int32 page_size = 2;      // default 20, max 100
  string sort_by = 3;       // field name
  bool descending = 4;
}

message PagedResponse {
  int32 total_count = 1;
  int32 page = 2;
  int32 page_size = 3;
  int32 total_pages = 4;
}

// === Результат операции ===

message OperationResult {
  bool success = 1;
  string error_code = 2;    // из Error Catalog
  string error_message = 3;
}
```

---

## 4. IAM-модуль (src/IAM/)

Обязательный фундамент платформы. Реализует Identity & Access Management.

### 4.1 Назначение IAM-модуля

| Аспект | Объяснение |
|--------|------------|
| **Naming** | "IAM" подчёркивает, что это фундамент платформы (Identity & Access Management) |
| **Контракт** | `iam.proto` остаётся — это domain term (Identity & Access Management) |
| **Package** | `pm.iam.v1` — консистентно с domain terminology |

---

### 4.2 PM.IAM.Domain

```
PM.IAM.Domain/
├── Entities/
│   ├── User.cs                     # id, keycloak_sub, email, display_name
│   ├── Organization.cs             # id, name, slug, owner_id, settings
│   ├── Membership.cs               # user_id, org_id, role_id, joined_at
│   ├── Role.cs                     # id, org_id, name, is_system
│   ├── Permission.cs               # id, code, name, description
│   ├── RolePermission.cs           # role_id, permission_id
│   ├── Invitation.cs               # id, org_id, email, token_hash, role_id, expires_at, status
│   └── AuditLogEntry.cs            # id, org_id, actor_id, action, entity_type, details
│
├── ValueObjects/
│   ├── Email.cs                    # Validated email
│   ├── TokenHash.cs                # SHA-256 hash
│   └── PermissionCode.cs           # e.g., "projects.create"
│
├── Events/
│   ├── UserCreatedEvent.cs
│   ├── UserJoinedOrgEvent.cs
│   ├── RoleAssignedEvent.cs
│   ├── PermissionChangedEvent.cs   # → invalidate RBAC cache
│   └── InvitationAcceptedEvent.cs
│
├── Enums/
│   ├── InvitationStatus.cs         # Pending, Accepted, Expired, Revoked
│   └── SystemRole.cs               # Owner, Admin, Member
│
└── PM.IAM.Domain.csproj
```

**Зависимости:**
```xml
<ProjectReference Include="..\..\Platform\PM.Platform.Core\PM.Platform.Core.csproj" />
```

---

### 4.3 PM.IAM.Application

```
PM.IAM.Application/
├── Commands/
│   ├── Organizations/
│   │   ├── CreateOrganizationCommand.cs
│   │   ├── CreateOrganizationHandler.cs
│   │   └── CreateOrganizationValidator.cs
│   ├── Invitations/
│   │   ├── CreateInvitationCommand.cs
│   │   ├── AcceptInvitationCommand.cs
│   │   └── RevokeInvitationCommand.cs
│   ├── Roles/
│   │   ├── CreateRoleCommand.cs
│   │   ├── AssignRoleCommand.cs
│   │   └── UpdateRolePermissionsCommand.cs
│   └── Users/
│       └── SyncUserFromKeycloakCommand.cs
│
├── Queries/
│   ├── Organizations/
│   │   ├── GetOrganizationQuery.cs
│   │   └── GetUserOrganizationsQuery.cs
│   ├── Permissions/
│   │   ├── CheckPermissionQuery.cs
│   │   ├── CheckBatchPermissionsQuery.cs
│   │   └── GetUserPermissionsQuery.cs
│   ├── Roles/
│   │   └── GetOrganizationRolesQuery.cs
│   └── Users/
│       ├── GetUserQuery.cs
│       └── GetOrganizationMembersQuery.cs
│
├── Services/
│   ├── IPermissionService.cs
│   ├── IInvitationService.cs
│   └── IRbacCacheService.cs
│
├── EventHandlers/
│   └── PermissionChangedHandler.cs  # Инвалидация кэша
│
└── PM.IAM.Application.csproj
```

**Зависимости:**
```xml
<ProjectReference Include="..\PM.IAM.Domain\PM.IAM.Domain.csproj" />
<ProjectReference Include="..\..\Platform\PM.Platform.Core\PM.Platform.Core.csproj" />
```

---

### 4.4 PM.IAM.Infrastructure

```
PM.IAM.Infrastructure/
├── Persistence/
│   ├── CoreDbContext.cs
│   ├── Configurations/
│   │   ├── UserConfiguration.cs
│   │   ├── OrganizationConfiguration.cs
│   │   ├── MembershipConfiguration.cs
│   │   ├── RoleConfiguration.cs
│   │   ├── PermissionConfiguration.cs
│   │   ├── InvitationConfiguration.cs
│   │   └── AuditLogConfiguration.cs
│   ├── Migrations/
│   └── Repositories/
│       ├── UserRepository.cs
│       ├── OrganizationRepository.cs
│       └── RoleRepository.cs
│
├── Caching/
│   └── RbacCacheService.cs         # Redis: rbac:cache:{org_id}:{user_id}
│
├── Keycloak/
│   ├── KeycloakAdminClient.cs      # Admin REST API
│   └── KeycloakUserSyncService.cs
│
├── Services/
│   ├── PermissionService.cs
│   └── InvitationService.cs
│
└── PM.IAM.Infrastructure.csproj
```

**Зависимости:**
```xml
<ProjectReference Include="..\PM.IAM.Domain\PM.IAM.Domain.csproj" />
<ProjectReference Include="..\PM.IAM.Application\PM.IAM.Application.csproj" />
<ProjectReference Include="..\..\Platform\PM.Platform.Infrastructure\PM.Platform.Infrastructure.csproj" />
```

---

### 4.5 PM.IAM.Contracts

**Назначение:** gRPC-контракты IAM. Используется BFF и всеми бизнес-модулями.

```
PM.IAM.Contracts/
├── Protos/
│   └── iam.proto
│
├── DTOs/
│   ├── UserDto.cs
│   ├── OrganizationDto.cs
│   ├── RoleDto.cs
│   ├── MembershipDto.cs
│   └── InvitationDto.cs
│
└── PM.IAM.Contracts.csproj
```

**iam.proto:**
```protobuf
syntax = "proto3";
package pm.iam.v1;

option csharp_namespace = "PM.IAM.Contracts.Grpc";

import "common.proto";

// ============================================
// PERMISSION SERVICE
// ============================================

service PermissionService {
  // Проверка одного разрешения
  rpc Check(CheckPermissionRequest) returns (CheckPermissionResponse);
  
  // Batch-проверка нескольких разрешений
  rpc CheckBatch(CheckBatchRequest) returns (CheckBatchResponse);
  
  // Получить все разрешения пользователя в организации
  rpc GetUserPermissions(GetUserPermissionsRequest) returns (GetUserPermissionsResponse);
}

message CheckPermissionRequest {
  string user_id = 1;
  string org_id = 2;
  string permission = 3;    // e.g., "projects.create", "users.invite"
  string resource_id = 4;   // optional, для resource-level проверок
}

message CheckPermissionResponse {
  bool allowed = 1;
  string reason = 2;        // если denied — причина (для логов)
}

message CheckBatchRequest {
  string user_id = 1;
  string org_id = 2;
  repeated string permissions = 3;
}

message CheckBatchResponse {
  map<string, bool> results = 1;  // permission → allowed
}

message GetUserPermissionsRequest {
  string user_id = 1;
  string org_id = 2;
}

message GetUserPermissionsResponse {
  repeated string permissions = 1;
  string role_name = 2;
}

// ============================================
// USER SERVICE
// ============================================

service UserService {
  rpc GetUser(GetUserRequest) returns (UserResponse);
  rpc GetUserOrganizations(GetUserOrganizationsRequest) returns (GetUserOrganizationsResponse);
}

message GetUserRequest {
  string user_id = 1;
}

message UserResponse {
  string id = 1;
  string email = 2;
  string display_name = 3;
  pm.common.v1.Timestamp created_at = 4;
}

message GetUserOrganizationsRequest {
  string user_id = 1;
}

message GetUserOrganizationsResponse {
  repeated OrganizationInfo organizations = 1;
}

message OrganizationInfo {
  string id = 1;
  string name = 2;
  string slug = 3;
  string role_name = 4;
  bool is_owner = 5;
}

// ============================================
// ORGANIZATION SERVICE
// ============================================

service OrganizationService {
  rpc GetOrganization(GetOrganizationRequest) returns (OrganizationResponse);
  rpc GetMembers(GetMembersRequest) returns (GetMembersResponse);
}

message GetOrganizationRequest {
  string org_id = 1;
}

message OrganizationResponse {
  string id = 1;
  string name = 2;
  string slug = 3;
  string owner_id = 4;
  pm.common.v1.Timestamp created_at = 5;
}

message GetMembersRequest {
  string org_id = 1;
  pm.common.v1.PagedRequest paging = 2;
}

message GetMembersResponse {
  repeated MemberInfo members = 1;
  pm.common.v1.PagedResponse paging = 2;
}

message MemberInfo {
  string user_id = 1;
  string email = 2;
  string display_name = 3;
  string role_name = 4;
  pm.common.v1.Timestamp joined_at = 5;
}
```

**PM.IAM.Contracts.csproj:**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\..\Platform\PM.Platform.Contracts\PM.Platform.Contracts.csproj" />
  </ItemGroup>
  
  <ItemGroup>
    <Protobuf Include="Protos\iam.proto" GrpcServices="Both" />
    <Protobuf Include="..\..\Platform\PM.Platform.Contracts\Protos\common.proto" 
              GrpcServices="None" Link="Protos\common.proto" />
  </ItemGroup>
  
  <ItemGroup>
    <PackageReference Include="Grpc.Tools" PrivateAssets="All" />
    <PackageReference Include="Google.Protobuf" />
    <PackageReference Include="Grpc.Net.Client" />
    <PackageReference Include="Grpc.AspNetCore" />
  </ItemGroup>
</Project>
```

---

### 4.6 PM.IAM.Api

```
PM.IAM.Api/
├── GrpcServices/
│   ├── PermissionGrpcService.cs
│   ├── UserGrpcService.cs
│   └── OrganizationGrpcService.cs
│
├── Controllers/                    # Internal REST (optional)
│   └── HealthController.cs
│
├── Middleware/
│   └── OrgContextMiddleware.cs
│
├── Program.cs
├── appsettings.json
├── appsettings.Development.json
├── Dockerfile
└── PM.IAM.Api.csproj
```

**PM.IAM.Api.csproj:**
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  
  <ItemGroup>
    <ProjectReference Include="..\PM.IAM.Application\PM.IAM.Application.csproj" />
    <ProjectReference Include="..\PM.IAM.Infrastructure\PM.IAM.Infrastructure.csproj" />
    <ProjectReference Include="..\PM.IAM.Contracts\PM.IAM.Contracts.csproj" />
  </ItemGroup>
</Project>
```

---

## 5. BFF-сервис (src/BFF/)

Единая точка входа для SPA.

### 5.1 Структура

```
PM.BFF/
├── Controllers/
│   ├── HealthController.cs
│   ├── AuthController.cs           # /auth/login, /auth/callback, /auth/logout, /auth/me
│   └── ProxyController.cs          # /api/{module}/* → routing
│
├── Auth/
│   ├── OidcHandler.cs              # PKCE flow с Keycloak
│   ├── SessionManager.cs           # Redis sessions
│   ├── SessionData.cs              # Структура сессии
│   ├── CsrfMiddleware.cs           # Double Submit Cookie
│   └── TokenRefreshService.cs      # Background refresh
│
├── Proxy/
│   ├── ModuleRouter.cs             # Роутинг к модулям
│   ├── GrpcClientFactory.cs        # Фабрика gRPC клиентов
│   └── TokenAttacher.cs            # Authorization header
│
├── Permissions/
│   └── PermissionChecker.cs        # gRPC клиент к IAM
│
├── Configuration/
│   ├── ModulesConfiguration.cs
│   └── AuthConfiguration.cs
│
├── Program.cs
├── appsettings.json
├── appsettings.Development.json
├── Dockerfile
└── PM.BFF.csproj
```

### 5.2 Зависимости

```xml
<ItemGroup>
  <!-- IAM контракты для RBAC -->
  <ProjectReference Include="..\..\IAM\PM.IAM.Contracts\PM.IAM.Contracts.csproj" />
  
  <!-- Платформенная инфраструктура -->
  <ProjectReference Include="..\..\Platform\PM.Platform.Infrastructure\PM.Platform.Infrastructure.csproj" />
</ItemGroup>
```

### 5.3 Конфигурация модулей

**appsettings.json:**
```json
{
  "Modules": {
    "iam": {
      "GrpcUrl": "http://iam-api:8081",
      "HealthPath": "/health"
    },
    "pm": {
      "GrpcUrl": "http://pm-api:8082",
      "HealthPath": "/health"
    },
    "analytics": {
      "GrpcUrl": "http://analytics-api:8083",
      "HealthPath": "/health"
    }
  },
  
  "Auth": {
    "Authority": "http://keycloak:8080/realms/pmplatform",
    "ClientId": "bff-client",
    "ClientSecret": "${BFF_CLIENT_SECRET}",
    "SessionTtlMinutes": 60,
    "CsrfCookieName": "XSRF-TOKEN",
    "CsrfHeaderName": "X-XSRF-TOKEN"
  },
  
  "Redis": {
    "ConnectionString": "redis:6379,password=${REDIS_PASSWORD}"
  }
}
```

### 5.4 Роутинг

| Путь | Назначение |
|------|------------|
| `/health` | Health check BFF |
| `/auth/*` | Аутентификация (login, callback, logout, me) |
| `/api/iam/*` | Проксирование в IAM API |
| `/api/pm/*` | Проксирование в ProjectManagement API |
| `/api/analytics/*` | Проксирование в Analytics API |

---

## 6. Бизнес-модули (src/Modules/)

Каждый модуль — независимый bounded context со своими контрактами.

### 6.1 Структура модуля

```
src/Modules/ProjectManagement/
├── PM.ProjectManagement.Domain/
│   ├── Entities/
│   │   ├── Project.cs
│   │   ├── Task.cs
│   │   ├── Sprint.cs
│   │   └── ProjectMember.cs
│   ├── ValueObjects/
│   ├── Events/
│   └── PM.ProjectManagement.Domain.csproj
│
├── PM.ProjectManagement.Application/
│   ├── Commands/
│   ├── Queries/
│   ├── Services/
│   └── PM.ProjectManagement.Application.csproj
│
├── PM.ProjectManagement.Infrastructure/
│   ├── Persistence/
│   │   ├── PMDbContext.cs
│   │   ├── Configurations/
│   │   └── Migrations/
│   └── PM.ProjectManagement.Infrastructure.csproj
│
├── PM.ProjectManagement.Contracts/
│   ├── Protos/
│   │   └── pm.proto              # package pm.projectmanagement.v1
│   ├── DTOs/
│   └── PM.ProjectManagement.Contracts.csproj
│
└── PM.ProjectManagement.Api/
    ├── GrpcServices/
    │   └── ProjectGrpcService.cs
    ├── Controllers/
    ├── Program.cs
    ├── Dockerfile
    └── PM.ProjectManagement.Api.csproj
```

### 6.2 Зависимости модуля

**PM.ProjectManagement.Api.csproj:**
```xml
<ItemGroup>
  <!-- IAM контракты для RBAC -->
  <ProjectReference Include="..\..\..\IAM\PM.IAM.Contracts\PM.IAM.Contracts.csproj" />
  
  <!-- Собственные слои -->
  <ProjectReference Include="..\PM.ProjectManagement.Application\PM.ProjectManagement.Application.csproj" />
  <ProjectReference Include="..\PM.ProjectManagement.Infrastructure\PM.ProjectManagement.Infrastructure.csproj" />
  <ProjectReference Include="..\PM.ProjectManagement.Contracts\PM.ProjectManagement.Contracts.csproj" />
  
  <!-- Платформа -->
  <ProjectReference Include="..\..\..\Platform\PM.Platform.Infrastructure\PM.Platform.Infrastructure.csproj" />
</ItemGroup>
```

### 6.3 Использование IAM для RBAC

```csharp
// PM.ProjectManagement.Api/GrpcServices/ProjectGrpcService.cs

public class ProjectGrpcService : ProjectService.ProjectServiceBase
{
    private readonly PermissionService.PermissionServiceClient _permissions;
    private readonly IMediator _mediator;

    public ProjectGrpcService(
        PermissionService.PermissionServiceClient permissions,
        IMediator mediator)
    {
        _permissions = permissions;
        _mediator = mediator;
    }

    public override async Task<CreateProjectResponse> CreateProject(
        CreateProjectRequest request,
        ServerCallContext context)
    {
        // 1. Проверка прав через IAM
        var check = await _permissions.CheckAsync(new CheckPermissionRequest
        {
            UserId = context.GetUserId(),
            OrgId = request.OrgId,
            Permission = "projects.create"
        });
        
        if (!check.Allowed)
            throw new RpcException(new Status(StatusCode.PermissionDenied, check.Reason));
        
        // 2. Выполнение команды
        var result = await _mediator.Send(new CreateProjectCommand
        {
            OrgId = request.OrgId,
            Name = request.Name,
            Description = request.Description
        });
        
        return new CreateProjectResponse { ProjectId = result.Id.ToString() };
    }
}
```

---

## 7. Схема зависимостей

### 7.1 Общая архитектура

```
                    ┌─────────────────────────────────────┐
                    │              Edge (Nginx)           │
                    │  (TLS, CSP, rate limiting, proxy)   │
                    └─────────────────┬───────────────────┘
                                      │ HTTP
                                      ▼
                    ┌─────────────────────────────────────┐
                    │              PM.BFF                  │
                    │  (OIDC, sessions, CSRF, proxy)      │
                    │  ┌─────────────────────────────┐    │
                    │  │ uses: PM.IAM.Contracts     │    │
                    │  └─────────────────────────────┘    │
                    └─────────────────┬───────────────────┘
                                      │ gRPC
              ┌───────────────────────┼───────────────────────┐
              ▼                       ▼                       ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│    PM.IAM.Api       │  │PM.PrjManagement.Api │  │  PM.Analytics.Api   │
│    (iam.proto)      │  │   (pm.proto)        │  │  (analytics.proto)  │
│                     │  │                     │  │                     │
│ ┌─────────────────┐ │  │ ┌─────────────────┐ │  │ ┌─────────────────┐ │
│ │ .Contracts      │ │  │ │ .Contracts      │ │  │ │ .Contracts      │ │
│ └─────────────────┘ │  │ └─────────────────┘ │  │ └─────────────────┘ │
└──────────┬──────────┘  └──────────┬──────────┘  └──────────┬──────────┘
           │                        │                        │
           │ uses                   │ uses                   │ uses
           ▼                        ▼                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      PM.Platform.Infrastructure                         │
│           (Redis, Outbox, OTel, EF Core, HealthChecks)                  │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         PM.Platform.Core                                │
│              (IEntity, CQRS, Behaviors, Exceptions)                     │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      PM.Platform.Contracts                              │
│                    (ТОЛЬКО common.proto)                                │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Граф зависимостей контрактов

```
PM.Platform.Contracts (common.proto)
         ▲
         │ import "common.proto"
         │
PM.IAM.Contracts (iam.proto)
         ▲
         │ ProjectReference
    ┌────┴────────────────────┐
    │                         │
PM.BFF              PM.{Module}.Api
                              │
                              │ ProjectReference (optional)
                              ▼
                    PM.{Module}.Contracts
```

### 7.3 Зависимости проектов (таблица)

| Проект | Зависит от |
|--------|------------|
| `PM.Platform.Core` | — |
| `PM.Platform.Contracts` | — |
| `PM.Platform.Infrastructure` | `PM.Platform.Core` |
| `PM.IAM.Domain` | `PM.Platform.Core` |
| `PM.IAM.Application` | `PM.IAM.Domain`, `PM.Platform.Core` |
| `PM.IAM.Infrastructure` | `PM.IAM.Application`, `PM.Platform.Infrastructure` |
| `PM.IAM.Contracts` | `PM.Platform.Contracts` |
| `PM.IAM.Api` | `PM.IAM.*`, `PM.Platform.Infrastructure` |
| `PM.BFF` | `PM.IAM.Contracts`, `PM.Platform.Infrastructure` |
| `PM.{Module}.Domain` | `PM.Platform.Core` |
| `PM.{Module}.Application` | `PM.{Module}.Domain`, `PM.Platform.Core` |
| `PM.{Module}.Infrastructure` | `PM.{Module}.Application`, `PM.Platform.Infrastructure` |
| `PM.{Module}.Contracts` | `PM.Platform.Contracts` |
| `PM.{Module}.Api` | `PM.{Module}.*`, `PM.IAM.Contracts`, `PM.Platform.Infrastructure` |

---

## 8. Как добавить новый модуль

### Шаг 1: Скопировать шаблон

```bash
cp -r src/Modules/_Template src/Modules/TelegramBot
```

### Шаг 2: Переименовать

Заменить `_Template` → `TelegramBot` во всех файлах:
- Папки: `PM._Template.*` → `PM.TelegramBot.*`
- Namespaces: `PM._Template` → `PM.TelegramBot`
- Proto package: `pm._template.v1` → `pm.telegrambot.v1`

```bash
# Быстрая замена (Linux/Mac)
find src/Modules/TelegramBot -type f -name "*.cs" -o -name "*.csproj" -o -name "*.proto" | \
  xargs sed -i 's/_Template/TelegramBot/g'
```

### Шаг 3: Добавить в Solution

```bash
dotnet sln PMPlatform.sln add src/Modules/TelegramBot/**/*.csproj
```

### Шаг 4: Добавить зависимость от IAM.Contracts

Уже есть в шаблоне:
```xml
<ProjectReference Include="..\..\IAM\PM.IAM.Contracts\PM.IAM.Contracts.csproj" />
```

### Шаг 5: Определить proto-контракт

**src/Modules/TelegramBot/PM.TelegramBot.Contracts/Protos/telegrambot.proto:**
```protobuf
syntax = "proto3";
package pm.telegrambot.v1;

option csharp_namespace = "PM.TelegramBot.Contracts.Grpc";

service TelegramBotService {
  rpc SendMessage(SendMessageRequest) returns (SendMessageResponse);
  rpc GetBotStatus(GetBotStatusRequest) returns (GetBotStatusResponse);
}

// ... messages
```

### Шаг 6: Зарегистрировать в BFF

**PM.BFF/appsettings.json:**
```json
{
  "Modules": {
    "telegrambot": {
      "GrpcUrl": "http://telegrambot-api:8084",
      "HealthPath": "/health"
    }
  }
}
```

### Шаг 7: Добавить в Docker Compose (надстройка)

**ops/platform/compose.platform.yml:** (подключается поверх `ops/iam/compose.iam.yml`)
+> Примечание: `postgres` и `redis` ниже — это *имена сервисов базового контура* в docker compose.  
+> Если в базовом контуре они называются иначе (например, `postgres-iam`, `redis`), используй реальные имена из `ops/iam/compose.iam.yml`.

```yaml
telegrambot-api:
    build:
     context: ../src/Modules/TelegramBot/PM.TelegramBot.Api
     dockerfile: Dockerfile
   image: pm-telegrambot-api:dev
   container_name: pm-telegrambot-api
   environment:
     ASPNETCORE_ENVIRONMENT: Development
     ConnectionStrings__TelegramBot: "Host=postgres;Port=5432;Database=telegrambot;..."
     Otel__Endpoint: "http://otel-collector:4317"
   depends_on:
     postgres:
       condition: service_healthy
     redis:
       condition: service_healthy
   networks:
     - backend-net
     - db-net
+  # healthcheck намеренно не задан:
+  # в chiseled-образах обычно нет curl/wget. Health проверяем через edge с хоста,
+  # либо используем отдельный debug-образ/target с утилитами.
   profiles: ["full"]
```

### Шаг 8: Добавить Angular library (опционально)

```bash
cd web/pm-web
ng generate library telegram-bot --prefix=tgb
```

---

## 9. Правила именования

### 9.1 Backend (.NET)

| Тип | Шаблон | Пример |
|-----|--------|--------|
| Solution | `PMPlatform.sln` | |
| Платформенный проект | `PM.Platform.{Layer}` | `PM.Platform.Core` |
| IAM проект | `PM.IAM.{Layer}` | `PM.IAM.Domain` |
| IAM контракты | `PM.IAM.Contracts` | |
| BFF проект | `PM.BFF` | |
| Модуль | `PM.{ModuleName}.{Layer}` | `PM.TelegramBot.Api` |
| Контракты модуля | `PM.{ModuleName}.Contracts` | `PM.TelegramBot.Contracts` |
| Namespace | Совпадает с именем проекта | `PM.IAM.Domain.Entities` |

### 9.2 gRPC / Proto

| Тип | Шаблон | Пример |
|-----|--------|--------|
| Proto file | `{domain}.proto` | `iam.proto`, `pm.proto` |
| Package (Platform) | `pm.common.v1` | |
| Package (IAM) | `pm.iam.v1` | |
| Package (Module) | `pm.{module}.v1` | `pm.telegrambot.v1` |
| C# namespace | `PM.{Module}.Contracts.Grpc` | `PM.IAM.Contracts.Grpc` |
| Service name | `{Entity}Service` | `PermissionService`, `ProjectService` |

### 9.3 Docker / DevOps

| Тип | Шаблон | Пример |
|-----|--------|--------|
| Image name | `pm-{service}:{tag}` | `pm-iam-api:dev` |
| Container name | `pm-{service}` | `pm-bff`, `pm-iam-api` |
| Network | `{purpose}-net` | `backend-net`, `db-net` |
| Volume | `pm_{service}_{type}` | `pm_postgres_data` |

### 9.4 Frontend (Angular)

| Тип | Шаблон | Пример |
|-----|--------|--------|
| Library | `{module-name}` | `core`, `project-management` |
| Prefix | 3-4 буквы от модуля | `core`, `pm`, `tgb` |
| Component | `{prefix}-{name}` | `core-login`, `pm-project-list` |
| Module | `{Name}Module` | `CoreModule`, `ProjectManagementModule` |

### 9.5 База данных

| Тип | Шаблон | Пример |
|-----|--------|--------|
| Schema | `{module}` | `iam`, `pm`, `analytics` |
| Table | `{entity}s` (plural) | `users`, `organizations`, `projects` |
| Index | `ix_{table}_{columns}` | `ix_memberships_user_org` |
| Foreign Key | `fk_{table}_{ref_table}` | `fk_memberships_users` |

---

## 10. Сводка по контрактам

| Проект | Содержимое | Package | Кто использует |
|--------|------------|---------|----------------|
| `PM.Platform.Contracts` | `common.proto` (Timestamp, UUID, Paging) | `pm.common.v1` | Все модули (import) |
| `PM.IAM.Contracts` | `iam.proto` (RBAC, Users, Orgs) | `pm.iam.v1` | BFF + все бизнес-модули |
| `PM.{Module}.Contracts` | `{module}.proto` + DTOs | `pm.{module}.v1` | BFF + зависимые модули |

### Принцип владения контрактами

```
┌──────────────────────────────────────────────────────────────┐
│                    КОНТРАКТЫ                                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Platform.Contracts     IAM.Contracts      Module.Contracts  │
│  ┌────────────────┐    ┌──────────────┐   ┌──────────────┐  │
│  │ common.proto   │    │ iam.proto    │   │ {m}.proto    │  │
│  │ ─────────────  │    │ ───────────  │   │ ──────────   │  │
│  │ Timestamp      │◄───│ Check*       │   │ Domain-      │  │
│  │ UUID           │    │ GetUser*     │   │ specific     │  │
│  │ PagedRequest   │    │ GetOrg*      │   │ RPCs         │  │
│  │ PagedResponse  │    │              │   │              │  │
│  └────────────────┘    └──────────────┘   └──────────────┘  │
│         │                     │                   │          │
│         │                     │                   │          │
│         ▼                     ▼                   ▼          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                      ПОТРЕБИТЕЛИ                        ││
│  │  BFF, IAM.Api, Module.Api — все импортируют нужное      ││
│  └─────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

**Правило:** Каждый модуль владеет своими контрактами. Platform — только общие примитивы. IAM — функции аутентификации и авторизации для всей платформы.

---

## 11. Definition of Done: структура проекта

Структура считается готовой когда:

- [ ] `PMPlatform.sln` собирается без ошибок: `dotnet build`
- [ ] Все проекты следуют naming conventions
- [ ] IAM.Api отвечает на `/health` → 200
- [ ] BFF отвечает на `/health` → 200
- [ ] gRPC reflection работает на IAM.Api
- [ ] Docker Compose поднимает все сервисы: `docker compose up -d`
- [ ] Документация в `docs/architecture/` актуальна

---

*Версия 1.2.1 | 25.01.2026*
