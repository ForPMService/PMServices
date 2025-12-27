# IAM Routes

## Public (без auth)

| Route | Page |
|-------|------|
| `/auth/login` | Login (redirect to Keycloak) |
| `/auth/register` | Registration form |
| `/auth/forgot-password` | Password recovery |
| `/auth/verify-email` | Email verification |
| `/auth/invite/:token` | Accept invite |

## Protected (требует auth)

| Route | Page |
|-------|------|
| `/profile` | User profile |
| `/profile/sessions` | Active sessions |
| `/select-organization` | Org switcher (если несколько) |

## Admin (требует permission)

| Route | Permission |
|-------|------------|
| `/admin/users` | `users.read` |
| `/admin/roles` | `roles.read` |
| `/admin/invites` | `users.invite` |
