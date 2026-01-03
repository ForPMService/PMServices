# Примеры использования PMServices IAM API

## Быстрый старт

### 1. Регистрация пользователя с организацией

```bash
curl -X POST https://api.pmservices.io/api/iam/registration/organization \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: unique-key-123" \
  -d '{
    "email": "admin@company.com",
    "password": "SecurePass123!",
    "firstName": "Jane",
    "lastName": "Smith",
    "phone": "+1234567890",
    "organizationName": "Acme Corp"
  }'
```

**Ответ:**
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "organizationId": "660e8400-e29b-41d4-a716-446655440000",
  "organizationName": "Acme Corp",
  "emailVerificationRequired": true
}
```

### 2. Вход и получение токена

Используйте Keycloak для получения JWT токена:

```bash
curl -X POST https://auth.pmservices.io/realms/pmservices/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=pmservices-api" \
  -d "username=admin@company.com" \
  -d "password=SecurePass123!"
```

### 3. Получение информации о текущем пользователе

```bash
curl -X GET https://api.pmservices.io/api/iam/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 4. Создание приглашения в организацию

```bash
curl -X POST https://api.pmservices.io/api/iam/organizations/{orgId}/invites \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "roleIds": ["role-uuid-here"],
    "message": "Присоединяйтесь к нашей команде!"
  }'
```

## Примеры RBAC

### Создание кастомной роли

```bash
curl -X POST https://api.pmservices.io/api/iam/rbac/roles \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-PM-OrgId: YOUR_ORG_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "project-manager",
    "name": "Project Manager",
    "description": "Управление проектами",
    "permissionIds": ["perm-1", "perm-2", "perm-3"]
  }'
```

### Назначение роли пользователю

```bash
curl -X POST https://api.pmservices.io/api/iam/rbac/users/{userId}/roles \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-PM-OrgId: YOUR_ORG_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "roleIds": ["role-uuid-1", "role-uuid-2"]
  }'
```

### Проверка прав доступа

```bash
curl -X POST https://api.pmservices.io/api/iam/rbac/check \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "permission": "project.create"
  }'
```

**Ответ:**
```json
{
  "allowed": true,
  "reason": "allowed",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "organizationId": "660e8400-e29b-41d4-a716-446655440000",
  "permission": "project.create",
  "checkedAt": "2024-01-15T10:30:00Z"
}
```

## Работа с приглашениями

### Создание invite link (многоразовая ссылка)

```bash
curl -X POST https://api.pmservices.io/api/iam/organizations/{orgId}/invite-links \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Developers Team Link",
    "roleIds": ["dev-role-uuid"],
    "maxUses": 50,
    "expiresInDays": 30
  }'
```

### Использование invite link

```bash
curl -X POST https://api.pmservices.io/api/iam/invite-links/{token}/join \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Управление профилем

### Обновление профиля

```bash
curl -X PATCH https://api.pmservices.io/api/iam/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Updated",
    "phone": "+1234567890"
  }'
```

### Загрузка аватара

```bash
curl -X POST https://api.pmservices.io/api/iam/me/avatar \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@/path/to/avatar.jpg"
```

## Работа с сессиями

### Получение списка активных сессий

```bash
curl -X GET https://api.pmservices.io/api/iam/security/sessions \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Завершение всех сессий кроме текущей

```bash
curl -X POST https://api.pmservices.io/api/iam/security/sessions/revoke-all \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Internal API (только для сервисов)

### Регистрация прав доступа модуля

```bash
curl -X POST https://api.pmservices.io/api/iam/internal/permissions/register \
  -H "Authorization: Bearer SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "moduleCode": "project-management",
    "moduleName": "Project Management",
    "permissions": [
      {
        "code": "project.create",
        "name": "Create Projects",
        "description": "Allows creating new projects"
      },
      {
        "code": "project.delete",
        "name": "Delete Projects"
      }
    ]
  }'
```

### Получение информации о пользователе (Internal)

```bash
curl -X GET https://api.pmservices.io/api/iam/internal/users/{userId}/context \
  -H "Authorization: Bearer SERVICE_TOKEN"
```

## Audit Log

### Получение логов организации

```bash
curl -X GET "https://api.pmservices.io/api/iam/organizations/{orgId}/audit-log?page=1&limit=50&subjectType=role&action=create" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Обработка ошибок

Все ошибки возвращаются в следующем формате:

```json
{
  "code": "IAM-004",
  "message": "Insufficient permissions",
  "details": {
    "required": "organization.admin",
    "current": "organization.member"
  }
}
```

### Типичные коды ошибок

- `IAM-001` - Email already registered
- `IAM-004` - Insufficient permissions
- `IAM-005` - Organization not found
- `IAM-007` - Email not verified
- `IAM-008` - Rate limit exceeded

## Best Practices

### 1. Используйте Idempotency Keys

Для операций создания всегда отправляйте уникальный ключ:

```bash
-H "X-Idempotency-Key: $(uuidgen)"
```

### 2. Обрабатывайте Rate Limits

При получении `429` ошибки, проверяйте заголовок `Retry-After`:

```javascript
if (response.status === 429) {
  const retryAfter = response.headers.get('Retry-After');
  await sleep(retryAfter * 1000);
  // retry request
}
```

### 3. Валидируйте токены

Проверяйте срок действия JWT токена и обновляйте его заранее:

```javascript
const tokenExpiry = parseJwt(token).exp;
if (Date.now() >= tokenExpiry * 1000 - 60000) { // за 1 минуту до истечения
  token = await refreshToken();
}
```

### 4. Используйте правильный контекст организации

Всегда указывайте `X-PM-OrgId` для org-scoped операций:

```bash
-H "X-PM-OrgId: YOUR_ORG_ID"
```

## SDKs и библиотеки

### JavaScript/TypeScript

```typescript
import { PMServicesIAM } from '@pmservices/iam-sdk';

const iam = new PMServicesIAM({
  baseUrl: 'https://api.pmservices.io',
  authUrl: 'https://auth.pmservices.io'
});

// Вход
await iam.auth.login('user@example.com', 'password');

// Получение профиля
const profile = await iam.users.getMe();

// Создание роли
const role = await iam.rbac.createRole({
  code: 'developer',
  name: 'Developer',
  permissionIds: ['perm-1', 'perm-2']
});
```

### Python

```python
from pmservices_iam import IAMClient

iam = IAMClient(
    base_url='https://api.pmservices.io',
    auth_url='https://auth.pmservices.io'
)

# Вход
iam.auth.login('user@example.com', 'password')

# Получение профиля
profile = iam.users.get_me()

# Создание роли
role = iam.rbac.create_role(
    code='developer',
    name='Developer',
    permission_ids=['perm-1', 'perm-2']
)
```

## Дополнительная информация

- 📖 [Полная документация API](https://your-username.github.io/iam-api-docs/)
- 🔧 [Swagger UI](https://your-username.github.io/iam-api-docs/swagger-ui.html)
- 📘 [ReDoc](https://your-username.github.io/iam-api-docs/redoc.html)
- 💬 [Поддержка](mailto:dev@pmservices.io)
