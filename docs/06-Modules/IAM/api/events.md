# IAM Events

Stream: `pmservices.iam.events`

## User

| Event | Payload |
|-------|---------|
| `iam.user.registered` | `{userId, orgId?, type}` |
| `iam.user.email_verified` | `{userId}` |
| `iam.user.suspended` | `{userId, reason}` |

## Organization

| Event | Payload |
|-------|---------|
| `iam.org.created` | `{orgId, ownerId}` |
| `iam.org.member_added` | `{orgId, userId, roles[]}` |
| `iam.org.member_removed` | `{orgId, userId}` |

## RBAC

| Event | Payload |
|-------|---------|
| `iam.rbac.role_assigned` | `{orgId, userId, roleId}` |
| `iam.rbac.role_revoked` | `{orgId, userId, roleId}` |

## Security

| Event | Payload |
|-------|---------|
| `iam.auth.password_recovered` | `{userId}` |
| `iam.session.revoked` | `{userId, sessionId}` |

## ⚠️ В payload только ID, не sensitive данные
